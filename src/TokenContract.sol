// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract WasteManagement {
    IERC20 public token;

    struct TotalImpact {
        uint256 wasteCollected;
        uint256 wasteSubmitted;
        uint256 wasteEarned;
    }

    struct Impact {
        uint256 wasteCollected;
        uint256 wasteSubmitted;
        uint256 wasteEarned;
    }

    struct User {
        address walletAddress;
        string name;
    }

    struct Waste {
        string image;
        address userAddress;
        string location;
        string typeOfWaste;
        string estimatedAmount;
        string status; // Example: "Submitted", "Collected", "Verified"
    }

    struct Notification {
        address walletAddress;
        string message;
    }

    struct Transaction {
        address walletAddress;
        string content;
        uint256 tokenAmount;
    }

    // Mappings
    mapping(address => Impact) public userImpacts;
    mapping(address => User) public users;
    mapping(uint256 => Waste) public wastes;
    mapping(address => Notification[]) public notifications;
    mapping(address => Transaction[]) public transactions;

    TotalImpact public totalImpact;
    uint256 public wasteCounter = 0;
    uint256 public rewardRatePerWaste = 10;

    // Events
    event WasteSubmitted(uint256 wasteId, address indexed userAddress);
    event WasteCollected(uint256 wasteId, address indexed collector);
    event WasteVerified(uint256 wasteId, address indexed verifier);
    event RewardCollected(address indexed userAddress, uint256 tokenAmount);
    event TokensSent(address indexed userAddress, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    // Add a user
    function addUser(string memory _name) public {
        users[msg.sender] = User(msg.sender, _name);
    }

    // Submit waste
    function submitWaste(
        string memory _image,
        string memory _location,
        string memory _typeOfWaste,
        string memory _estimatedAmount
    ) public {
        TotalImpact storage _totalImpact = totalImpact;

        _totalImpact.wasteSubmitted++;
        wasteCounter++;
        wastes[wasteCounter] = Waste(
            _image,
            msg.sender,
            _location,
            _typeOfWaste,
            _estimatedAmount,
            "Submitted"
        );
        userImpacts[msg.sender].wasteSubmitted++;

        emit WasteSubmitted(wasteCounter, msg.sender);
    }

    // Verify waste
    function verifyWaste(uint256 _wasteId) public {
        Waste storage waste = wastes[_wasteId];
        require(
            keccak256(abi.encodePacked(waste.status)) ==
                keccak256(abi.encodePacked("Submitted")),
            "Waste is not in submitted status"
        );

        waste.status = "Verified";
        userImpacts[waste.userAddress].wasteEarned++;
        emit WasteVerified(_wasteId, msg.sender);
    }

    // Collect waste
    function collectWaste(uint256 _wasteId) public {
        TotalImpact storage _totalImpact = totalImpact;

        _totalImpact.wasteCollected++;
        Waste storage waste = wastes[_wasteId];
        require(
            keccak256(abi.encodePacked(waste.status)) ==
                keccak256(abi.encodePacked("Verified")),
            "Waste is not verified yet"
        );

        waste.status = "Collected";
        userImpacts[msg.sender].wasteCollected++;
        emit WasteCollected(_wasteId, msg.sender);
    }

    // Collect reward and send tokens
    function collectRewardAndSendTokens() public {
        TotalImpact storage _totalImpact = totalImpact;

        Impact storage impact = userImpacts[msg.sender];
        require(impact.wasteEarned > 0, "No waste earnings available");

        // Calculate total tokens to send
        uint256 rewardAmount = impact.wasteEarned * rewardRatePerWaste;

        // Reset the waste earned to 0 after sending the reward
        impact.wasteEarned = 0;

        // Send tokens to the user
        require(
            token.transfer(msg.sender, rewardAmount),
            "Token transfer failed"
        );

        // Log the transaction
        transactions[msg.sender].push(
            Transaction({
                walletAddress: msg.sender,
                content: "Reward Collected and Tokens Sent",
                tokenAmount: rewardAmount
            })
        );

        _totalImpact.wasteEarned += rewardAmount;

        emit RewardCollected(msg.sender, rewardAmount);
        emit TokensSent(msg.sender, rewardAmount);
    }

    // Getter functions
    function getUser(address _userAddress) public view returns (User memory) {
        return users[_userAddress];
    }

    function getWaste(uint256 _wasteId) public view returns (Waste memory) {
        return wastes[_wasteId];
    }

    function getImpact(
        address _userAddress
    ) public view returns (Impact memory) {
        return userImpacts[_userAddress];
    }

    function getNotifications(
        address _userAddress
    ) public view returns (Notification[] memory) {
        return notifications[_userAddress];
    }

    function getTransactions(
        address _userAddress
    ) public view returns (Transaction[] memory) {
        return transactions[_userAddress];
    }

    function getTotalImpact() public view returns (TotalImpact memory) {
        return totalImpact;
    }
}
