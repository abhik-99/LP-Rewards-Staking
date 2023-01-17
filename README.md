# LP Token Staking Rewards

## Project Overview
The idea is that the user stakes LP token in the contract and in return get a Badge. Based on the time elapsed, the badge can be upgraded. Initially, the badge is at level 1. When a certain time has elapsed (based on the amount of token staked), the user can upgrade the badge.
At the end, the user can unstake and based on the badge level, the user gets rewards on the staked amount and keeps a cool NFT badge to remember the contract by.

## Design
The Staking rules are designed in such a manner that:
- Any token transfer approval is handled externally.
- While methods for transferring NFT tokens from Rewards Contract are present, they do not work. This proves that issued tokens are SBTs.
- The user gets incentivized to stay more than 12 days at level 1 otherwise risks losing the rewards to gas costs.
- The user can increase the staked amount in a dynamic fashion and can lower the time period taken by staking more.
- Staking more unlocks higher level badge in less time.
- User can stake at level 1 again and again but if the user has staked to level 2 or 3 and then unstaked, then the user cannot stake again.
- The user can generate a stable yeild of 1.5% because of the above reason.
- The badge minted to the user cannot be transferred to anyone else.
- Staking and Unstaking is not allowed if Staking contract is not furnished with Reward LP tokens.

## Flow

This section elaborates on the contract flow. It starts from the very beginning and then moves on to the `LPStakeRewards.sol` contract. There are 3 phases in the flow as described below.

### Phase 1 - Pre-deployment
The `TestErc20.sol` contract is to be deployed. This token serves as the LP Staking tokens in the project. Since the contract is deployed before the rewards contract is deployed, the builder / owner of the contract has to take the initiative to furnish the rewards contract with LP tokens which will be rewarded to the user. 

Based on Game Theory, any sensible Owner would fund the contract for users while the users are incentivised to behave.

### Phase 2 - Deployment & Staking
1. Owner deploys `LPStakeRewards.sol` and fund it with `TestErc20` LP Tokens by using the `fundContract()` method in Rewards Contract.
2. User stakes LP Tokens (TestErc20) in the contract and are issued a **Level 1** badge.
3. User keeps staking based on the below criteria to get upgrade to **Level 2** and then to **Level 3**:

| Amount Staked | Duration Required for L2 | Duration Required for L3 |
| ------------- | ------------------------ | ------------------------ |
| <= 10 LP Tokens | 30 Days | 18 days |
| > 10 and <= 50 LP Tokens | 20 Days | 12 Days |
| > 50 LP Tokens | 12 days | 7 days |

### Unstaking

At this stage, the user invokes the `unstake()` function and based on the following criteria, is either penalized or gets a reward:
1. If the user withdraws before 11 days, the user gets penalized 50% of the staked amount.
2. If the user has atleast staked for 11 days and is at level 1, then:
    i. If the user is at Level 1, then gets 0.001 % as reward if the user has staked less than 10 LP tokens.
    ii. If the user is at Level 1 and has staked more than 10 LP tokens, then gets 1.5% as reward
3. If the user is at Level 2, then:
    i. if Less than 10 LP tokens then gets 2%
    ii. Otherwise gets 3%
4. If the user is at Level 3, then:
    i. If the user has staked less than 10 LP tokens, then gets 3.5%.
    ii. Otherwise gets 5%.



