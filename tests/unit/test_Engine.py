import boa
from eth_utils import to_wei

FUND_VALUE = to_wei(20, "ether") # not used

def test_Trigger_Demand_Trigger_Works_Correctly(industry_contract, customer_engine_contract, OWNER, PATRICK):
    # arrange
    boa.env.set_balance(OWNER, to_wei(10, "ether"))
    
    with boa.env.prank(OWNER):
        industry_contract.fund_cyfrin(0, value=to_wei(10, "ether"))
        industry_contract.produce(10)  # produce enough items
    
    assert industry_contract.inventory() == 10, "Inventory should be equals to 10"

    # act
    with boa.env.prank(PATRICK):
        customer_engine_contract.trigger_demand(value=to_wei(0.1, "ether"))  # adjust as needed

    # assert
    assert industry_contract.inventory() < 10, "Inventory should reduce"
