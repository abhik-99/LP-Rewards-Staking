// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LPStakeRewards is ERC1155URIStorage, Ownable, ReentrancyGuard {
    uint8 constant BADGE_LEVELS = 3;
    IERC20 lpTokenContract;

    struct User {
        uint256 amount;
        uint256 time;
        uint8 level;
    }

    mapping(address => User) private stakingRegistry;

    // Assumed ERC20 contract is pre-deployed. So this contract needs to have a Rewards pool to generate Staking Rewards
    uint256 currentRewardPool;

    event Staked(address indexed _user, uint256 _amount);
    event UserBadgeIssued(address indexed _user, uint8 indexed _level);

    constructor(address _lpTokenAddress) ERC1155("Test Badge") {
        lpTokenContract = IERC20(_lpTokenAddress);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function fundContract(uint256 _amount) external onlyOwner {
        // Approve needs to be taken care of beforehand
        lpTokenContract.transferFrom(_msgSender(), address(this), _amount);
    }

    function stake(uint256 _amount) external nonReentrant {
        require(currentRewardPool > 0, "Reward Pool Empty");
        address user = _msgSender();
        require(stakingRegistry[user].level == 0, "You are not allowed to stake");

        // For First Time Stakers
        if (stakingRegistry[user].amount == 0) {
            _mint(user, 0, 1, "");
            emit UserBadgeIssued(user, 1);
        }

        // Prior Approval needed from User's End
        lpTokenContract.transferFrom(user, address(this), _amount);
        if (stakingRegistry[user].amount != 0) {
            stakingRegistry[user].time = block.timestamp;
        }
        stakingRegistry[user].amount += _amount;

        emit Staked(user, _amount);
    }

    // Returns if the user is eligible for an upgrade and if so then to which level
    function _upgradeEligible(
        address _user
    ) internal view returns (bool, uint8) {
        /*
        Rules:
        User Staked less than 10e18 Lp Tokens -> Upgrades in 30 days from L1 to L2 and in further 18 days from L2 to L3
        User Staked more than 10e18 but less than 50e18 Lp Tokens -> Upgrades in 20 days from L1 to L2 and in further 12 days from L2 to L3
        User Staked more than 50e18 LpTokens -> Upgrades in 12 days from L1 to L2 and in further 7 days from L2 to L3
        */

        User memory user = stakingRegistry[_user];

        // User has already reached Level 3 or has already unstaked
        if (balanceOf(_user, 2) == 1 || user.amount == 0) return (false, 0);

        // User has reached Level 2 and might reach Level 3
        if (balanceOf(_user, 1) == 1) {
            if (
                user.amount <= 10e18 &&
                (block.timestamp - user.time) > 48 * 24 * 60 * 60
            ) return (true, 2);
            if (
                user.amount > 10e18 &&
                user.amount <= 50e18 &&
                (block.timestamp - user.time) > 32 * 24 * 60 * 60
            ) return (true, 2);
            if (
                user.amount > 50e18 &&
                (block.timestamp - user.time) > 19 * 24 * 60 * 60
            ) return (true, 2);
        }

        // User is currently at Level 1 and might reach Level 2
        if (balanceOf(_user, 0) == 1) {
            if (
                user.amount <= 10e18 &&
                (block.timestamp - user.time) > 30 * 24 * 60 * 60
            ) return (true, 1);
            if (
                user.amount > 10e18 &&
                user.amount <= 50e18 &&
                (block.timestamp - user.time) > 20 * 24 * 60 * 60
            ) return (true, 1);
            if (
                user.amount > 50e18 &&
                (block.timestamp - user.time) > 12 * 24 * 60 * 60
            ) return (true, 1);
        }

        return (false, 0);
    }

    // Upgrades User Badge Level
    function _upgrade(address _user, uint8 nextLevel) internal {
        _burn(_user, nextLevel - 1, 1);
        _mint(_user, nextLevel, 1, "");
        emit UserBadgeIssued(_user, nextLevel + 1);
    }

    function upgradeBadge() external nonReentrant {
        address user = _msgSender();
        (bool _upgradeable, uint8 nextLevel) = _upgradeEligible(user);
        require(_upgradeable == true, "You are not eligible for an upgrade");
        _upgrade(user, nextLevel);
        stakingRegistry[user].level += 1;
    }

    function unstake() external payable nonReentrant {
        require(currentRewardPool > 0, "Reward Pool Empty");
        address userAddress = _msgSender();
        User memory user = stakingRegistry[userAddress];

        // User has atleast staked for 11 days
        if (user.level == 0 && user.time > 11 * 24 * 60 * 60) {
            if (user.amount < 10e18) {
                // 0.01% reward if less than 10 tokens staked
                lpTokenContract.transferFrom(
                    address(this),
                    userAddress,
                    user.amount + (user.amount / 10000)
                );
                user.amount = 0;
            } else {
                // 1.5% reward if less than 10 tokens staked
                lpTokenContract.transferFrom(
                    address(this),
                    userAddress,
                    user.amount + ((user.amount * 15) / 1000)
                );
                user.amount = 0;
            }
        } else if (user.level == 1) {
            if (user.amount < 10e18) {
                // 2% reward if less than 10 tokens staked
                lpTokenContract.transferFrom(
                    address(this),
                    userAddress,
                    user.amount + ((user.amount * 2) / 100)
                );
                user.amount = 0;
            } else {
                // 3% reward if less than 10 tokens staked
                lpTokenContract.transferFrom(
                    address(this),
                    userAddress,
                    user.amount + ((user.amount * 3) / 100)
                );
                user.amount = 0;
            }
        } else if (user.level == 2) {
            if (user.amount < 10e18) {
                // 3.5% reward if less than 10 tokens staked
                lpTokenContract.transferFrom(
                    address(this),
                    userAddress,
                    user.amount + ((user.amount * 35) / 1000)
                );
                user.amount = 0;
            } else {
                // 5% reward if less than 10 tokens staked
                lpTokenContract.transferFrom(
                    address(this),
                    userAddress,
                    user.amount + ((user.amount * 5) / 100)
                );
                user.amount = 0;
            }
        } else {
            // -50% as penalty if less than 10 tokens staked
            lpTokenContract.transferFrom(
                address(this),
                userAddress,
                user.amount - ((user.amount * 50) / 100)
            );
            user.amount = 0;
        }

        stakingRegistry[userAddress] = user;
    }

    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal override {
        super._beforeTokenTransfer(
            _operator,
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
        require(_from == address(0) || _to == address(0), "Not Allowed");
    }
}
