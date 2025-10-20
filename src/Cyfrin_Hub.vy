# @version ^0.4.1
# pragma nonreentrancy on
# @license MIT
"""
@title Cyfrin Industry
@notice This contract simulates a company that produces and sells items to customers.
@dev It includes features for production, sales, reputation management, and shareholding.
@dev The company can be funded by investors, and shares can be issued up to a public cap.
@dev The company can also increase its share cap, and it manages holding costs and bankruptcy
@author Sir M. (Shades) Ayomide
@ co-author Chukwubuike Victory Chime aka yeahChibyke
"""

# ------------------------------------------------------------------
#                              EVENTS
# ------------------------------------------------------------------
event Produced:
    amount: uint256
    cost: uint256


event Sold:
    amount: uint256
    revenue: uint256


event Withdrawn_Shares:
    investor: address
    shares: uint256


event ReputationChanged:
    new_reputation: uint256


event SharesIssued:
    investor: address
    amount: uint256


event ShareCapIncreased:
    new_cap: uint256


# ------------------------------------------------------------------
#                         STATE VARIABLES
# ------------------------------------------------------------------

OWNER: public(immutable(address))  # Owner of the company (deployer)

inventory: public(uint256)  # Number of items currently in stock
reputation: public(uint256)  # Trust score of the company (0–100)
last_hold_time: public(uint256)  # Timestamp of last holding cost application
company_balance: public(uint256)  # Current ETH balance available for operations
holding_debt: public(uint256)  # Accumulated unpaid holding costs
CUSTOMER_ENGINE: public(address)  # Trusted contract that can trigger sales
customer_engine_set: public(bool)  # Flag to prevent re-setting the engine

public_shares_cap: public(uint256)  # Max shares available for public investment
issued_shares: public(uint256)  # Total shares currently issued
shares: public(HashMap[address, uint256])  # Investor address → shares owned
share_received_time: public(
    HashMap[address, uint256]
)  # Timestamp of first share acquisition

TOTAL_SHARES: constant(uint256) = 1_000_000_000  # Fixed total supply of shares
MAX_PAYOUT_PER_SHARE: constant(uint256) = (
    2 * 10**15
)  # Max redeemable per share (0.002 ETH)
INITIAL_SHARE_PRICE: constant(uint256) = (
    1 * 10**15
)  # Default share price (0.001 ETH)
PRODUCTION_COST: constant(uint256) = (
    1 * 10**16
)  # Cost to produce one item (0.01 ETH)
SALE_PRICE: constant(uint256) = 2 * 10**16  # Revenue per item sold (0.02 ETH)
HOLDING_COST_PER_ITEM: constant(uint256) = (
    1 * 10**15
)  # Storage cost per item/hour (0.001 ETH)

REPUTATION_PENALTY: constant(uint256) = 5  # Reputation loss per failed sale
REPUTATION_REWARD: constant(uint256) = 2  # Reputation gain per successful sale

LOCKUP_PERIOD: constant(uint256) = 30 * 86400  # Lockup duration (30 days)
EARLY_WITHDRAWAL_PENALTY: constant(
    uint256
) = 10  # Penalty % for early withdrawal

# ------------------------------------------------------------------
#                           CONSTRUCTOR
# ------------------------------------------------------------------
@deploy
def __init__():
    """
    @notice Initializes the company with default values.
    @dev Sets owner, inventory, reputation, and initial share cap.
        CUSTOMER_ENGINE must be set later via `set_customer_engine`.
    """
    OWNER = msg.sender
    self.inventory = 0
    self.reputation = 100
    self.last_hold_time = block.timestamp
    self.public_shares_cap = 1_000_000
    self.issued_shares = 0


# ------------------------------------------------------------------
#                        EXTERNAL FUNCTIONS
# ------------------------------------------------------------------
@external
@payable
def fund_cyfrin(action: uint256):
    """
    @notice Routes ETH funding to either the owner or investor logic.
    @dev Accepts ETH and delegates to fund_owner() or fund_investor() based on action.
    @dev action = 0 → fund_owner(); action = 1 → fund_investor().
    @dev Reverts if action is not 0 or 1.
    @param action Selector for funding type: 0 for owner, 1 for investor.
    """
    if action == 0:
        self.fund_owner()
    elif action == 1:
        self.fund_investor()
    else:
        raise "Input MUST be between 0 and 1!!!"


@external
def produce(amount: uint256):
    """
    @notice Produces new items at a fixed cost per unit.
    @dev Only the owner can call this function.
    @dev Requires sufficient company_balance to cover PRODUCTION_COST * amount.
    @dev Increases inventory and reduces company_balance.
    @dev Emits Produced event.
    @param amount Number of items to produce.
    """
    assert not self._is_bankrupt(), "Company is bankrupt!!!"
    assert msg.sender == OWNER, "Not the owner!!!"
    total_cost: uint256 = amount * PRODUCTION_COST
    assert self.company_balance >= total_cost, "Insufficient balance!!!"

    self.company_balance -= total_cost
    self.inventory += amount
    log Produced(amount=amount, cost=total_cost)


