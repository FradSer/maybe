# frozen_string_literal: true

require "test_helper"

class WellKnown::AgentCardControllerTest < ActionDispatch::IntegrationTest
  test "serves the agent card publicly" do
    get "/.well-known/agent-card.json"

    assert_response :success
    assert_equal "application/json", response.media_type

    card = JSON.parse(response.body)
    assert_equal "Maybe Finance Agent", card["name"]
    assert_equal "1.0.0", card["version"]
    assert_equal "1.0", card.dig("supportedInterfaces", 0, "protocolVersion")
    assert card.dig("supportedInterfaces", 0, "url").starts_with?("http://www.example.com")
    assert card.dig("supportedInterfaces", 0, "url").ends_with?("/api/v1/a2a")
    assert_equal "JSONRPC", card.dig("supportedInterfaces", 0, "protocolBinding")
    assert_equal false, card.dig("capabilities", "streaming")
    assert_equal false, card.dig("capabilities", "pushNotifications")
    assert_equal [ "GetTransactions", "GetAccounts", "GetBalanceSheet", "GetIncomeStatement" ], card["skills"].map { |s| s["id"] }
    assert_equal({ "type" => "apiKey", "in" => "header", "name" => "X-Api-Key" }, card.dig("securitySchemes", "apiKey"))
  end

  test "uses APP_DOMAIN for the interface URL when set" do
    with_env_overrides APP_DOMAIN: "https://maybe.example.com" do
      get "/.well-known/agent-card.json"

      assert_equal "https://maybe.example.com/api/v1/a2a", JSON.parse(response.body).dig("supportedInterfaces", 0, "url")
    end
  end

  test "serves the card without the json extension" do
    get "/.well-known/agent-card"

    assert_response :success
  end
end
