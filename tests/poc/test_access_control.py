import boa
from eth_utils import to_wei

def test_produce_requires_owner(industry_contract, OWNER):
    boa.env.set_balance(OWNER, to_wei(10, "ether"))
    with boa.env.prank(OWNER):
        industry_contract.fund_cyfrin(0, value=to_wei(1, "ether"))
        industry_contract.produce(1)  # ok

    attacker = boa.env.generate_address("attacker")
    with boa.env.prank(attacker):
        # must revert for non-owner
        try:
            industry_contract.produce(1)
            assert False, "produce() allowed non-owner (potential vuln)"
        except Exception:
            pass

def test_sell_to_customer_requires_engine(industry_contract):
    # random EOA should not be allowed to call sell_to_customer
    attacker = boa.env.generate_address("attacker")
    boa.env.set_balance(attacker, to_wei(1, "ether"))
    with boa.env.prank(attacker):
        try:
            industry_contract.sell_to_customer(1, value=to_wei(0.02, "ether"))
            assert False, "sell_to_customer callable by non-engine (potential vuln)"
        except Exception:
            pass

def test_set_customer_engine_only_once(industry_contract, OWNER):
    e1 = boa.env.generate_address("engine1")
    e2 = boa.env.generate_address("engine2")
    with boa.env.prank(OWNER):
        industry_contract.set_customer_engine(e1)  # first time ok
        try:
            industry_contract.set_customer_engine(e2)  # must revert
            assert False, "set_customer_engine callable multiple times"
        except Exception:
            pass
