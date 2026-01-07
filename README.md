1. We are going to have a contract controlled by DAO.
2. Every transaction that the DAO wants to send has to be voted on
3. We will use ERC20 tokens for voting(Bad model, there are lot please do research) 

# DAO Sample – Governor + Timelock + Token (Foundry)

This repository is a **minimal but complete DAO (Decentralized Autonomous Organization) implementation** built using **OpenZeppelin Governor contracts** and tested with **Foundry**.

The project demonstrates **end-to-end on-chain governance**, including proposal creation, voting, timelock queuing, and execution — without UI complexity.

---

## What This Project Demonstrates

This DAO shows how a decentralized governance system works using:

* **ERC20Votes** for voting power
* **Governor** for proposal lifecycle
* **TimelockController** for delayed execution
* **Ownable contract controlled only by governance**

Everything is tested at the smart-contract level.

---

## Core DAO Components

### 1. Governance Token (`GovToken`)

* ERC20 token with voting power
* Uses delegation (`delegate`) for governance participation
* Voting power is snapshot-based

### 2. Governor (`MyGovernor`)

* Handles proposal creation
* Manages voting lifecycle
* Enforces voting delay & voting period
* Integrates with Timelock for execution

### 3. Timelock (`TimeLock`)

* Enforces a mandatory execution delay
* Prevents immediate proposal execution
* Acts as the **only owner** of governed contracts

### 4. Governed Contract (`Box`)

* Simple contract with a `store(uint256)` function
* Ownership transferred to Timelock
* Cannot be updated directly by users

---

## Governance Lifecycle (End-to-End Flow)

A proposal must follow this **strict lifecycle**:

```
Propose
   ↓
Pending
   ↓ (after votingDelay blocks)
Active
   ↓
Vote
   ↓ (after votingPeriod blocks)
Succeeded
   ↓
Queued (Timelock)
   ↓ (after timelock delay)
Executed
```

Any attempt to skip a step will **revert**.

---

## Proposal States (OpenZeppelin Governor)

```solidity
enum ProposalState {
    Pending,    // 0
    Active,     // 1
    Canceled,   // 2
    Defeated,   // 3
    Succeeded,  // 4
    Queued,     // 5
    Executed    // 6
}
```

---

## Project Structure

```
DAO-Sample/
├── src/
│   ├── GovToken.sol        # ERC20Votes governance token
│   ├── MyGovernor.sol     # OpenZeppelin Governor implementation
│   ├── TimeLock.sol       # TimelockController wrapper
│   └── Box.sol             # Governed contract
│
├── test/
│   └── MyGovernorTest.t.sol # Full DAO lifecycle tests
│
├── lib/                    # OpenZeppelin & dependencies
├── foundry.toml
└── README.md
```

---

## Tech Stack

* Solidity ^0.8.30
* OpenZeppelin Contracts (Governor, Timelock, ERC20Votes)
* Foundry (forge)
* Forge Std (vm, console)

---

## Prerequisites

Make sure you have:

* Git
* Foundry

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

## Clone the Repository

```bash
git clone https://github.com/DecentralizedGlasses/DAO-Sample.git
cd DAO-Sample
```

---

## Install Dependencies

```bash
forge install
```

---

## Run Tests

```bash
forge test
```

Verbose output (recommended for governance debugging):

```bash
forge test -vvvv
```

---

## What the Tests Cover

The test suite verifies:

* ❌ Direct contract updates without governance revert
* ✅ Proposal creation
* ✅ Voting delay enforcement
* ✅ Voting with delegated tokens
* ✅ Voting period enforcement
* ✅ Timelock queueing
* ✅ Timelock delay enforcement
* ✅ Successful execution
* ✅ Final state correctness

---

## Why Timelock Is Required

The Timelock ensures:

* No instant governance execution
* Community has time to react to proposals
* Governance actions are transparent and predictable

Only the Timelock can:

* Execute proposals
* Own governed contracts

---

## Important Testing Rules (Very Important)

* **Voting uses block numbers**, not timestamps
* **Timelock uses timestamps**, not blocks
* `vm.roll()` → advance blocks
* `vm.warp()` → advance time
* Skipping steps will cause `GovernorUnexpectedProposalState` reverts

---

## Common Errors Explained

### `GovernorUnexpectedProposalState`

* Proposal lifecycle step skipped
* Voting delay or voting period not respected

### `OwnableInvalidOwner(address(0))`

* Contract deployed with zero owner
* Ownership misconfigured

### Proposal stuck in `Pending`

* Voting delay not passed
* Blocks not advanced

---

## Learning Outcomes

By studying this project, you will understand:

* How DAO governance works on-chain
* How OpenZeppelin Governor enforces rules
* Why governance uses block-based timing
* How Timelock prevents instant execution
* How to test DAOs correctly using Foundry

---

## References

* OpenZeppelin Governor Documentation
* OpenZeppelin TimelockController
* Foundry Book
* Ethereum Governance Standards

---

## Final Notes

This repository is intentionally **simple and minimal**.

It is designed to:

* Teach governance mechanics clearly
* Avoid UI distractions
* Focus on correctness and security

If you understand this codebase,
you understand **real DAO governance**.
