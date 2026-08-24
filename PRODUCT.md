# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

**Primary user** (inferred from codebase evidence — self_hosted mode, personal fork): A technically-capable individual who self-hosts their own personal finance infrastructure. They are comfortable with Docker, Rails, and CLI operations. They value data ownership, privacy, and control over their financial data.

**Secondary user** (inferred from A2A protocol implementation): External AI agents that interact with the user's financial data via the Agent-to-Agent protocol v1.0 (Google A2A spec) over JSON-RPC 2.0. Discovery happens through the machine-readable Agent Card at `/.well-known/agent-card.json`.

## Product Purpose

Maybe is a self-hosted, open-source personal finance operating system that lets individuals track, analyze, and manage their complete financial picture — accounts, transactions, budgets, investments, net worth, and cash flow — under their own control.

## Positioning

A self-hosted, open-source personal finance platform that puts data ownership first, in contrast to cloud-dependent apps like Mint, YNAB, or Copilot Money. The A2A agent protocol distinguishes this fork by enabling AI agents to interact with financial data programmatically.

## Operating Context

- **Self-hosted deployment**: Runs via Docker Compose on the user's own infrastructure (inferred from `SELF_HOSTED` env var, Docker docs in `docs/hosting/`)
- **Browser-based**: Full-featured web app accessed through a standard browser
- **Background processing**: Sidekiq handles async jobs (Plaid sync, imports, AI chat responses)
- **Data entry methods**: Manual entry, Plaid bank sync, CSV import with field mapping
- **AI assistant**: Built-in chat interface for querying financial data via LLM
- **Agent integration**: A2A v1.0 protocol endpoint at `/api/v1/a2a` for programmatic agent access; Agent Card discovery document served for agent registries such as AgentMesh

## Capabilities and Constraints

**Confirmed capabilities** (from codebase):
- Multi-account management: checking, savings, credit cards, investments, crypto, loans, properties
- Transaction tracking, categorization, tagging, and rules-based auto-categorization
- Budget management with category-based budgeting
- Net worth tracking with time-series charts
- Balance sheet and income statement views
- Cash flow visualization (Sankey diagram)
- Investment portfolio tracking with holdings, securities, and trades
- Multi-currency support with exchange rate syncing
- Plaid integration for automated bank syncing
- CSV import with custom field mapping
- AI assistant/chat for natural-language financial queries, with client-side chat search and cancelable in-flight responses
- Global keyboard shortcuts (hotkeys) for navigation and search; dismissible banners persist per session
- A2A protocol v1.0 for external AI agent integration: `SendMessage` / `GetTask` / `CancelTask` methods, Task↔Chat 1:1 mapping, API-key auth via `X-Api-Key`, `A2A-Version: 1.0` header
- Demo mode for evaluation without real data
- Dark/light theme support
- User roles: personal (single-user or family accounts); invitation codes for joining a family
- MFA (multi-factor authentication), password strength checks, remember-me sessions
- API access via OAuth2 (Doorkeeper) and API keys
- Data export functionality
- Onboarding flow for new users with a skip route
- Responsive multi-panel layout: staged sidebar collapse on desktop, ultra-wide adaptive behavior, mobile drawer navigation

**Confirmed constraints**:
- Self-hosted only — no hosted/SaaS version (the original hosted service shut down July 2025)
- Rails 8.1 monolith with Hotwire frontend (no separate SPA)
- PostgreSQL database
- Requires Docker for deployment (inferred from self_hosted mode)
- Rate-limited API via Rack::Attack

## Brand Commitments

- **Name**: "Maybe" (the original project name, preserved in this fork)
- **Identity**: Open-source personal finance app. The project maintains the original Maybe branding.
- **Voice**: Direct, helpful, transparent (inferred from UI copy patterns — "Welcome back", "Here's what's happening with your finances")
- **Inferred commitment**: Long-term self-hosted viability — the user maintains this fork as a living alternative to the abandoned hosted version

## Evidence on Hand

- Ruby on Rails 8.1 application with Hotwire (Turbo + Stimulus) frontend
- Tailwind CSS v4 with a custom design system in `app/assets/tailwind/maybe-design-system.css`
- ViewComponent-based UI components in `app/components/`
- D3.js for financial visualizations (net worth charts, Sankey diagrams)
- Lookbook component previews at `/design-system`
- Sidekiq dashboard at `/sidekiq`
- Doorkeeper OAuth for API authentication
- Jbuilder templates for JSON API responses
- Minitest + fixtures for testing (no RSpec, no FactoryBot)
- VCR for external API test recording

## Product Principles

*(inferred from codebase structure and conventions)*

1. **Data ownership first**: Everything runs on the user's infrastructure. No external dependencies beyond optional Plaid connections and exchange rate APIs.
2. **Full financial picture**: Track all asset types — not just spending but investments, property, crypto, and liabilities — in one place.
3. **AI-augmented finance**: The assistant and A2A protocol make financial data queryable through natural language, not just dashboards.
4. **Predictable Rails conventions**: Business logic lives in models, not service objects. Hotwire over heavy JS frameworks. Minitest over RSpec.
5. **Self-serve UI**: Every feature is accessible through the web interface — account management, imports, rules, budgets, settings, exports.

## Accessibility & Inclusion

*Updated after dedicated accessibility passes (Aug 2026)*
- Dark and light theme support via Tailwind design system tokens
- Standard HTML form elements with labels
- Dedicated accessibility improvement passes: enlarged touch targets, improved focus states, layout-level accessibility refinements
- Design critique reports maintained under `.impeccable/critique/`