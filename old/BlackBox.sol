pragma solidity 0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract DividendManagerInterface {
    function payDividend() external payable;
}

interface UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function blackBoxAddress() external view returns (address);
    function unicornBreedingAddress() external view returns (address);
    function geneLabAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);

    function createDividendPercent() external view returns (uint);
    function sellDividendPercent() external view returns (uint);
    function subFreezingPrice() external view returns (uint);
    function subFreezingTime() external view returns (uint64);
    function subTourFreezingPrice() external view returns (uint);
    function subTourFreezingTime() external view returns (uint64);
    function createUnicornPrice() external view returns (uint);
    function createUnicornPriceInCandy() external view returns (uint);
    function oraclizeFee() external view returns (uint);

    function paused() external view returns (bool);
    //    function locked() external view returns (bool);

    function isTournament(address _tournamentAddress) external view returns (bool);

    function getCreateUnicornFullPrice() external view returns (uint);
    function getHybridizationFullPrice(uint _price) external view returns (uint);
    function getSellUnicornFullPrice(uint _price) external view returns (uint);
    function getCreateUnicornFullPriceInCandy() external view returns (uint);


    //service
    function registerInit(address _contract) external;

}

contract UnicornAccessControl {

    UnicornManagementInterface public unicornManagement;


    function UnicornAccessControl(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
        unicornManagement.registerInit(this);
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

    //    modifier onlyOLevel() {
    //        require(msg.sender == unicornManagement.ownerAddress() || msg.sender == unicornManagement.managerAddress());
    //        _;
    //    }

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

    //    modifier whenUnlocked() {
    //        require(!unicornManagement.locked());
    //        _;
    //    }

    modifier onlyManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == unicornManagement.unicornBreedingAddress());
        _;
    }

    modifier onlyGeneLab() {
        require(msg.sender == unicornManagement.geneLabAddress());
        _;
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }

    modifier onlyUnicornToken() {
        require(msg.sender == unicornManagement.unicornTokenAddress());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return unicornManagement.paused();
    }
}




contract BlackBoxController is UnicornAccessControl  {
    UnicornTokenInterface public unicornToken;
    address public ownOracle;


    event Gene0Request(uint indexed unicornId);
    event GeneHybritizationRequest(uint indexed unicornId, uint firstAncestorUnicornId, uint secondAncestorUnicornId);

    event FundsTransferred(address dividendManager, uint value);



    function BlackBoxController(address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {
    }

    function init() onlyManagement whenPaused external {
        unicornToken = UnicornTokenInterface(unicornManagement.unicornTokenAddress());
    }

    function() public payable {
        //
    }

    function oracleCallback(uint unicornId, string gene) external {
        require(msg.sender == ownOracle);
        require(unicornToken.setGene(unicornId, bytes(gene)));
    }

    function oracleRequest() internal {
        require(address(this).balance >= unicornManagement.oraclizeFee());
        ownOracle.transfer(unicornManagement.oraclizeFee());
    }

    function geneCore(uint _childUnicornId, uint _parent1UnicornId, uint _parent2UnicornId) onlyBreeding public payable {
        oracleRequest();
        emit GeneHybritizationRequest(_childUnicornId, _parent1UnicornId, _parent2UnicornId);
    }

    function createGen0(uint _unicornId) onlyBreeding public payable {
        oracleRequest();
        emit Gene0Request(_unicornId);
    }

    function setOwnOracle(address _ownOracle) public onlyOwner {
        ownOracle = _ownOracle;
    }

    function transferEthersToDividendManager(uint _value) onlyManager public {
        require(address(this).balance >= _value);
        DividendManagerInterface dividendManager = DividendManagerInterface(unicornManagement.dividendManagerAddress());
        dividendManager.payDividend.value(_value)();
        emit FundsTransferred(unicornManagement.dividendManagerAddress(), _value);
    }

    function setGeneManual(uint unicornId, string gene) public onlyOwner{
        unicornToken.setGene(unicornId, bytes(gene));
    }
}

interface UnicornTokenInterface {

    //ERC721
    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _unicornId) external view returns (address _owner);
    function transfer(address _to, uint256 _unicornId) external;
    function approve(address _to, uint256 _unicornId) external;
    function takeOwnership(uint256 _unicornId) external;
    function totalSupply() external constant returns (uint);
    function owns(address _claimant, uint256 _unicornId) external view returns (bool);
    function allowance(address _claimant, uint256 _unicornId) external view returns (bool);
    function transferFrom(address _from, address _to, uint256 _unicornId) external;

    //specific
    function createUnicorn(address _owner) external returns (uint);
    //    function burnUnicorn(uint256 _unicornId) external;
    function getGen(uint _unicornId) external view returns (bytes);
    function setGene(uint _unicornId, bytes _gene) external;
    function updateGene(uint _unicornId, bytes _gene) external;
    function getUnicornGenByte(uint _unicornId, uint _byteNo) external view returns (uint8);

    function setName(uint256 _unicornId, string _name ) external returns (bool);
    function plusFreezingTime(uint _unicornId) external;
    function plusTourFreezingTime(uint _unicornId) external;
    function minusFreezingTime(uint _unicornId, uint64 _time) external;
    function minusTourFreezingTime(uint _unicornId, uint64 _time) external;
    function isUnfreezed(uint _unicornId) external view returns (bool);
    function isTourUnfreezed(uint _unicornId) external view returns (bool);

    function marketTransfer(address _from, address _to, uint256 _unicornId) external;
}
