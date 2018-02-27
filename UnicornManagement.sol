pragma solidity ^0.4.0;


contract UnicornManagement {
    event GamePaused();
    event GameResumed();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public ownerAddress;
    address public managerAddress;
    address public communityAddress;
    address public dividendManagerAddress; //onlyCommunity
    address public blackBoxAddress; //onlyOwner
    address public breedingAddress; //onlyOwner
    uint public dividendPercent; //OnlyManager 4 digits. 10.5% = 1050

    mapping(address => bool) tournaments;//address 1 exists

    bool public paused = true;

    //    UnicornManagementInterface unicornManagement = UnicornManagementInterface(_unicornManagementAddress);

    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == managerAddress);
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == communityAddress);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function UnicornManagement(address _owner) public {
        ownerAddress = _owner;
        managerAddress = _owner;
        communityAddress = _owner;
    }

    function setManagerAddress(address _newManager) external onlyOwner {
        require(_newManager != address(0));
        managerAddress = _newManager;
    }

    function setCommunity(address _newCommunityAddress) external onlyCommunity {
        require(_newCommunityAddress != address(0));
        communityAddress = _newCommunityAddress;
    }

    function setDividendManager(address _dividendManagerAddress) external onlyCommunity {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;
    }

    function setTournament(address _newTournamentAddress) external onlyCommunity {
        require(_newTournamentAddress != address(0));
        tournaments[_newTournamentAddress] = true;
    }

    function delTournament(address _tournamentAddress) external onlyCommunity {
        require(tournaments[_tournamentAddress]);
        tournaments[_tournamentAddress] = false;
    }

    function isTournament(address _tournamentAddress) external view returns (bool) {
        return tournaments[_tournamentAddress];
    }

    function setBlackBox(address _blackBoxAddress) external onlyOwner whenPaused {
        require(_blackBoxAddress != address(0));
        //TODO насколько необходима такая проверка?
        //TODO мы же не проверяем isBreeding при записи его адреса в ББ
        //TODO даже если криворукий овнер установит нерпавильный контракт - игра все равно на паузе и есть время исправить
        //        BlackBoxInterface candidateContract = BlackBoxInterface(_blackBoxAddress);
        //        require(candidateContract.isBlackBox());
        //        blackBoxContract = candidateContract;
        blackBoxAddress = _blackBoxAddress;
    }

    function setBreeding(address _breedingAddress) external onlyOwner {
        require(_breedingAddress != address(0));
        breedingAddress = _breedingAddress;
        //        breedingContract = UnicornBreeding(breedingAddress);
    }


    function transferOwnership(address _ownerAddress) external onlyOwner {
        require(_ownerAddress != address(0));
        OwnershipTransferred(ownerAddress, _ownerAddress);
        ownerAddress = _ownerAddress;
    }

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        GamePaused();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        GameResumed();
        return true;
    }
}


contract UnicornManagementInterface {
    function ownerAddress() public returns (address);

    function managerAddress() public returns (address);

    function communityAddress() public returns (address);

    function dividendManagerAddress() public returns (address);

    function blackBoxAddress() public returns (address);

    function breedingAddress() public returns (address);

    function transferOwnership(address newOwner) external;

    function setTournament(address _newTournamentAddress) external;

    function delTournament(address _tournamentAddress) external;

    function isTournament(address _tournamentAddress) external  view returns (bool);

    function setBlackBoxAddress(address _blackBoxAddress) external;

    function setBreedingAddress(address _breedingAddress) external;

    function pause() public returns (bool);

    function unpause() public returns (bool);

    function paused() public returns (bool);
}

contract UnicornAccessControl {

    UnicornManagementInterface public unicornManagement;

    function UnicornAccessControl(address _unicornManagementAddress) public {
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

