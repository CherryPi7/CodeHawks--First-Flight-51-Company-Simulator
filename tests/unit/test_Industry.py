import boa
from eth_utils import to_wei

SET_OWNER_BALANCE = to_wei(1000, "ether")

FUND_VALUE = to_wei(20, "ether")

def test_FundOwner_Works_Correctly(industry_contract, OWNER):
    # arrange
    boa.env.set_balance(OWNER, SET_OWNER_BALANCE)
    
    #act
    
    with boa.env.prank(OWNER):
        industry_contract.fund_cyfrin(0, value=FUND_VALUE)

    #assert
    assert industry_contract.get_balance() == FUND_VALUE, "Balance should be 10 eth after funding"


def test_FundCompany_Works_Correctly(industry_contract, OWNER, PATRICK):
    # arrange
    boa.env.set_balance(OWNER, FUND_VALUE)

    with boa.env.prank(OWNER):
        industry_contract.fund_cyfrin(0, value=FUND_VALUE)

    # act
    with boa.env.prank(PATRICK):
        industry_contract.fund_cyfrin(1, value=FUND_VALUE)

    # assert
    assert industry_contract.get_balance() == 2 * FUND_VALUE, "Balance should be 20 eth after funding"


def test_FundCompany_Mints_Correct_Shares(industry_contract, OWNER, PATRICK):
    # arrange
    boa.env.set_balance(OWNER, FUND_VALUE)
    with boa.env.prank(OWNER):
        industry_contract.fund_cyfrin(0, value=to_wei(10, "ether"))

    # -- Calculate expected shares (no shares issued yet, so use INITIAL_SHARE_PRICE) --
    initial_share_price = 1 * 10**15 
    expected_shares = FUND_VALUE // initial_share_price

    #act
    with boa.env.prank(PATRICK):
        industry_contract.fund_cyfrin(1, value=FUND_VALUE)
        patrick_shares = industry_contract.get_my_shares(caller=PATRICK)

    # assert
    assert patrick_shares == expected_shares, f"Expected {expected_shares} shares, got {patrick_shares}"
