pragma solidity ^0.4.0;

contract UnicornManagementInterface {
    function ownerAddress() public returns (address);
    function managerAddress() public returns (address);
    function communityAddress() public returns (address);
    function dividendManagerAddress() public returns (address);
    function blackBoxAddress() public returns (address);
    function breedingAddress() public returns (address);
    function paused() public returns (bool);

    function transferOwnership(address _ownerAddress) external;
    function setTournament(address _tournamentAddress) external;
    function delTournament(address _tournamentAddress) external;
    function isTournament(address _tournamentAddress) external view returns (bool);
    function setBlackBoxAddress(address _blackBoxAddress) external;
    function setBreedingAddress(address _breedingAddress) external;
    function setDividendManager(address _dividendManagerAddress) external;
    function setCreateDividendPercent(uint _percent) public;
    function setSellDividendPercent(uint _percent) public;
    function pause() public;
    function unpause() public;
}

contract UnicornAccessControll {

    UnicornManagementInterface public unicornManagement;

    function UnicornAccessControll(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == unicornManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == unicornManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == unicornManagement.communityAddress());
        _;
    }

    modifier onlyOLevel() {
        require(msg.sender == unicornManagement.ownerAddress() || msg.sender == unicornManagement.managerAddress());
        _;
    }

    modifier onlyTournament() {
        require(unicornManagement.isTournament(msg.sender));
        _;
    }

    modifier whenNotPaused() {
        require(!unicornManagement.paused());
        _;
    }

    modifier whenPaused {
        require(unicornManagement.paused());
        _;
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == unicornManagement.breedingAddress());
        _;
    }

}

