require "test_helper"

class Holding::MaterializerTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:empty)
    @account = @family.accounts.create!(name: "Test", balance: 20000, cash_balance: 20000, currency: "USD", accountable: Investment.new)
    @aapl = securities(:aapl)
  end

  test "syncs holdings" do
    create_trade(@aapl, account: @account, qty: 1, price: 200, date: Date.current)

    # Should have yesterday's and today's holdings
    assert_difference "@account.holdings.count", 2 do
      Holding::Materializer.new(@account, strategy: :forward).materialize_holdings
    end
  end

  test "syncs multi currency trade" do
    create_trade(@aapl, account: @account, qty: 10, price: 180, date: Date.current, currency: "EUR")

    # Holdings are generated in the account's currency (which is what shows to the user),
    # even when the trade itself was executed in a different currency
    assert_difference "@account.holdings.count", 2 do
      Holding::Materializer.new(@account, strategy: :forward).materialize_holdings
    end

    holdings = @account.holdings.to_a
    assert holdings.all? { |h| h.currency == "USD" }
    assert_equal 10, holdings.last.qty
  end

  test "purges stale holdings for unlinked accounts" do
    # Since the account has no entries, there should be no holdings
    Holding.create!(account: @account, security: @aapl, qty: 1, price: 100, amount: 100, currency: "USD", date: Date.current)

    assert_difference "Holding.count", -1 do
      Holding::Materializer.new(@account, strategy: :forward).materialize_holdings
    end
  end
end
