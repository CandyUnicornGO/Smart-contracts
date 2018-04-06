pragma solidity 0.4.21;

interface DividendManagerInterface {
    function payDividend() external payable;
}

interface UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    //    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    //    function walletAddress() external view returns (address);
    // function blackBoxAddress() external view returns (address);
    function unicornBreedingAddress() external view returns (address);
    // function geneLabAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    //    function candyToken() external view returns (address);
    //    function candyPowerToken() external view returns (address);

    function oraclizeFee() external view returns (uint);

    function paused() external view returns (bool);
    //service
    function registerInit(address _contract) external;
}

interface UnicornFamilyTree {
    function setAncestors(uint unicornId, uint parent1Id, uint parent2Id) external;
}


interface UnicornTokenInterface {
    //
    //    //ERC721
    //    function balanceOf(address _owner) external view returns (uint256 _balance);
    //    function ownerOf(uint256 _unicornId) external view returns (address _owner);
    //    function transfer(address _to, uint256 _unicornId) external;
    //    function approve(address _to, uint256 _unicornId) external;
    //    function takeOwnership(uint256 _unicornId) external;
    //    function totalSupply() external constant returns (uint);
    //    function owns(address _claimant, uint256 _unicornId) external view returns (bool);
    //    function allowance(address _claimant, uint256 _unicornId) external view returns (bool);
    //    function transferFrom(address _from, address _to, uint256 _unicornId) external;

    //specific
    // function getGen(uint _unicornId) external view returns (bytes);
    function setGene(uint _unicornId, bytes _gene) external;
    function updateGene(uint _unicornId, bytes _gene) external;
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

    // modifier onlyGeneLab() {
    //     require(msg.sender == unicornManagement.geneLabAddress());
    //     _;
    // }


    //    modifier onlyUnicornToken() {
    //        require(msg.sender == unicornManagement.unicornTokenAddress());
    //        _;
    //    }

}




contract BlackBoxController is UnicornAccessControl  {
    UnicornTokenInterface public unicornToken;
    address public ownOracle;
    UnicornFamilyTree public familyTree;

    event Gene0Request(uint indexed unicornId);
    event GeneHybritizationRequest(uint indexed unicornId, uint firstAncestorUnicornId, uint secondAncestorUnicornId);

    event FundsTransferred(address dividendManager, uint value);



    function BlackBoxController(address _unicornManagementAddress, address _familyTreeAddress) UnicornAccessControl(_unicornManagementAddress) public {
        familyTree = UnicornFamilyTree(_familyTreeAddress);
    }

    function init() onlyManagement whenPaused external {
        unicornToken = UnicornTokenInterface(unicornManagement.unicornTokenAddress());
    }

    function() public payable {
        //
    }

    function oracleCallback(uint unicornId, string gene) external {
        require(msg.sender == ownOracle);
        unicornToken.setGene(unicornId, bytes(gene));
    }

    function oracleRequest() internal {
        require(address(this).balance >= unicornManagement.oraclizeFee());
        ownOracle.transfer(unicornManagement.oraclizeFee());
    }

    function geneCore(uint _childUnicornId, uint _parent1UnicornId, uint _parent2UnicornId) onlyBreeding public payable {
        oracleRequest();
        familyTree.setAncestors(_childUnicornId, _parent1UnicornId, _parent2UnicornId);
        emit GeneHybritizationRequest(_childUnicornId, _parent1UnicornId, _parent2UnicornId);
    }

    function createGen0(uint _unicornId) onlyBreeding public payable {
        oracleRequest();
        familyTree.setAncestors(_unicornId, 0, 0);
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
