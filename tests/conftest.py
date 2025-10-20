# ------------------------------------------------------------------
#                             IMPORTS
# ------------------------------------------------------------------

import boa
import pytest
from eth_utils import to_wei

from script.deploy import deploy_engine, deploy_industry

# ------------------------------------------------------------------
#                            VARIABLES
# ------------------------------------------------------------------

SET_BALANCE = to_wei(1000, "ether")


# ------------------------------------------------------------------
#                         SESSION FIXTURES
# ------------------------------------------------------------------

@pytest.fixture(scope="session")
def industry_contract():
    return deploy_industry()

@pytest.fixture(scope="session")
def customer_engine_contract(industry_contract):
    return deploy_engine(industry_contract)

@pytest.fixture(scope="session")
def OWNER(industry_contract):
    return industry_contract.OWNER_ADDRESS()


# ------------------------------------------------------------------
#                        FUNCTION FIXTURES
# ------------------------------------------------------------------

@pytest.fixture(scope="function")
def PATRICK():
    return _generate_account_with_balance("patrick")

@pytest.fixture(scope="function")
def DACIAN():
    return _generate_account_with_balance("dacian")

@pytest.fixture(scope="function")
def PASCAL():
    return _generate_account_with_balance("pascal")

@pytest.fixture(scope="function")
def HE1M():
    return _generate_account_with_balance("he1m")


# ------------------------------------------------------------------
#                              HELPER
# ------------------------------------------------------------------

def _generate_account_with_balance(name):
    """Helper function to generate account with balance"""
    address = boa.env.generate_address(name)
    boa.env.set_balance(address, SET_BALANCE)
    return address
