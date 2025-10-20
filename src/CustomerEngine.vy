# @version ^0.4.1
# pragma nonreentrancy on
# @license MIT
"""
@title Cyfrin Industry - Customer Engine
@notice Simulates customer demand for a blockchain-based company simulation.
@dev Interacts with CompanyGame to trigger item sales based on reputation and randomness.
@dev Enforces cooldown, payment, and reputation checks to simulate realistic demand.
@dev Only the CompanyGame contract can receive ETH and fulfill sales via `sell_to_customer`.
@author Sir M. (Shades) Ayomide
@ co-author Chukwubuike Victory Chime aka yeahChibyke
"""

# ------------------------------------------------------------------
#                        IN-LINE INTERFACE
# ------------------------------------------------------------------
interface CompanyGame:
    def sell_to_customer(requested: uint256): payable
    def reputation() -> uint256: view


# ------------------------------------------------------------------
#                        STATE VARIABLES
# ------------------------------------------------------------------
ITEM_PRICE: constant(uint256) = 2 * 10**16  # 0.02 ETH per item
MAX_REQUEST: constant(uint256) = 5  # Max items per demand
MIN_REPUTATION: constant(uint256) = 60  # Minimum reputation to receive demand
COOLDOWN: constant(uint256) = 60  # Cooldown in seconds between demands

# Maps user address to last trigger timestamp
last_trigger: public(HashMap[address, uint256])

# Address of the connected CompanyGame contract
company: public(address)

# ------------------------------------------------------------------
#                           CONSTRUCTOR
# ------------------------------------------------------------------
@deploy
def __init__(_company: address):
    self.company = _company


# ------------------------------------------------------------------
#                        EXTERNAL FUNCTIONS
# ------------------------------------------------------------------
@payable
@external
def trigger_demand():
    """
    @notice Simulates a customer placing a demand for items from the company.
    @dev Users must pay ETH to request items. Excess ETH is refunded.
    @dev Demand size is pseudo-random (1 - 5 items), influenced by company reputation.
    @dev Can only be called once per address every `COOLDOWN` seconds.
    @dev Requires company reputation ≥ `MIN_REPUTATION`.
    @dev Calls `sell_to_customer` on CompanyGame with exact ETH required.
    @dev Reverts if call fails (e.g., insufficient inventory).
    """
    # Cooldown enforcement
    assert (
        block.timestamp > self.last_trigger[msg.sender] + COOLDOWN
    ), "Wait before next demand!!!"
    self.last_trigger[msg.sender] = block.timestamp

    # Reputation check
    rep: uint256 = staticcall CompanyGame(self.company).reputation()
    assert rep >= MIN_REPUTATION, "Reputation too low for demand!!!"

    # Pseudo-random demand calculation
    seed: uint256 = convert(
        keccak256(
            concat(
                convert(block.timestamp, bytes32), convert(msg.sender, bytes32)
            )
        ),
        uint256,
    )
    base: uint256 = seed % 5  # 0 to 4
    extra_item_chance: uint256 = 0
    if (seed % 100) < (rep - 50):
        extra_item_chance = 1

    requested: uint256 = base + 1 + extra_item_chance  # 1 to 6
    requested = min(requested, MAX_REQUEST)  # cap at 5

    # ETH payment enforcement
    total_cost: uint256 = requested * ITEM_PRICE
    assert msg.value >= total_cost, "Insufficient payment!!!"

    # Refund excess ETH
    excess: uint256 = msg.value - total_cost
    if excess > 0:
        send(msg.sender, excess)

    data: Bytes[36] = concat(
        method_id("sell_to_customer(uint256)"), convert(requested, bytes32)
    )

    # Call CompanyGame
    raw_call(self.company, data, value=total_cost, revert_on_failure=True)
