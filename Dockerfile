# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.4
# Pin the Debian version: the floating -slim tag will re-point to trixie (postgresql-17
# at different paths) when the Ruby image is rebuilt upstream.
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim-bookworm AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client libyaml-0-2

# Set production environment
ARG BUILD_COMMIT_SHA
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    BUILD_COMMIT_SHA=${BUILD_COMMIT_SHA}
    
# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get install --no-install-recommends -y build-essential libpq-dev git pkg-config libyaml-dev

# Install application gems
COPY .ruby-version Gemfile Gemfile.lock ./
ARG BUNDLE_MIRROR
RUN if [ -n "$BUNDLE_MIRROR" ]; then \
      bundle config set --global mirror.https://rubygems.org "$BUNDLE_MIRROR" && \
      gem install bundler -v 2.6.9 --no-document; \
    fi \
    && bundle install

RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

RUN bundle exec bootsnap precompile --gemfile -j 0

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile -j 0 app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Clean up installation packages to reduce image size
RUN rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install runtime services: PostgreSQL 15 (server + contrib for pgcrypto), Redis, supervisor.
# postgresql-15's postinst auto-creates a default "main" cluster in /var/lib/postgresql
# (owned by the postgres user) — drop it; this container runs its own cluster at
# /data/postgres as uid 1000.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y postgresql-15 postgresql-contrib-15 redis-server supervisor && \
    pg_dropcluster --stop 15 main || true && \
    rm -rf /var/lib/postgresql /etc/postgresql /var/log/postgresql /var/lib/apt/lists /var/cache/apt/archives

# Supervisor config (replaces Debian's default, which assumes root: socket in /var/run)
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security.
# /data holds the persistent postgres + redis data (mounted as the maybe-data volume).
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp && \
    mkdir -p /data && chown rails:rails /data
USER 1000:1000

# Entrypoint initializes the data dirs, then execs the given command (supervisord).
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start all four services (rails, sidekiq, postgres, redis) via supervisor by default
EXPOSE 3000
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
