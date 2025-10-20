from moccasin.boa_tools import VyperContract

from src import CustomerEngine, Cyfrin_Hub


def deploy_industry() -> VyperContract:
    cyfrin_industry: VyperContract = Cyfrin_Hub.deploy()
    print(f"Cyfrin Industry deployed at {cyfrin_industry.address}")
    
    return cyfrin_industry

def deploy_engine(industry: VyperContract) -> VyperContract:
    customer_engine: VyperContract = CustomerEngine.deploy(industry.address)
    industry.set_customer_engine(customer_engine.address)
    
    print(f"Customer Engine deployed at {customer_engine.address}")
    return customer_engine

def moccasin_main() -> tuple[VyperContract, VyperContract]:
    industry = deploy_industry()
    customer_engine = deploy_engine(industry)
    return industry, customer_engine
