Feature: Theme-aware trend colors
  Trend colors remain readable as inline text in both themes

  Scenario: Positive trends use the contrast-safe positive token
    Given a trend rises with the default favorable direction
    When its color is requested
    Then the positive trend token is returned

  Scenario: Negative trends use the contrast-safe negative token
    Given a trend falls with the default favorable direction
    When its color is requested
    Then the negative trend token is returned

  Scenario: Flat trends use the contrast-safe neutral token
    Given a trend is unchanged
    When its color is requested
    Then the flat trend token is returned

  Scenario: Favorable downward movement remains positive
    Given a liability trend falls with a downward favorable direction
    When its color is requested
    Then the positive trend token is returned
