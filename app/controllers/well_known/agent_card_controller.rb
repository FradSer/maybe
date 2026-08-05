# frozen_string_literal: true

# Public A2A discovery document served at /.well-known/agent-card
class WellKnown::AgentCardController < ApplicationController
  skip_authentication
  skip_before_action :verify_authenticity_token

  def show
    render json: {
      name: "Maybe Finance Agent",
      description: "Personal finance assistant for Maybe: answers questions about transactions, accounts, balance sheet, and income statement data.",
      url: interface_url,
      protocolVersion: "1.0",
      capabilities: { streaming: false, pushNotifications: false, stateTransitionHistory: false },
      skills: [
        { id: "GetTransactions", name: "GetTransactions", description: "Query transaction history across accounts" },
        { id: "GetAccounts", name: "GetAccounts", description: "List accounts and their balances" },
        { id: "GetBalanceSheet", name: "GetBalanceSheet", description: "Get the balance sheet for a date range" },
        { id: "GetIncomeStatement", name: "GetIncomeStatement", description: "Get the income statement for a date range" }
      ],
      securitySchemes: [ { type: "apiKey", in: "header", name: "X-Api-Key" } ]
    }
  end

  private

    def interface_url
      base = ENV["APP_DOMAIN"].presence || request.base_url
      base = "https://#{base}" unless base.match?(%r{\Ahttps?://})
      base.sub(%r{/\z}, "") + "/api/v1/a2a"
    end
end
