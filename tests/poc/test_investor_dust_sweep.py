import boa
from eth_utils import to_wei

def test_investor_dust_sweep(industry_contract, OWNER):
    boa.env.set_balance(OWNER, to_wei(2, "ether"))
    with boa.env.prank(OWNER):
        industry_contract.fund_cyfrin(0, value=to_wei(1, "ether"))

    attacker = boa.env.generate_address("attacker")
    # try several tiny values
    dusts = [1, 10, 10**6, 10**9, 10**12, 10**14]
    for dust in dusts:
        boa.env.set_balance(attacker, dust)
        before = industry_contract.get_balance()
        with boa.env.prank(attacker):
            try:
                industry_contract.fund_cyfrin(1, value=dust)
            except Exception:
                continue  # contract rejected — good

        shares = industry_contract.get_my_shares(caller=attacker)
        after = industry_contract.get_balance()

        assert not (shares == 0 and after > before), \
            f"Dust donation accepted: value={dust}, shares=0, balance increased"
