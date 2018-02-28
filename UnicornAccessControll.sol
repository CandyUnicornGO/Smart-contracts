pragma solidity ^0.4.0;

contract CandyCoinInterface {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}
contract BlackBoxInterface {
    function isBlackBox() public returns (bool);
    function createGen0(uint unicornId, uint typeId) public payable;
    function genCore(uint childUnicornId, uint unicorn1Id, uint unicorn2Id) public payable;
}

contract UnicornBreedingInterface {
    function setFreezing(uint _unicornId, uint _time) public;
    function setTourFreezing(uint _unicornId, uint _time) public;
    function setGen(uint _unicornId, bytes _gen) public;
}
contract UnicornManagementInterface {
    function ownerAddress() public returns (address);
    function managerAddress() public returns (address);
    function communityAddress() public returns (address);
    function dividendManagerAddress() public returns (address);
    function blackBoxAddress() public returns (address);
    function breedingAddress() public returns (address);
    function candyToken() public returns (address);

    function createDividendPercent() public returns (uint); //OnlyManager 4 digits. 10.5% = 1050
    function sellDividendPercent() public returns (uint); //OnlyManager 4 digits. 10.5% = 1050
    function subFreezingPrice() public returns (uint); // 0.01 ETH
    function subFreezingTime() public returns (uint);
    function createUnicornPrice() public returns (uint);
    function createUnicornPriceInCandy() public returns (uint); //1 token
    function oraclizeFee() public returns (uint); //0.003 ETH
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
    function getCandyToken() external view returns (CandyCoinInterface);
    function getBreeding() external view returns (UnicornBreedingInterface);
    function getBlackBox() external view returns (BlackBoxInterface);
    function setOraclizeFee(uint _fee) external;
    function setSubFreezingPrice(uint _price) external;
    function setSubFreezingTime(uint _time) external;
    function setCreateUnicornPrice(uint _price, uint _candyPrice) external;
    function getCreateUnicornPrice() external view returns (uint);
    function getHybridizationPrice(uint _price) external view returns (uint);

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

