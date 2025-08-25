# LootDAO - Community Gaming Treasury

A decentralized autonomous organization (DAO) built on Stacks blockchain for funding gaming initiatives including tournaments, game modifications, and fan art creation.

## Core Features

**Membership System**
- Minimum stake: 1000 STX to join
- Voting power based on stake with diminishing returns
- Reputation system for active participation
- Ability to increase stake or withdraw (leave DAO)

**Governance & Voting**
- Create proposals for funding requests
- 24-hour voting period (144 blocks)
- 20% quorum requirement + simple majority to pass
- Automatic execution of passed proposals

**Gaming Initiatives**
- **Tournaments**: Organize and fund competitive gaming events
- **Game Mods**: Reward developers for creating modifications
- **Fan Art**: Support community creative content
- **Direct Funding**: General purpose proposal system

## Key Functions

### Member Functions
```clarity
(join-dao stake-amount)           ;; Join with minimum 1000 STX
(increase-stake additional-amount) ;; Add more stake
(withdraw-stake)                  ;; Leave DAO and withdraw
(vote proposal-id support)        ;; Vote on proposals
```

### Proposal Functions
```clarity
(create-proposal title desc amount recipient type)  ;; Create funding request
(execute-proposal proposal-id)                      ;; Execute passed proposal
```

### Gaming Features
```clarity
(create-tournament name prize-pool duration)        ;; Organize tournament
(submit-reward-request category amount desc)        ;; Request rewards
```

## Smart Contract Architecture

**Data Storage**
- Members: stake, voting power, reputation, join date
- Proposals: details, voting results, execution status
- Tournaments: prize pools, participants, status
- Rewards: creator requests for mods/art

**Security Features**
- Owner-only emergency functions
- Stake requirement prevents spam
- Quorum prevents minority rule
- Reputation system encourages participation

## Deployment

1. Deploy contract to Stacks testnet/mainnet
2. Set minimum stake (default: 1000 STX)
3. Community members join by staking tokens
4. Start creating and voting on proposals

**Treasury Management**: All staked tokens form the treasury pool for funding approved initiatives.

**Voting Power**: Calculated with diminishing returns to prevent whale dominance while rewarding larger stakes.