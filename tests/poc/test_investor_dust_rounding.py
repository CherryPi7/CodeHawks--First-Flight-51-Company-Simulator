import boa
from eth_utils import to_wei

def test_investor_dust_rounding(industry_contract, OWNER):
    # Seed company so share price > 0
    boa.env.set_balance(OWNER, to_wei(2, "ether"))
    with boa.env.prank(OWNER):
        industry_contract.fund_cyfrin(0, value=to_wei(1, "ether"))

    attacker = boa.env.generate_address("attacker")
    dust = 10**12  # 0.000001 ETH; tweak if needed
    boa.env.set_balance(attacker, dust)

    before = industry_contract.get_balance()
    with boa.env.prank(attacker):
        try:
            industry_contract.fund_cyfrin(1, value=dust)  # investor path
        except Exception:
            # If contract rejects dust, that's fine (no vuln)
            return

    shares = industry_contract.get_my_shares(caller=attacker)
    after = industry_contract.get_balance()

    # Fails if investor gets 0 shares but balance increased (donation)
    assert not (shares == 0 and after > before), \
        "Investor can donate dust: 0 shares minted but ETH accepted"