@external
@payable
def sell_to_customer(requested: uint256):
    """
    @notice Internal sale function triggered only by the CustomerEngine.
    @dev This function is not meant to be called directly by users.
    @dev Only CUSTOMER_ENGINE is authorized to call this function.
    @dev Applies holding cost, checks inventory, updates reputation, and adds revenue.
    @dev Emits Sold or ReputationChanged event.
    @param requested Number of items requested by customer.
    """
    assert msg.sender == self.CUSTOMER_ENGINE, "Not the customer engine!!!"
    assert not self._is_bankrupt(), "Company is bankrupt!!!"
    self._apply_holding_cost()

    if self.inventory >= requested:
        self.inventory -= requested
        revenue: uint256 = requested * SALE_PRICE
        self.company_balance += revenue
        if self.reputation < 100:
            # Increase reputation for successful sale
            self.reputation = min(self.reputation + REPUTATION_REWARD, 100)
        else:
            # Maintain reputation if already at max
            self.reputation = 100
        log Sold(amount=requested, revenue=revenue)
    else:
        self.reputation = min(max(self.reputation - REPUTATION_PENALTY, 0), 100)

        log ReputationChanged(new_reputation=self.reputation)


@external
def withdraw_shares():
    """
    @notice Allows investors to redeem their shares for ETH.
    @dev Payout is based on current share price (net worth per share).
    @dev If shares are withdrawn before LOCKUP_PERIOD, a 10% penalty is applied.
    @dev Total payout is capped at MAX_PAYOUT_PER_SHARE per share to prevent fund draining.
    @dev Investor's share count is reset to zero.
    @dev Emits Withdrawn_Shaares event.
    """
    shares_owned: uint256 = self.shares[msg.sender]
    assert shares_owned > 0, "Not an investor!!!"

    share_price: uint256 = self.get_share_price()
    payout: uint256 = shares_owned * share_price

    # Check lockup
    time_held: uint256 = block.timestamp - self.share_received_time[msg.sender]
    if time_held < LOCKUP_PERIOD:
        penalty: uint256 = payout * EARLY_WITHDRAWAL_PENALTY // 100
        payout -= penalty

    max_payout: uint256 = shares_owned * MAX_PAYOUT_PER_SHARE
    if payout > max_payout:
        payout = max_payout

    self.shares[msg.sender] = 0
    self.issued_shares -= shares_owned

    assert self.company_balance >= payout, "Insufficient company funds!!!"

    self.company_balance -= payout

    raw_call(
        msg.sender,
        b"",
        value=payout,
        revert_on_failure=True,
    )

    log Withdrawn_Shares(investor=msg.sender, shares=shares_owned)


@external
def increase_share_cap(amount: uint256):
    """
    @notice Increases the number of shares available for public investment.
    @dev Only the owner can call this function.
    @dev Cannot exceed TOTAL_SHARES (1 billion).
    @dev Used to allow more investors to join over time.
    @param amount Number of new shares to make available for funding.
    """
    assert msg.sender == OWNER, "Not the owner!!!"
    assert (
        self.public_shares_cap + amount <= TOTAL_SHARES
    ), "Error: Exceeds total shares"

    self.public_shares_cap += amount
    log ShareCapIncreased(new_cap=self.public_shares_cap)


@payable
@external
def pay_holding_debt():
    """
    @notice Allows the owner to pay down the company's holding debt.
    @dev Only the owner can call this function.
    @dev If payment exceeds debt, the excess is added to company_balance.
    @dev If payment is partial, debt is reduced accordingly.
    """

    assert msg.sender == OWNER, "Not the owner!!!"
    assert self.holding_debt > 0, "No debt to pay"

    if msg.value >= self.holding_debt:
        excess: uint256 = msg.value - self.holding_debt
        self.holding_debt = 0
        self.company_balance += excess
    else:
        self.holding_debt -= msg.value


@external
def set_customer_engine(engine: address):
    """
    @notice Sets the trusted CustomerEngine contract that can trigger sales.
    @dev Can only be called once by the owner.
    @dev Prevents unauthorized contracts or users from simulating demand.
    @dev Establishes trust relationship between CompanyGame and CustomerEngine.
    @param engine Address of the deployed CustomerEngine contract.
    """
    assert msg.sender == OWNER, "Not the owner!!!"
    assert not self.customer_engine_set, "Engine already set"
    self.CUSTOMER_ENGINE = engine
    self.customer_engine_set = True


