// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Forex_Training is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Node {
        uint256 NumberOfChildNodeOnLeft;
        uint256 NumberOfChildNodeOnRight;
        uint256 numberOfChildNodeOnLeftForOneDay;
        uint256 numberOfChildNodeOnRightForOneDay;
        uint256 NumberOfBalancedCalculated;
        uint256 TotalUserRewarded;
        uint256 NumberOfNewBalanced;
        uint256 RewardAmountNotReleased;
        address LeftNode;
        address RightNode;
        address UplineAddress;
        int8 DirectionOfCurrentNodeInUplineNode;
        bool Status;
    }

    IERC20 private tetherToken;

    mapping(address => Node) private _users;
    mapping(address => bool) private _oldUsers;
    address[] private _usersAddresses;

    address private owner;
    uint256 private newUsersInADay;
    uint256 private ownerBalanced;
    uint256 private lastRun;
    uint256 private registrationFee;
    uint256 private numberOfRegisteredUsersIn_24Hours;
    uint256 private totalBalance;
    uint256 private numberOfNewBalanceIn_24Hours;
    uint256 private constMaxBalanceForCalculatedReward;

    event UserReactivated(address indexed user);
    event UserRegistered(address indexed upLine, address indexed newUser);
    event UserWithdraw(address indexed user, uint256 indexed rewardAmount);
    event UploadOldUser(address indexed uplineAddress, address indexed oldUserAddress);

    constructor(address _tetherToken, address _owner) {
        owner = _owner;
        registrationFee = 100 ether;

        tetherToken = IERC20(_tetherToken);
        lastRun = block.timestamp;
        numberOfRegisteredUsersIn_24Hours = 0;
        numberOfNewBalanceIn_24Hours = 0;
        constMaxBalanceForCalculatedReward = 10;

        _users[owner] = Node({
            NumberOfChildNodeOnLeft: 0,
            NumberOfChildNodeOnRight: 0,
            numberOfChildNodeOnLeftForOneDay: 0,
            numberOfChildNodeOnRightForOneDay: 0,
            NumberOfBalancedCalculated: 0,
            TotalUserRewarded: 0,
            NumberOfNewBalanced: 0,
            RewardAmountNotReleased: 0,
            LeftNode: address(0),
            RightNode: address(0),
            UplineAddress: address(0),
            DirectionOfCurrentNodeInUplineNode: 1,
            Status: true
        });

        _usersAddresses.push(owner);
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "Just Owner Can Run This Order!");
        _;
    }

    function Calculating_Rewards_In_24_Hours() public {
        require(block.timestamp > lastRun + 2 minutes, "The Calculating_Node_Rewards_In_24_Hours Time Has Not Come");

        uint256 currentUserLeftNode;
        uint256 currentUserRightNode;

        uint256 remainingUserLeftChildYesterday;
        uint256 remainingUserRightChildYesterday;

        uint256 totalNormalUserBalanced = 0;
        uint256 totalExcessBalances = 0;
        uint256 maxBalancedCap = 10;
        ownerBalanced = min(newUsersInADay, maxBalancedCap);

        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            address currentUser = _usersAddresses[i];
            uint256 leftCount = _users[currentUser].numberOfChildNodeOnLeftForOneDay;
            uint256 rightCount = _users[currentUser].numberOfChildNodeOnRightForOneDay;
            // currentUserLeftNode = _users[currentUser].numberOfChildNodeOnLeftForOneDay;
            // currentUserRightNode = _users[currentUser].numberOfChildNodeOnLeftForOneDay;
            uint256 balancedCount = min(leftCount, rightCount);
            // uint256 balancedCount = min(currentUserLeftNode, currentUserRightNode);

            if (currentUser != owner) {
                if (balancedCount > maxBalancedCap) {
                    totalExcessBalances += (balancedCount - maxBalancedCap);
                    balancedCount = maxBalancedCap;
                }
                totalNormalUserBalanced += balancedCount;
            }
        }

        uint256 rewardPerBalanced = Today_Reward_Per_Balance();

        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            address currentUser = _usersAddresses[i];
            uint256 userReward;
            uint256 currentUserBalanced;

            if (currentUser == owner) {
                userReward = ownerBalanced * rewardPerBalanced;
            } else {
                currentUserBalanced = min(
                    currentUserLeftNode + remainingUserLeftChildYesterday,
                    currentUserRightNode + remainingUserRightChildYesterday
                );
                userReward = currentUserBalanced * rewardPerBalanced;
            }

            if (totalExcessBalances > 0 && currentUserBalanced < maxBalancedCap) {
                userReward += (totalExcessBalances * rewardPerBalanced) / totalNormalUserBalanced;
            }

            _users[currentUser].RewardAmountNotReleased += userReward;
        }

        newUsersInADay = 0;
        lastRun = block.timestamp;
        numberOfRegisteredUsersIn_24Hours = 0;
        numberOfNewBalanceIn_24Hours = 0;

        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            address currentUser = _usersAddresses[i];
            // currentUserLeftNode = _users[currentUser].numberOfChildNodeOnLeftForOneDay;
            // currentUserRightNode = _users[currentUser].numberOfChildNodeOnRightForOneDay;

            uint256 leftNodes = _users[currentUser].numberOfChildNodeOnLeftForOneDay;
            uint256 RightNodes = _users[currentUser].numberOfChildNodeOnRightForOneDay;

            if (currentUserLeftNode == currentUserRightNode) {
                // currentUserLeftNode = 0;
                // currentUserRightNode = 0;
                leftNodes = 0;
                RightNodes = 0;
            } else {
                remainingUserLeftChildYesterday =
                    currentUserLeftNode > currentUserRightNode ? currentUserLeftNode - currentUserRightNode : 0;
                remainingUserRightChildYesterday =
                    currentUserRightNode > currentUserLeftNode ? currentUserRightNode - currentUserLeftNode : 0;
                leftNodes = 0;
                RightNodes = 0;
            }
        }
    }

    function reactivateUser() public {
        require(_users[_msgSender()].Status == false, "User is already active or not registered.");
        require(_users[_msgSender()].TotalUserRewarded >= 1000 ether, "Reactivate condition not met.");

        uint256 ownerBenefit = 20 ether;
        uint256 registerFee = registrationFee - ownerBenefit;

        tetherToken.safeTransferFrom(_msgSender(), address(this), registerFee);
        tetherToken.safeTransferFrom(_msgSender(), owner, ownerBenefit);

        _users[_msgSender()].TotalUserRewarded = 0;
        _users[_msgSender()].Status = true;

        emit UserReactivated(_msgSender());
    }

    function B_Withdraw() public nonReentrant {
        require(_users[_msgSender()].RewardAmountNotReleased > 0, "You have not received any award yet");
        require(_users[_msgSender()].Status == true, "You can not withdraw your reward");

        if (_msgSender() == owner) {
            uint256 ownerReward = _users[owner].RewardAmountNotReleased;
            _users[owner].RewardAmountNotReleased = 0;
            tetherToken.safeTransfer(owner, ownerReward);
            return;
        }

        uint256 reward;
        reward = _users[_msgSender()].RewardAmountNotReleased;
        _users[_msgSender()].TotalUserRewarded += reward;
        _users[_msgSender()].RewardAmountNotReleased = 0;

        if (_users[_msgSender()].TotalUserRewarded >= 1000 ether) {
            _users[_msgSender()].Status = false;
        }

        tetherToken.safeTransfer(_msgSender(), reward);

        emit UserWithdraw(_msgSender(), reward);
    }

    function Emergency_72() public onlyOwner {
        require(block.timestamp > lastRun + 3 days, "The Emergency_72 Time Has Not Come");
        require(tetherToken.balanceOf(address(this)) > 0, "contract not have balance");

        tetherToken.safeTransfer(owner, tetherToken.balanceOf(address(this)));
    }

    function A_Register(address uplineAddress) public {
        uint256 ownerBenefit = 20 ether;
        uint256 registerFee = registrationFee - ownerBenefit;

        uint256 NumberOfCurrentBalanced;
        uint256 NumberOfNewBalanced;

        address temp_UplineAddress;
        address temp_CurrentAddress;
        int8 temp_DirectionOfCurrentNodeInUplineNode;

        require(
            _users[uplineAddress].LeftNode == address(0) || _users[uplineAddress].RightNode == address(0),
            "This address have two directs and could not accept new members!"
        );
        require(_msgSender() != uplineAddress, "You can not enter your own address!");

        require(_users[_msgSender()].Status == false, "This address is already registered!");
        require(_users[uplineAddress].Status == true, "This Upline address is Not Exist!");

        if (_oldUsers[_msgSender()] == false) {
            tetherToken.safeTransferFrom(_msgSender(), address(this), registerFee);
            tetherToken.safeTransferFrom(_msgSender(), owner, ownerBenefit);
        }

        if (uplineAddress == owner) {
            require(_users[owner].LeftNode == address(0), "Owner can only have one direct subset.");
            _users[owner].LeftNode = _msgSender();
            temp_DirectionOfCurrentNodeInUplineNode = 0;
        } else {
            if (_users[uplineAddress].LeftNode == address(0)) {
                _users[uplineAddress].LeftNode = _msgSender();
                temp_DirectionOfCurrentNodeInUplineNode = -1;
            } else {
                _users[uplineAddress].RightNode = _msgSender();
                temp_DirectionOfCurrentNodeInUplineNode = 1;
            }
        }

        _users[_msgSender()] = Node({
            NumberOfChildNodeOnLeft: 0,
            NumberOfChildNodeOnRight: 0,
            numberOfChildNodeOnLeftForOneDay: 0,
            numberOfChildNodeOnRightForOneDay: 0,
            NumberOfBalancedCalculated: 0,
            TotalUserRewarded: 0,
            NumberOfNewBalanced: 0,
            RewardAmountNotReleased: 0,
            LeftNode: address(0),
            RightNode: address(0),
            UplineAddress: uplineAddress,
            DirectionOfCurrentNodeInUplineNode: temp_DirectionOfCurrentNodeInUplineNode,
            Status: true
        });

        temp_UplineAddress = uplineAddress;
        temp_CurrentAddress = _msgSender();

        if (!_oldUsers[temp_CurrentAddress]) {
            while (true) {
                if (_users[temp_UplineAddress].Status == false) {
                    break;
                }

                if (temp_DirectionOfCurrentNodeInUplineNode == 1) {
                    _users[temp_UplineAddress].NumberOfChildNodeOnRight += 1;
                    _users[temp_UplineAddress].numberOfChildNodeOnRightForOneDay += 1;
                } else {
                    _users[temp_UplineAddress].NumberOfChildNodeOnLeft += 1;
                    _users[temp_UplineAddress].numberOfChildNodeOnLeftForOneDay += 1;
                }

                NumberOfCurrentBalanced = _users[temp_UplineAddress].NumberOfChildNodeOnLeft
                    < _users[temp_UplineAddress].NumberOfChildNodeOnRight
                    ? _users[temp_UplineAddress].NumberOfChildNodeOnLeft
                    : _users[temp_UplineAddress].NumberOfChildNodeOnRight;

                NumberOfNewBalanced = NumberOfCurrentBalanced
                    - (
                        _users[temp_UplineAddress].NumberOfBalancedCalculated
                            + _users[temp_UplineAddress].NumberOfNewBalanced
                    );

                if (NumberOfNewBalanced > 0) {
                    _users[temp_UplineAddress].NumberOfNewBalanced += NumberOfNewBalanced;
                    if (_users[temp_UplineAddress].NumberOfNewBalanced <= constMaxBalanceForCalculatedReward) {
                        totalBalance += NumberOfNewBalanced;
                        numberOfNewBalanceIn_24Hours += NumberOfNewBalanced;
                    }
                }

                temp_CurrentAddress = temp_UplineAddress;
                temp_DirectionOfCurrentNodeInUplineNode = _users[temp_CurrentAddress].DirectionOfCurrentNodeInUplineNode;
                temp_UplineAddress = _users[temp_UplineAddress].UplineAddress;
            }

            numberOfRegisteredUsersIn_24Hours += 1;
        }

        _usersAddresses.push(_msgSender());
        newUsersInADay++;
        emit UserRegistered(uplineAddress, _msgSender());
    }

    function Upload_Old_User(address oldUserAddress, address uplineAddress) public onlyOwner {
        require(_users[oldUserAddress].Status == false, "This address is already registered!");
        require(uplineAddress != address(0), "Upline address cannot be zero address");
        require(_users[uplineAddress].Status == true, "Upline address must be an active user");
        require(
            _users[uplineAddress].LeftNode == address(0) || _users[uplineAddress].RightNode == address(0),
            "Upline address cannot accept more members"
        );

        uint256 NumberOfCurrentBalanced;
        uint256 NumberOfNewBalanced;

        address temp_UplineAddress;
        address temp_CurrentAddress;

        int8 temp_DirectionOfCurrentNodeInUplineNode;

        if (uplineAddress == owner) {
            require(_users[owner].LeftNode == address(0), "Owner can only have one direct subset.");
            _users[owner].LeftNode = _msgSender();
            temp_DirectionOfCurrentNodeInUplineNode = 0;
        } else {
            if (_users[uplineAddress].LeftNode == address(0)) {
                _users[uplineAddress].LeftNode = oldUserAddress;
                temp_DirectionOfCurrentNodeInUplineNode = -1;
            } else {
                _users[uplineAddress].RightNode = oldUserAddress;
                temp_DirectionOfCurrentNodeInUplineNode = 1;
            }
        }

        _users[oldUserAddress] = Node({
            NumberOfChildNodeOnLeft: 0,
            NumberOfChildNodeOnRight: 0,
            numberOfChildNodeOnLeftForOneDay: 0,
            numberOfChildNodeOnRightForOneDay: 0,
            NumberOfBalancedCalculated: 0,
            TotalUserRewarded: 0,
            NumberOfNewBalanced: 0,
            RewardAmountNotReleased: 0,
            LeftNode: address(0),
            RightNode: address(0),
            UplineAddress: uplineAddress,
            DirectionOfCurrentNodeInUplineNode: temp_DirectionOfCurrentNodeInUplineNode,
            Status: true
        });

        temp_UplineAddress = uplineAddress;
        temp_CurrentAddress = oldUserAddress;

        if (!_oldUsers[temp_CurrentAddress]) {
            while (true) {
                if (_users[temp_UplineAddress].Status == false) {
                    break;
                }

                if (temp_DirectionOfCurrentNodeInUplineNode == 1) {
                    _users[temp_UplineAddress].NumberOfChildNodeOnRight += 1;
                    _users[temp_UplineAddress].numberOfChildNodeOnRightForOneDay += 1;
                } else {
                    _users[temp_UplineAddress].NumberOfChildNodeOnLeft += 1;
                    _users[temp_UplineAddress].numberOfChildNodeOnLeftForOneDay += 1;
                }

                NumberOfCurrentBalanced = _users[temp_UplineAddress].NumberOfChildNodeOnLeft
                    < _users[temp_UplineAddress].NumberOfChildNodeOnRight
                    ? _users[temp_UplineAddress].NumberOfChildNodeOnLeft
                    : _users[temp_UplineAddress].NumberOfChildNodeOnRight;

                NumberOfNewBalanced = NumberOfCurrentBalanced
                    - (
                        _users[temp_UplineAddress].NumberOfBalancedCalculated
                            + _users[temp_UplineAddress].NumberOfNewBalanced
                    );

                if (NumberOfNewBalanced > 0) {
                    _users[temp_UplineAddress].NumberOfNewBalanced += NumberOfNewBalanced;
                    if (_users[temp_UplineAddress].NumberOfNewBalanced <= constMaxBalanceForCalculatedReward) {
                        totalBalance += NumberOfNewBalanced;
                        numberOfNewBalanceIn_24Hours += NumberOfNewBalanced;
                    }
                }

                temp_CurrentAddress = temp_UplineAddress;
                temp_DirectionOfCurrentNodeInUplineNode = _users[temp_CurrentAddress].DirectionOfCurrentNodeInUplineNode;
                temp_UplineAddress = _users[temp_UplineAddress].UplineAddress;
            }

            numberOfRegisteredUsersIn_24Hours += 1;
        }

        _usersAddresses.push(oldUserAddress);
        newUsersInADay++;

        emit UploadOldUser(uplineAddress, oldUserAddress);
    }

    function Today_Contract_Balance() public view returns (uint256) {
        return IERC20(tetherToken).balanceOf(address(this));
    }

    function All_Time_User_Left_Right(address userAddress) public view returns (uint256, uint256) {
        return (_users[userAddress].NumberOfChildNodeOnLeft, _users[userAddress].NumberOfChildNodeOnRight);
    }

    function Today_Total_Balance() public view returns (uint256) {
        uint256 totalBalancesIncludingOwner = numberOfNewBalanceIn_24Hours + newUsersInADay;

        return totalBalancesIncludingOwner;
    }

    function Today_Reward_Per_Balance() public view returns (uint256) {
        uint256 todayReward;
        uint256 totalBalancesIncludingOwner = numberOfNewBalanceIn_24Hours + newUsersInADay;

        if (totalBalancesIncludingOwner == 0) {
            todayReward = 0;
        } else {
            todayReward = IERC20(tetherToken).balanceOf(address(this)) / totalBalancesIncludingOwner;
        }

        return todayReward;
    }

    function Reward_Amount_Not_Released(address userAddress) public view returns (uint256) {
        return _users[userAddress].RewardAmountNotReleased;
    }

    function Total_User_Reward(address userAddress) public view returns (uint256) {
        return _users[userAddress].TotalUserRewarded;
    }

    function Registration_Fee() public view returns (uint256) {
        return registrationFee;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
