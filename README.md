# Company Simulator

### Prize Pool TO BE FILLED OUT BY CYFRIN

- Total Pool -  
- H/M -  
- Low -  

- Starts: Oct 23rd 
- Ends:  Oct 30th

- nSLOC:  265

[//]: # (contest-details-open)

## About the Project

Company Simulator is a decentralized smart contract system built in Vyper that simulates the operations of a virtual company. It includes modules for production, inventory management, customer demand, shareholding, reputation, and financial health.

## Actors

```text
Actors:
    Owner: Deploys and controls core company functions such as production, share cap increases, and debt repayment.
    Investor: Public user who funds the company and receives proportional shares.
    Customer: Simulates demand by purchasing items from the company.
```

Centralization Risks:
- Only the owner can produce items, increase share cap, and pay off debt.
- Reputation gating and share issuance are controlled by the owner.
- Customers are rate-limited to prevent spam but can still influence company revenue and reputation.

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

All contracts in `src` are in scope.

```text
src/
├── Cyfrin_Hub.vy         # Core contract managing company operations
├── CustomerEngine.vy     # Simulates customer demand and triggers sales
```

[//]: # (scope-close)

## Compatibilities

```text
Compatibilities:
  Blockchains:
    - Ethereum / Any EVM-compatible chain
  Tokens:
    - ETH only
```

[//]: # (getting-started-open)

## Setup

To deploy and test the Company Simulator locally using Moccasin:

Build & Deploy:
```bash
mox run deploy
```

Run Tests:
```bash
mox test
```

_For documentation, run `mox --help` or visit [Moccasin Docs](https://cyfrin.github.io/moccasin)_

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues
- None
[//]: # (known-issues-close)
