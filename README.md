# Decentralized Music Publishing

These smart contracts facilitate a decentralized governance model, revenue sharing, and licensing management. The system allows participants to propose and vote on key decisions, manage revenue distribution, and handle licensing fees efficiently.

## Table of Contents

- [Contracts Overview](#contracts-overview)
- [Governance & Voting Contract](#governance--voting-contract)
  - [Key Features](#key-features)
  - [Proposal Types](#proposal-types)
  - [Public Functions](#public-functions)
- [Revenue Sharing Contract](#revenue-sharing-contract)
  - [Key Features](#key-features)
  - [Public Functions](#public-functions)
- [Licensing Contract](#licensing-contract)
  - [Key Features](#key-features)
  - [Public Functions](#public-functions)
- [Setup and Usage](#setup-and-usage)
- [Error Codes](#error-codes)

---

## Contracts Overview

### 1. Governance & Voting Contract
This contract manages the proposal submission and voting process for the community. It ensures that only registered users can vote and that proposals are executed based on the community's consensus.

### 2. Revenue Sharing Contract
The revenue sharing contract handles the management of contributor shares and distributes revenue based on these shares. It ensures that the contributions are acknowledged and compensated accordingly.

### 3. Licensing Contract
The licensing contract manages the licensing fees and authorized users. It allows authorized users to pay licensing fees and ensures proper handling of these fees for revenue distribution.

---

## Governance & Voting Contract

### Key Features

- **Proposal Management**: Allows the owner to submit proposals for voting.
- **Voting Mechanism**: Only registered voters can cast votes on proposals.
- **Proposal Execution**: Executes proposals based on voting results, including licensing and revenue-related proposals.

### Proposal Types

- **General Proposal**: A proposal that doesn't fit into the other two categories.
- **Licensing Proposal**: Proposals related to licensing agreements.
- **Revenue Proposal**: Proposals concerning revenue distribution.

### Public Functions

- **set-contract-references**: Set the addresses for the licensing and revenue contracts.
- **is-authorized-member**: Check if a user is a registered voter.
- **submit-proposal**: Submit a new proposal with title, type, target, and amount.
- **cast-vote**: Cast a vote on the current proposal (true for yes, false for no).
- **end-voting**: Conclude voting and execute the proposal if passed.

---

## Revenue Sharing Contract

### Key Features

- **Share Management**: Allows the owner or voting contract to set or update contributor shares.
- **Revenue Pool Management**: Accumulates revenue and distributes it based on contributor shares.
- **Automated Revenue Distribution**: Distributes the accumulated revenue to contributors based on their share percentage.

### Public Functions

- **set-contracts**: Set the addresses for the voting and licensing contracts.
- **implement-proposal**: Implement the approved proposal from the voting contract.
- **set-share**: Define or update a contributor's share percentage.
- **receive-payment**: Accept payments from the licensing contract to the revenue pool.
- **distribute-revenue**: Distribute the accumulated revenue pool among all contributors.

---

## Licensing Contract

### Key Features

- **Licensing Fee Management**: Defines and updates the licensing fee for authorized users.
- **User Authorization**: Manages which users are authorized to pay licensing fees.
- **Payment Processing**: Handles the transfer of licensing fees to the revenue contract.

### Public Functions

- **set-contracts**: Set the addresses for the voting and revenue contracts.
- **is-authorized**: Check if a user is authorized to pay licensing fees.
- **implement-proposal**: Implement proposals to add or remove authorized users or update licensing fees.
- **set-licensing-fee**: Update the current licensing fee.
- **add-authorized-user**: Add a new authorized user.
- **remove-authorized-user**: Remove an authorized user.
- **pay-license-fee**: Process the payment of the licensing fee.

---

## Setup and Usage

1. **Deployment**: Deploy the contracts on a compatible blockchain platform (e.g., Stacks).
2. **Set Contract References**: After deploying, set the contract references for the governance, revenue, and licensing contracts using the `set-contract-references` function.
3. **Register Users**: Use the voting contract to register users who will participate in governance.
4. **Submit Proposals**: The contract owner can submit proposals for community voting.
5. **Manage Shares**: Contributors can have their shares managed via the revenue sharing contract.
6. **Payment Processing**: Users can pay their licensing fees, which will be managed by the licensing contract.

---

## Error Codes

- **ERR-UNAUTHORIZED**: Caller is not authorized to perform the action.
- **ERR-ALREADY-EXISTS**: A proposal or user already exists.
- **ERR-NOT-FOUND**: The specified user or contract was not found.
- **ERR-VOTING-CLOSED**: Voting period has ended.
- **ERR-NOT-REGISTERED**: User is not registered to vote.
- **ERR-ACTIVE-PROPOSAL**: A proposal is already active.
- **ERR-INVALID-PROPOSAL**: The proposal type is invalid.
- **ERR-INVALID-SHARE**: The specified share percentage is invalid.
- **ERR-TOTAL-EXCEEDED**: Total share percentage exceeds 100.
- **ERR-NOT-AUTHORIZED**: The user is not authorized to perform this action.
- **ERR-INVALID-AMOUNT**: The amount specified is invalid.

---

This README provides a comprehensive overview of your contracts and their functionalities. You can customize it further based on your specific implementation and needs!
