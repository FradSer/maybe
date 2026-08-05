Rails.application.configure do
  config.plaid = nil
  config.plaid_eu = nil

  # Sandbox credentials for the test environment. Must be set before the config
  # below runs: `bin/rails test` (no file args) boots the environment via
  # test:prepare BEFORE test_helper has a chance to set them.
  if Rails.env.test?
    ENV["PLAID_ENV"] = "sandbox"
    ENV["PLAID_CLIENT_ID"] ||= "test_client_id"
    ENV["PLAID_SECRET"] ||= "test_secret"
  end

  if ENV["PLAID_CLIENT_ID"].present? && ENV["PLAID_SECRET"].present?
    config.plaid = Plaid::Configuration.new
    config.plaid.server_index = Plaid::Configuration::Environment[ENV["PLAID_ENV"] || "sandbox"]
    config.plaid.api_key["PLAID-CLIENT-ID"] = ENV["PLAID_CLIENT_ID"]
    config.plaid.api_key["PLAID-SECRET"] = ENV["PLAID_SECRET"]
  end

  if ENV["PLAID_EU_CLIENT_ID"].present? && ENV["PLAID_EU_SECRET"].present?
    config.plaid_eu = Plaid::Configuration.new
    config.plaid_eu.server_index = Plaid::Configuration::Environment[ENV["PLAID_ENV"] || "sandbox"]
    config.plaid_eu.api_key["PLAID-CLIENT-ID"] = ENV["PLAID_EU_CLIENT_ID"]
    config.plaid_eu.api_key["PLAID-SECRET"] = ENV["PLAID_EU_SECRET"]
  end
end
