# Community Treasury Smart Contract

## Overview
The Community Treasury Smart Contract is a decentralized governance system that manages community funds through a democratic proposal and voting mechanism. It allows community members to contribute funds, create proposals for fund allocation, vote on proposals, and execute approved transactions.

## Features
- Secure fund management
- Proposal creation and voting system
- Democratic governance
- Emergency controls
- Stake-based proposal system
- Configurable voting parameters

## Core Components

### Treasury Management
- Secure vault for storing community funds
- Tracking of individual contributor balances
- Protected withdrawal mechanism
- Emergency withdrawal capability for administrators

### Proposal System
- Stake-required proposal creation
- Detailed proposal information storage
- Configurable voting windows
- Automated stake return upon proposal completion

### Voting Mechanism
- One vote per address per proposal
- Support and opposition vote tracking
- Configurable quorum requirements
- Minimum participation thresholds
- Automated vote counting and result determination

## Technical Parameters

### Governance Constants
- Voting Window: 10,000 blocks
- Initial Stake Required: 1,000,000 microSTX
- Minimum Participation Threshold: 500 votes
- Success Vote Percentage: 51% (510/1000)

### Error Codes
```
u100 - Access Denied
u101 - Balance Too Low
u102 - Amount Invalid
u103 - Nonexistent Proposal
u104 - Duplicate Vote
u105 - Voting Closed
u106 - Deposit Too Low
u107 - Invalid Payee
u108 - Invalid Text
u109 - Invalid Controller
```

## Public Functions

### Treasury Operations
1. `contribute-funds()`
   - Allows users to contribute STX to the treasury
   - Returns the contribution amount
   - No minimum contribution requirement

2. `initiate-proposal(withdrawal-size, beneficiary, details)`
   - Creates a new funding proposal
   - Requires initial stake deposit
   - Parameters:
     - withdrawal-size: Amount of STX requested
     - beneficiary: Recipient address
     - details: Proposal description (max 256 characters)

3. `record-vote(proposal-number, support)`
   - Records a vote on a specific proposal
   - One vote per address
   - Parameters:
     - proposal-number: Proposal identifier
     - support: Boolean for support/oppose

4. `execute-proposal(proposal-number)`
   - Executes an approved proposal
   - Transfers funds to beneficiary
   - Returns stake to proposal creator
   - Requires meeting voting thresholds

### Administrative Functions
1. `reassign-controller(new-controller)`
   - Transfers administrative control
   - Restricted to current controller

2. `emergency-withdrawal()`
   - Allows emergency withdrawal of all funds
   - Restricted to controller
   - Emergency use only

## Read-Only Functions

1. `get-vault-balance()`
   - Returns current treasury balance

2. `fetch-proposal(proposal-number)`
   - Returns detailed proposal information

3. `check-vote-status(proposal-number, voter)`
   - Checks if an address has voted on a proposal

4. `get-contributor-balance(contributor)`
   - Returns total contributions from an address

## Security Measures

1. Access Control
   - Administrative functions restricted to controller
   - One vote per address per proposal
   - Protected withdrawal mechanisms

2. Input Validation
   - Beneficiary address validation
   - Proposal text length verification
   - Amount validation against balance

3. Vote Protection
   - Duplicate vote prevention
   - Voting window enforcement
   - Quorum requirements

## Usage Requirements

### For Contributors
- Must have STX to contribute
- Cannot withdraw direct contributions

### For Proposal Creators
- Must provide required stake
- Must specify valid beneficiary
- Must provide valid proposal details

### For Voters
- Can only vote once per proposal
- Must vote within voting window
- Vote cannot be changed once cast

## Best Practices

1. Proposal Creation
   - Provide clear, detailed descriptions
   - Request reasonable amounts
   - Specify appropriate beneficiary

2. Voting
   - Review proposal details carefully
   - Vote within the voting window
   - Verify transaction success

3. Administration
   - Regular monitoring of proposals
   - Careful controller reassignment
   - Emergency function use only when necessary

## Note
This smart contract is designed for use on the Stacks blockchain and handles STX tokens. All amounts are in microSTX units. Exercise caution when interacting with the contract, especially when creating proposals or executing administrative functions.