# ------------------------------------------------------------------
#                        INTERNAL FUNCTIONS
# ------------------------------------------------------------------
@payable
@internal
def fund_owner():
    """
    @notice Allows the owner to inject ETH into the company without receiving shares.
    @dev Increases company_balance directly. No shares are issued.
        Only the owner can call this function.
    @dev This simulates owner capital injections or personal investment.
    """
    assert msg.sender == OWNER, "Not the owner!!!"
    self.company_balance += msg.value


@payable
@internal
def fund_investor():
    """
    @notice Allows public users to invest ETH in exchange for shares.
    @dev Share amount is calculated based on current net worth per share.
        If no shares have been issued, uses INITIAL_SHARE_PRICE.
    @dev Investor receives shares proportional to contribution.
        Excess shares beyond cap are trimmed.
    @dev Emits SharesIssued event.
    """
    assert msg.value > 0, "Must send ETH!!!"
    assert (
        self.issued_shares <= self.public_shares_cap
    ), "Share cap reached!!!"
    assert (self.company_balance > self.holding_debt), "Company is insolvent!!!"

    # Calculate shares based on contribution
    net_worth: uint256 = 0
    if self.company_balance > self.holding_debt:
        net_worth = self.company_balance - self.holding_debt

    share_price: uint256 = (
        net_worth // max(self.issued_shares, 1)
        if self.issued_shares > 0
        else INITIAL_SHARE_PRICE
    )
    new_shares: uint256 = msg.value // share_price

    # Cap shares if exceeding visible limit
    available: uint256 = self.public_shares_cap - self.issued_shares
    if new_shares > available:
        new_shares = available

    self.shares[msg.sender] += new_shares
    self.issued_shares += new_shares
    self.company_balance += msg.value

    if self.share_received_time[msg.sender] == 0:
        self.share_received_time[msg.sender] = block.timestamp

    log SharesIssued(investor=msg.sender, amount=new_shares)


@internal
def _apply_holding_cost():
    """
    @dev Applies hourly holding cost for stored inventory since last call.
    @dev Cost is calculated per item per second (from hourly rate).
    @dev If company cannot pay, the cost is added to holding_debt.
    @dev Updates last_hold_time to current timestamp.
    """
    seconds_passed: uint256 = block.timestamp - self.last_hold_time
    # Convert hourly cost to per-second
    cost_per_second: uint256 = HOLDING_COST_PER_ITEM // 3600
    cost: uint256 = (seconds_passed * self.inventory * cost_per_second)

    if self.company_balance >= cost:
        self.company_balance -= cost
    else:
        self.holding_debt += cost - self.company_balance
        self.company_balance = 0

    self.last_hold_time = block.timestamp


# ------------------------------------------------------------------
#                          VIEW FUNCTIONS
# ------------------------------------------------------------------

@view
@internal
def get_share_price() -> uint256:
    """
    @notice Calculates the current share price based on net worth.
    @dev Net worth = company_balance - holding_debt (capped at 0).
    @dev Share price = net_worth / issued_shares.
    @dev If no shares issued, returns INITIAL_SHARE_PRICE.
    @return Price per share in wei.
    """
    if self.issued_shares == 0:
        return INITIAL_SHARE_PRICE
    net_worth: uint256 = max(self.company_balance - self.holding_debt, 0)
    return net_worth // self.issued_shares


@internal
@view
def _is_bankrupt() -> bool:
    return (self.company_balance < self.holding_debt)


@view
@external
def get_balance() -> uint256:
    """
    @notice Returns the current ETH balance of the company.
    @dev Includes all funds available for operations.
    @return Company's ETH balance in wei.
    """
    return self.company_balance


@view
@external
def get_reputation_tier() -> String[16]:
    """
    @notice Returns a human-readable reputation tier.
    @dev Based on current reputation score (0-100).
    @return One of: "Excellent", "Good", "Poor", "Terrible"
    """
    if self.reputation >= 90:
        return "Excellent"
    elif self.reputation >= 70:
        return "Very Good"
    elif self.reputation >= 50:
        return "Fair"
    else:
        return "Terrible"


@view
@external
def get_my_shares() -> uint256:
    """
    @notice Returns the number of shares owned by the caller.
    @dev Useful for investors to check their stake.
    @return Number of shares held by msg.sender.
    """
    return self.shares[msg.sender]


@view
@external
def OWNER_ADDRESS() -> address:
    return OWNER


# ------------------------------------------------------------------
#                          FALLBACK
# ------------------------------------------------------------------

@payable
@external
def __default__():
    """
    @notice Rejects any direct ETH transfers to the contract.
    @dev Prevents accidental ETH deposits.
    @dev Reverts with error message.
    """
    raise "Direct ETH not accepted!!!"
