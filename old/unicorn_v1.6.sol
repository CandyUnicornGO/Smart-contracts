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


contract UnicornInit {
    function init() external;
}

contract UnicornManagement {
    using SafeMath for uint;

    address public ownerAddress;
    address public managerAddress;
    address public communityAddress;
    address public walletAddress;
    address public candyToken;
    address public candyPowerToken;
    address public dividendManagerAddress; //onlyCommunity
    address public blackBoxAddress; //onlyOwner
    address public unicornBreedingAddress; //onlyOwner
    address public geneLabAddress; //onlyOwner
    address public unicornTokenAddress; //onlyOwner

    uint public createDividendPercent = 375; //OnlyManager 4 digits. 10.5% = 1050
    uint public sellDividendPercent = 375; //OnlyManager 4 digits. 10.5% = 1050
    uint public subFreezingPrice = 1000000000000000000; //
    uint64 public subFreezingTime = 1 hours;
    uint public subTourFreezingPrice = 1000000000000000000; //
    uint64 public subTourFreezingTime = 1 hours;
    uint public createUnicornPrice = 50000000000000000;
    uint public createUnicornPriceInCandy = 25000000000000000000; //25 tokens
    uint public oraclizeFee = 3000000000000000; //0.003 ETH

    bool public paused = true;
    bool public locked = false;

    mapping(address => bool) tournaments;//address

    event GamePaused();
    event GameResumed();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewManagerAddress(address managerAddress);
    event NewCommunityAddress(address communityAddress);
    event NewDividendManagerAddress(address dividendManagerAddress);
    event NewWalletAddress(address walletAddress);
    event NewCreateUnicornPrice(uint price, uint priceCandy);
    event NewOraclizeFee(uint fee);
    event NewSubFreezingPrice(uint price);
    event NewSubFreezingTime(uint time);
    event NewSubTourFreezingPrice(uint price);
    event NewSubTourFreezingTime(uint time);
    event NewCreateUnicornPrice(uint price);
    event NewCreateDividendPercent(uint percent);
    event NewSellDividendPercent(uint percent);
    event AddTournament(address tournamentAddress);
    event DelTournament(address tournamentAddress);
    event NewBlackBoxAddress(address blackBoxAddress);
    event NewBreedingAddress(address breedingAddress);


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

    modifier whenUnlocked() {
        require(!locked);
        _;
    }

    function lock() external onlyOwner whenPaused whenUnlocked {
        locked = true;
    }

    function UnicornManagement(address _candyToken) public {
        ownerAddress = msg.sender;
        managerAddress = msg.sender;
        communityAddress = msg.sender;
        walletAddress = msg.sender;
        candyToken = _candyToken;
        candyPowerToken = _candyToken;
    }


    struct InitItem {
        uint listIndex;
        bool exists;
    }

    mapping (address => InitItem) private initItems;
    address[] private initList;

    function registerInit(address _contract) external whenPaused {
        require(msg.sender == ownerAddress || tx.origin == ownerAddress);

        if (!initItems[_contract].exists) {
            initItems[_contract] = InitItem({
                listIndex: initList.length,
                exists: true
                });
            initList.push(_contract);
        }
    }

    function unregisterInit(address _contract) external onlyOwner whenPaused {
        require(initItems[_contract].exists && initList.length > 0);
        uint lastIdx = initList.length - 1;
        initItems[initList[lastIdx]].listIndex = initItems[_contract].listIndex;
        initList[initItems[_contract].listIndex] = initList[lastIdx];
        initList.length--;
        delete initItems[_contract];

    }

    function runInit() external onlyOwner whenPaused {
        for(uint i = 0; i < initList.length; i++) {
            UnicornInit(initList[i]).init();
        }
    }

    function setCandyPowerToken(address _candyPowerToken) external onlyOwner whenPaused {
        require(_candyPowerToken != address(0));
        candyPowerToken = _candyPowerToken;
    }

    function setUnicornToken(address _unicornTokenAddress) external onlyOwner whenPaused whenUnlocked {
        require(_unicornTokenAddress != address(0));
        //        require(unicornTokenAddress == address(0));
        unicornTokenAddress = _unicornTokenAddress;
    }

    function setBlackBox(address _blackBoxAddress) external onlyOwner whenPaused {
        require(_blackBoxAddress != address(0));
        blackBoxAddress = _blackBoxAddress;
    }

    function setGeneLab(address _geneLabAddress) external onlyOwner whenPaused {
        require(_geneLabAddress != address(0));
        geneLabAddress = _geneLabAddress;
    }

    function setUnicornBreeding(address _unicornBreedingAddress) external onlyOwner whenPaused whenUnlocked {
        require(_unicornBreedingAddress != address(0));
        //        require(unicornBreedingAddress == address(0));
        unicornBreedingAddress = _unicornBreedingAddress;
    }

    function setManagerAddress(address _managerAddress) external onlyOwner {
        require(_managerAddress != address(0));
        managerAddress = _managerAddress;
        emit NewManagerAddress(_managerAddress);
    }

    function setDividendManager(address _dividendManagerAddress) external onlyOwner {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;
        emit NewDividendManagerAddress(_dividendManagerAddress);
    }

    function setWallet(address _walletAddress) external onlyOwner {
        require(_walletAddress != address(0));
        walletAddress = _walletAddress;
        emit NewWalletAddress(_walletAddress);
    }

    function setTournament(address _tournamentAddress) external onlyOwner {
        require(_tournamentAddress != address(0));
        tournaments[_tournamentAddress] = true;
        emit AddTournament(_tournamentAddress);
    }

    function delTournament(address _tournamentAddress) external onlyOwner {
        require(tournaments[_tournamentAddress]);
        tournaments[_tournamentAddress] = false;
        emit DelTournament(_tournamentAddress);
    }

    function transferOwnership(address _ownerAddress) external onlyOwner {
        require(_ownerAddress != address(0));
        ownerAddress = _ownerAddress;
        emit OwnershipTransferred(ownerAddress, _ownerAddress);
    }


    function setCreateDividendPercent(uint _percent) public onlyManager {
        require(_percent < 2500);
        //no more then 25%
        createDividendPercent = _percent;
        emit NewCreateDividendPercent(_percent);
    }

    function setSellDividendPercent(uint _percent) public onlyManager {
        require(_percent < 2500);
        //no more then 25%
        sellDividendPercent = _percent;
        emit NewSellDividendPercent(_percent);
    }

    //time in minutes
    function setSubFreezingTime(uint64 _time) external onlyManager {
        subFreezingTime = _time * 1 minutes;
        emit NewSubFreezingTime(_time);
    }

    //price in CandyCoins
    function setSubFreezingPrice(uint _price) external onlyManager {
        subFreezingPrice = _price;
        emit NewSubFreezingPrice(_price);
    }


    //time in minutes
    function setSubTourFreezingTime(uint64 _time) external onlyManager {
        subTourFreezingTime = _time * 1 minutes;
        emit NewSubTourFreezingTime(_time);
    }

    //price in CandyCoins
    function setSubTourFreezingPrice(uint _price) external onlyManager {
        subTourFreezingPrice = _price;
        emit NewSubTourFreezingPrice(_price);
    }

    //in weis
    function setOraclizeFee(uint _fee) external onlyManager {
        oraclizeFee = _fee;
        emit NewOraclizeFee(_fee);
    }

    //price in weis
    function setCreateUnicornPrice(uint _price, uint _candyPrice) external onlyManager {
        createUnicornPrice = _price;
        createUnicornPriceInCandy = _candyPrice;
        emit NewCreateUnicornPrice(_price, _candyPrice);
    }

    function setCommunity(address _communityAddress) external onlyCommunity {
        require(_communityAddress != address(0));
        communityAddress = _communityAddress;
        emit NewCommunityAddress(_communityAddress);
    }


    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit GamePaused();
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit GameResumed();
    }



    function isTournament(address _tournamentAddress) external view returns (bool) {
        return tournaments[_tournamentAddress];
    }

    function getCreateUnicornFullPrice() external view returns (uint) {
        return createUnicornPrice.add(oraclizeFee);
    }

    function getCreateUnicornFullPriceInCandy() external view returns (uint) {
        return createUnicornPriceInCandy;
    }

    function getHybridizationFullPrice(uint _price) external view returns (uint) {
        return _price.add(valueFromPercent(_price, createDividendPercent));//.add(oraclizeFee);
    }

    function getSellUnicornFullPrice(uint _price) external view returns (uint) {
        return _price.add(valueFromPercent(_price, sellDividendPercent));//.add(oraclizeFee);
    }

    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }
}

contract DividendManagerInterface {
    function payDividend() external payable;
}

contract UnicornManagementInterface {

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


contract ERC20 {
    //    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}


contract megaCandyInterface is ERC20 {
    function transferFromSystem(address _from, address _to, uint256 _value) public returns (bool);
    function burn(address _from, uint256 _value) public returns (bool);
    function mint(address _to, uint256 _amount) public returns (bool);
}


contract UnicornBreedingInterface {
    function deleteOffer(uint _unicornId) external;
    function deleteHybridization(uint _unicornId) external;
}

contract BlackBoxInterface {
    function createGen0(uint _unicornId) public payable;
    function geneCore(uint _childUnicornId, uint _parent1UnicornId, uint _parent2UnicornId) public payable;
}


contract BlackBoxController is UnicornAccessControl  {
    UnicornTokenInterface public unicornToken;
    address public oracle = 0x5a8aAD505a44165813ECDFa213d0615293e33671;
    address public resurrector = 0x845B3e01052e76a0F201E51f4611d4d23a069AEe;

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
        require(msg.sender == oracle);
        unicornToken.setGene(unicornId, bytes(gene));
    }

    function oracleCallbackWithdraw(uint unicornId, string gene) external {
        uint gas = gasleft();
        require(msg.sender == oracle);
        oracle.transfer(gas * tx.gasprice);
        unicornToken.setGene(unicornId, bytes(gene));
    }

    function resurrectorCallbackWithdraw(uint unicornId, string gene) external {
        uint gas = gasleft();
        require(msg.sender == resurrector);
        resurrector.transfer(gas * tx.gasprice);
        unicornToken.setGene(unicornId, bytes(gene));
    }

    //    function oracleRequest() internal {
    //        require(address(this).balance >= unicornManagement.oraclizeFee());
    //        ownOracle.transfer(unicornManagement.oraclizeFee());
    //    }

    function geneCore(uint _childUnicornId, uint _parent1UnicornId, uint _parent2UnicornId) onlyBreeding public payable {
        //        oracleRequest();
        emit GeneHybritizationRequest(_childUnicornId, _parent1UnicornId, _parent2UnicornId);
    }

    function createGen0(uint _unicornId) onlyBreeding public payable {
        //        oracleRequest();
        emit Gene0Request(_unicornId);
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function setResurrector(address _resurrector) public onlyOwner {
        resurrector = _resurrector;
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

contract UnicornTokenInterface {

    //ERC721
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _unicornId) public view returns (address _owner);
    function transfer(address _to, uint256 _unicornId) public;
    function approve(address _to, uint256 _unicornId) public;
    function takeOwnership(uint256 _unicornId) public;
    function totalSupply() public constant returns (uint);
    function owns(address _claimant, uint256 _unicornId) public view returns (bool);
    function allowance(address _claimant, uint256 _unicornId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _unicornId) public;

    //    //specific
    //    struct Unicorn {
    //        bytes gene;
    //        uint64 birthTime;
    //        uint64 freezingEndTime;
    //        uint64 freezingTourEndTime;
    //        string name;
    //    }
    //    mapping(uint256 => Unicorn) public unicorns;
    //    function unicorns(uint _unicornId) external returns (bytes gene, uint64 birthTime, uint64 freezingEndTime, uint64 freezingTourEndTime, string name);
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

contract UnicornBase is UnicornAccessControl {
    using SafeMath for uint;
    UnicornBreedingInterface public unicornBreeding; //set on deploy

    event Transfer(address indexed from, address indexed to, uint256 unicornId);
    event Approval(address indexed owner, address indexed approved, uint256 unicornId);
    event UnicornGeneSet(uint indexed unicornId);
    event UnicornGeneUpdate(uint indexed unicornId);
    event UnicornFreezingTimeSet(uint indexed unicornId, uint time);
    event UnicornTourFreezingTimeSet(uint indexed unicornId, uint time);


    struct Unicorn {
        bytes gene;
        uint64 birthTime;
        uint64 freezingEndTime;
        uint64 freezingTourEndTime;
        string name;
    }

    uint8 maxFreezingIndex = 7;
    uint32[8] internal freezing = [
    uint32(1 hours),    //1 hour
    uint32(2 hours),    //2 - 4 hours
    uint32(8 hours),    //8 - 12 hours
    uint32(16 hours),   //16 - 24 hours
    uint32(36 hours),   //36 - 48 hours
    uint32(72 hours),   //72 - 96 hours
    uint32(120 hours),  //120 - 144 hours
    uint32(168 hours)   //168 hours
    ];

    //count for random plus from 0 to ..
    uint32[8] internal freezingPlusCount = [
    0, 3, 5, 9, 13, 25, 25, 0
    ];

    // Total amount of unicorns
    uint256 private totalUnicorns;

    // Incremental counter of unicorns Id
    uint256 private lastUnicornId;

    //Mapping from unicorn ID to Unicorn struct
    mapping(uint256 => Unicorn) public unicorns;

    // Mapping from unicorn ID to owner
    mapping(uint256 => address) private unicornOwner;

    // Mapping from unicorn ID to approved address
    mapping(uint256 => address) private unicornApprovals;

    // Mapping from owner to list of owned unicorn IDs
    mapping(address => uint256[]) private ownedUnicorns;

    // Mapping from unicorn ID to index of the owner unicorns list
    // т.е. ID уникорна => порядковый номер в списке владельца
    mapping(uint256 => uint256) private ownedUnicornsIndex;

    // Mapping from unicorn ID to approval for GeneLab
    mapping(uint256 => bool) private unicornApprovalsForGeneLab;

    modifier onlyOwnerOf(uint256 _unicornId) {
        require(owns(msg.sender, _unicornId));
        _;
    }

    /**
    * @dev Gets the owner of the specified unicorn ID
    * @param _unicornId uint256 ID of the unicorn to query the owner of
    * @return owner address currently marked as the owner of the given unicorn ID
    */
    function ownerOf(uint256 _unicornId) public view returns (address) {
        return unicornOwner[_unicornId];
    }

    function totalSupply() public view returns (uint256) {
        return totalUnicorns;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedUnicorns[_owner].length;
    }

    /**
    * @dev Gets the list of unicorns owned by a given address
    * @param _owner address to query the unicorns of
    * @return uint256[] representing the list of unicorns owned by the passed address
    */
    function unicornsOf(address _owner) public view returns (uint256[]) {
        return ownedUnicorns[_owner];
    }

    /**
    * @dev Gets the approved address to take ownership of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to query the approval of
    * @return address currently approved to take ownership of the given unicorn ID
    */
    function approvedFor(uint256 _unicornId) public view returns (address) {
        return unicornApprovals[_unicornId];
    }

    /**
    * @dev Tells whether the msg.sender is approved for the given unicorn ID or not
    * This function is not private so it can be extended in further implementations like the operatable ERC721
    * @param _owner address of the owner to query the approval of
    * @param _unicornId uint256 ID of the unicorn to query the approval of
    * @return bool whether the msg.sender is approved for the given unicorn ID or not
    */
    function allowance(address _owner, uint256 _unicornId) public view returns (bool) {
        return approvedFor(_unicornId) == _owner;
    }

    /**
    * @dev Approves another address to claim for the ownership of the given unicorn ID
    * @param _to address to be approved for the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be approved
    */
    function approve(address _to, uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        //модификатор onlyOwnerOf гарантирует, что owner = msg.sender
        //        address owner = ownerOf(_unicornId);
        require(_to != msg.sender);
        if (approvedFor(_unicornId) != address(0) || _to != address(0)) {
            unicornApprovals[_unicornId] = _to;
            emit Approval(msg.sender, _to, _unicornId);
        }
    }

    /**
    * @dev Claims the ownership of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn being claimed by the msg.sender
    */
    function takeOwnership(uint256 _unicornId) public {
        require(allowance(msg.sender, _unicornId));
        clearApprovalAndTransfer(ownerOf(_unicornId), msg.sender, _unicornId);
    }

    /**
    * @dev Transfers the ownership of a given unicorn ID to another address
    * @param _to address to receive the ownership of the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function transfer(address _to, uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        clearApprovalAndTransfer(msg.sender, _to, _unicornId);
    }


    /**
    * @dev Internal function to clear current approval and transfer the ownership of a given unicorn ID
    * @param _from address which you want to send unicorns from
    * @param _to address which you want to transfer the unicorn to
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function clearApprovalAndTransfer(address _from, address _to, uint256 _unicornId) internal {
        require(owns(_from, _unicornId));
        require(_to != address(0));
        require(_to != ownerOf(_unicornId));

        clearApproval(_from, _unicornId);
        removeUnicorn(_from, _unicornId);
        addUnicorn(_to, _unicornId);
        emit Transfer(_from, _to, _unicornId);
    }

    /**
    * @dev Internal function to clear current approval of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function clearApproval(address _owner, uint256 _unicornId) private {
        require(owns(_owner, _unicornId));
        unicornApprovals[_unicornId] = 0;
        emit Approval(_owner, 0, _unicornId);
    }

    /**
    * @dev Internal function to add a unicorn ID to the list of a given address
    * @param _to address representing the new owner of the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be added to the unicorns list of the given address
    */
    function addUnicorn(address _to, uint256 _unicornId) private {
        require(unicornOwner[_unicornId] == address(0));
        unicornOwner[_unicornId] = _to;

        uint256 length = ownedUnicorns[_to].length;
        ownedUnicorns[_to].push(_unicornId);
        ownedUnicornsIndex[_unicornId] = length;
        totalUnicorns = totalUnicorns.add(1);
    }

    /**
    * @dev Internal function to remove a unicorn ID from the list of a given address
    * @param _from address representing the previous owner of the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be removed from the unicorns list of the given address
    */
    function removeUnicorn(address _from, uint256 _unicornId) private {
        require(owns(_from, _unicornId));

        uint256 unicornIndex = ownedUnicornsIndex[_unicornId];
        //        uint256 lastUnicornIndex = balanceOf(_from).sub(1);
        uint256 lastUnicornIndex = ownedUnicorns[_from].length.sub(1);
        uint256 lastUnicorn = ownedUnicorns[_from][lastUnicornIndex];

        unicornOwner[_unicornId] = 0;
        ownedUnicorns[_from][unicornIndex] = lastUnicorn;
        ownedUnicorns[_from][lastUnicornIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both unicornIndex and lastUnicornIndex are going to
        // be zero. Then we can make sure that we will remove _unicornId from the ownedUnicorns list since we are first swapping
        // the lastUnicorn to the first position, and then dropping the element placed in the last position of the list

        ownedUnicorns[_from].length--;
        ownedUnicornsIndex[_unicornId] = 0;
        ownedUnicornsIndex[lastUnicorn] = unicornIndex;
        totalUnicorns = totalUnicorns.sub(1);


        unicornBreeding.deleteOffer(_unicornId);
        unicornBreeding.deleteHybridization(_unicornId);
    }


    function createUnicorn(address _owner) onlyBreeding external returns (uint) {
        require(_owner != address(0));
        uint256 _unicornId = lastUnicornId++;
        addUnicorn(_owner, _unicornId);
        //store new unicorn data
        unicorns[_unicornId] = Unicorn({
            gene : new bytes(0),
            birthTime : uint64(now),
            freezingEndTime : 0,
            freezingTourEndTime: 0,
            name: ''
            });
        emit Transfer(0x0, _owner, _unicornId);
        return _unicornId;
    }


    function owns(address _claimant, uint256 _unicornId) public view returns (bool) {
        return ownerOf(_unicornId) == _claimant && ownerOf(_unicornId) != address(0);
    }


    function transferFrom(address _from, address _to, uint256 _unicornId) public {
        require(_to != address(this));
        require(allowance(msg.sender, _unicornId));
        clearApprovalAndTransfer(_from, _to, _unicornId);
    }


    function fromHexChar(uint8 _c) internal pure returns (uint8) {
        return _c - (_c < 58 ? 48 : (_c < 97 ? 55 : 87));
    }


    function getUnicornGenByte(uint _unicornId, uint _byteNo) public view returns (uint8) {
        uint n = _byteNo << 1; // = _byteNo * 2
        //        require(unicorns[_unicornId].gene.length >= n + 1);
        if (unicorns[_unicornId].gene.length < n + 1) {
            return 0;
        }
        return fromHexChar(uint8(unicorns[_unicornId].gene[n])) << 4 | fromHexChar(uint8(unicorns[_unicornId].gene[n + 1]));
    }


    function setName(uint256 _unicornId, string _name ) public onlyOwnerOf(_unicornId) returns (bool) {
        bytes memory tmp = bytes(unicorns[_unicornId].name);
        require(tmp.length == 0);

        unicorns[_unicornId].name = _name;
        return true;
    }


    function getGen(uint _unicornId) external view returns (bytes){
        return unicorns[_unicornId].gene;
    }

    function setGene(uint _unicornId, bytes _gene) onlyBlackBox external  {
        if (unicorns[_unicornId].gene.length == 0) {
            unicorns[_unicornId].gene = _gene;
            emit UnicornGeneSet(_unicornId);
        }
    }

    function updateGene(uint _unicornId, bytes _gene) onlyGeneLab public {
        require(unicornApprovalsForGeneLab[_unicornId]);
        delete unicornApprovalsForGeneLab[_unicornId];
        unicorns[_unicornId].gene = _gene;
        emit UnicornGeneUpdate(_unicornId);
    }

    function approveForGeneLab(uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        unicornApprovalsForGeneLab[_unicornId] = true;
    }

    function clearApprovalForGeneLab(uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        delete unicornApprovalsForGeneLab[_unicornId];
    }

    //transfer by market
    function marketTransfer(address _from, address _to, uint256 _unicornId) onlyBreeding external {
        clearApprovalAndTransfer(_from, _to, _unicornId);
    }

    function plusFreezingTime(uint _unicornId) onlyBreeding external  {
        unicorns[_unicornId].freezingEndTime = uint64(_getFreezeTime(getUnicornGenByte(_unicornId, 163)) + now);
        emit UnicornFreezingTimeSet(_unicornId, unicorns[_unicornId].freezingEndTime);
    }

    function plusTourFreezingTime(uint _unicornId) onlyBreeding external {
        unicorns[_unicornId].freezingTourEndTime = uint64(_getFreezeTime(getUnicornGenByte(_unicornId, 168)) + now);
        emit UnicornTourFreezingTimeSet(_unicornId, unicorns[_unicornId].freezingTourEndTime);
    }

    function _getFreezeTime(uint8 freezingIndex) internal view returns (uint time) {
        freezingIndex %= maxFreezingIndex;
        time = freezing[freezingIndex];
        if (freezingPlusCount[freezingIndex] != 0) {
            time += (uint(block.blockhash(block.number - 1)) % freezingPlusCount[freezingIndex]) * 1 hours;
        }
    }


    //change freezing time for candy
    function minusFreezingTime(uint _unicornId, uint64 _time) onlyBreeding public {
        //не минусуем на уже размороженных конях
        require(unicorns[_unicornId].freezingEndTime > now);
        //не используем safeMath, т.к. subFreezingTime в теории не должен быть больше now %)
        unicorns[_unicornId].freezingEndTime -= _time;
    }

    //change tour freezing time for candy
    function minusTourFreezingTime(uint _unicornId, uint64 _time) onlyBreeding public {
        //не минусуем на уже размороженных конях
        require(unicorns[_unicornId].freezingTourEndTime > now);
        //не используем safeMath, т.к. subTourFreezingTime в теории не должен быть больше now %)
        unicorns[_unicornId].freezingTourEndTime -= _time;
    }

    function isUnfreezed(uint _unicornId) public view returns (bool) {
        return (unicorns[_unicornId].birthTime > 0 && unicorns[_unicornId].freezingEndTime <= uint64(now));
    }

    function isTourUnfreezed(uint _unicornId) public view returns (bool) {
        return (unicorns[_unicornId].birthTime > 0 && unicorns[_unicornId].freezingTourEndTime <= uint64(now));
    }

}


contract UnicornToken is UnicornBase {
    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";

    function UnicornToken(address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {

    }

    function init() onlyManagement whenPaused external {
        unicornBreeding = UnicornBreedingInterface(unicornManagement.unicornBreedingAddress());
    }

    function() public {

    }
}

contract BreedingDataBase is UnicornAccessControl {
    //counter for gen0
    uint public gen0Limit = 30000;
    uint public gen0Count = 839;
    //TODO ?? нужен?
    uint public gen0Step = 1000;

    //counter for presale gen0
    uint public gen0PresaleLimit = 1000;
    uint public gen0PresaleCount = 0;

    struct Hybridization{
        uint listIndex;
        uint price;
        bool exists;
    }

    // Mapping from unicorn ID to Hybridization struct
    mapping (uint => Hybridization) public hybridizations;
    mapping(uint => uint) public hybridizationList;
    uint public hybridizationListSize = 0;

    struct UnicornFreeze {
        uint index;
        //        uint indexTour;
        uint hybridizationsCount;
        uint statsSumHours;
        uint freezingEndTime;
        //        uint freezingTourEndTime;
        bool mustCalculate;
        bool exists;
    }

    mapping (uint => UnicornFreeze) public unicornsFreeze;


    struct Offer{
        uint marketIndex;
        uint priceEth;
        uint priceCandy;
        bool exists;
    }

    // Mapping from unicorn ID to Offer struct
    mapping (uint => Offer) public offers;
    // Mapping from unicorn ID to offer ID
    //    mapping (uint => uint) public unicornOffer;
    // market index => offerId
    mapping(uint => uint) public market;
    uint public marketSize = 0;


    function BreedingDataBase(address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {

    }

    function init() onlyManagement whenPaused view external {
        //unicornBreeding = UnicornBreedingInterface(unicornManagement.unicornBreedingAddress());
    }


    function incGen0Count() onlyBreeding external {
        gen0Count++;
    }

    function incGen0PresaleCount() onlyBreeding external {
        gen0PresaleCount++;
    }

    function incGen0Limit() onlyBreeding external {
        //TODO ?? добавил gen0Step, ок ?
        gen0Limit += gen0Step;
    }


    function createHybridization(uint _unicornId, uint _price) onlyBreeding external {
        hybridizations[_unicornId] = Hybridization({
            price: _price,
            exists: true,
            listIndex: hybridizationListSize
            });
        hybridizationList[hybridizationListSize++] = _unicornId;
    }


    function hybridizationExists(uint _unicornId) external view returns (bool) {
        return hybridizations[_unicornId].exists;
    }


    function hybridizationPrice(uint _unicornId) external view returns (uint) {
        return hybridizations[_unicornId].price;
    }


    function deleteHybridization(uint _unicornId) onlyBreeding external returns (bool){
        if (hybridizations[_unicornId].exists) {
            hybridizations[hybridizationList[--hybridizationListSize]].listIndex = hybridizations[_unicornId].listIndex;
            hybridizationList[hybridizations[_unicornId].listIndex] = hybridizationList[hybridizationListSize];
            delete hybridizationList[hybridizationListSize];
            delete hybridizations[_unicornId];
            return true;
        }
        return false;
    }


    function freezeIndex(uint _unicornId) external view returns (uint) {
        return unicornsFreeze[_unicornId].index;
    }

    function freezeHybridizationsCount(uint _unicornId) external view returns (uint) {
        return unicornsFreeze[_unicornId].hybridizationsCount;
    }

    function freezeStatsSumHours(uint _unicornId) external view returns (uint) {
        return unicornsFreeze[_unicornId].statsSumHours;
    }

    function freezeEndTime(uint _unicornId) external view returns (uint) {
        return unicornsFreeze[_unicornId].freezingEndTime;
    }

    function freezeMustCalculate(uint _unicornId) external view returns (bool) {
        return unicornsFreeze[_unicornId].mustCalculate;
    }

    function freezeExists(uint _unicornId) external view returns (bool) {
        return unicornsFreeze[_unicornId].exists;
    }


    function createFreeze(uint _unicornId, uint _index) onlyBreeding external {
        unicornsFreeze[_unicornId].exists = true;
        unicornsFreeze[_unicornId].mustCalculate = true;
        unicornsFreeze[_unicornId].index = _index;
        unicornsFreeze[_unicornId].hybridizationsCount = 0;
    }

    function incFreezeHybridizationsCount(uint _unicornId) onlyBreeding external {
        unicornsFreeze[_unicornId].hybridizationsCount++;
    }

    function setFreezeHybridizationsCount(uint _unicornId, uint _count) onlyBreeding external {
        unicornsFreeze[_unicornId].hybridizationsCount = _count;
    }

    function incFreezeIndex(uint _unicornId) onlyBreeding external {
        unicornsFreeze[_unicornId].index++;
    }

    function setFreezeEndTime(uint _unicornId, uint _time) onlyBreeding external {
        unicornsFreeze[_unicornId].freezingEndTime = _time;

    }

    function minusFreezeEndTime(uint _unicornId, uint _time) onlyBreeding external {
        unicornsFreeze[_unicornId].freezingEndTime -= _time;
    }

    function setFreezeMustCalculate(uint _unicornId, bool _mustCalculate) onlyBreeding external {
        unicornsFreeze[_unicornId].mustCalculate = _mustCalculate;
    }

    function setStatsSumHours(uint _unicornId, uint _statsSumHours) onlyBreeding external {
        unicornsFreeze[_unicornId].statsSumHours = _statsSumHours;
    }

    function offerExists(uint _unicornId) external view returns (bool) {
        return offers[_unicornId].exists;
    }

    function offerPriceEth(uint _unicornId) external view returns (uint) {
        return offers[_unicornId].priceEth;
    }

    function offerPriceCandy(uint _unicornId) external view returns (uint) {
        return offers[_unicornId].priceCandy;
    }

    function createOffer(uint _unicornId, uint _priceEth, uint _priceCandy) onlyBreeding external {
        offers[_unicornId] = Offer({
            priceEth: _priceEth,
            priceCandy: _priceCandy,
            exists: true,
            marketIndex: marketSize
            });

        market[marketSize++] = _unicornId;
    }

    function deleteOffer(uint _unicornId) onlyBreeding external {
        offers[market[--marketSize]].marketIndex = offers[_unicornId].marketIndex;
        market[offers[_unicornId].marketIndex] = market[marketSize];
        delete market[marketSize];
        delete offers[_unicornId];
    }
}


interface BreedingDataBaseInterface {

    function gen0Limit() external view returns (uint);
    function gen0Count() external view returns (uint);
    function gen0Step() external view returns (uint);

    function gen0PresaleLimit() external view returns (uint);
    function gen0PresaleCount() external view returns (uint);

    function incGen0Count() external;
    function incGen0PresaleCount() external;
    function incGen0Limit() external;

    function createHybridization(uint _unicornId, uint _price) external;
    function hybridizationExists(uint _unicornId) external view returns (bool);
    function hybridizationPrice(uint _unicornId) external view returns (uint);
    function deleteHybridization(uint _unicornId) external returns (bool);

    function freezeIndex(uint _unicornId) external view returns (uint);
    function freezeHybridizationsCount(uint _unicornId) external view returns (uint);
    function freezeStatsSumHours(uint _unicornId) external view returns (uint);
    function freezeEndTime(uint _unicornId) external view returns (uint);
    function freezeMustCalculate(uint _unicornId) external view returns (bool);
    function freezeExists(uint _unicornId) external view returns (bool);

    function createFreeze(uint _unicornId, uint _index) external;
    function incFreezeHybridizationsCount(uint _unicornId) external;
    function setFreezeHybridizationsCount(uint _unicornId, uint _count) external;

    function incFreezeIndex(uint _unicornId) external;
    function setFreezeEndTime(uint _unicornId, uint _time) external;
    function minusFreezeEndTime(uint _unicornId, uint _time) external;
    function setFreezeMustCalculate(uint _unicornId, bool _mustCalculate) external;
    function setStatsSumHours(uint _unicornId, uint _statsSumHours) external;


    function offerExists(uint _unicornId) external view returns (bool);
    function offerPriceEth(uint _unicornId) external view returns (uint);
    function offerPriceCandy(uint _unicornId) external view returns (uint);

    function createOffer(uint _unicornId, uint _priceEth, uint _priceCandy) external;
    function deleteOffer(uint _unicornId) external;

}


/*
* НЕ ЗАБЫТЬ ДОБАВИТЬ АДРЕС БРИДИНГА В ЛЭНД МАНАДЖМЕНТ!!!
*/
contract UnicornBreeding is UnicornAccessControl {
    using SafeMath for uint;
    //onlyOwner
    UnicornTokenInterface public unicornToken; //only on deploy
    BlackBoxInterface public blackBox;

    event HybridizationAdd(uint indexed unicornId, uint price);
    event HybridizationAccept(uint indexed firstUnicornId, uint indexed secondUnicornId, uint newUnicornId, uint price);
    event SelfHybridization(uint indexed firstUnicornId, uint indexed secondUnicornId, uint newUnicornId, uint price);
    event HybridizationDelete(uint indexed unicornId);
    event FundsTransferred(address dividendManager, uint value);
    event CreateUnicorn(address indexed owner, uint indexed unicornId, uint parent1, uint  parent2);
    event NewGen0Limit(uint limit);
    event NewGen0Step(uint step);


    event OfferAdd(uint256 indexed unicornId, uint priceEth, uint priceCandy);
    event OfferDelete(uint256 indexed unicornId);
    event UnicornSold(uint256 indexed unicornId, uint priceEth, uint priceCandy);
    event FreeOffer(uint256 indexed unicornId);
    event FreeHybridization(uint256 indexed unicornId);

    event NewSellDividendPercent(uint percentCandy, uint percentCandyEth);
    event NewSelfHybridizationPrice(uint percentCandy);

    event UnicornFreezingTimeSet(uint indexed unicornId, uint time);
    event UnicornTourFreezingTimeSet(uint indexed unicornId, uint time);


    ERC20 public candyToken;
    megaCandyInterface public megaCandyToken;
    BreedingDataBaseInterface public breedingDB;

    uint public sellDividendPercentCandy = 375; //OnlyManager 4 digits. 10.5% = 1050
    uint public sellDividendPercentEth = 375; //OnlyManager 4 digits. 10.5% = 1050
    uint public selfHybridizationPrice = 0;


    uint32[8] internal freezing = [
    uint32(1 hours),    //1 hour
    uint32(2 hours),    //2 - 4 hours
    uint32(8 hours),    //8 - 12 hours
    uint32(16 hours),   //16 - 24 hours
    uint32(36 hours),   //36 - 48 hours
    uint32(72 hours),   //72 - 96 hours
    uint32(120 hours),  //120 - 144 hours
    uint32(168 hours)   //168 hours
    ];

    //count for random plus from 0 to ..
    uint32[8] internal freezingPlusCount = [
    0, 3, 5, 9, 13, 25, 25, 0
    ];

    function() public payable {

    }

    function UnicornBreeding(address _breedingDB, address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {
        candyToken = ERC20(unicornManagement.candyToken());
        breedingDB = BreedingDataBaseInterface(_breedingDB);
    }

    function init() onlyManagement whenPaused external {
        unicornToken = UnicornTokenInterface(unicornManagement.unicornTokenAddress());
        blackBox = BlackBoxInterface(unicornManagement.blackBoxAddress());
        megaCandyToken = megaCandyInterface(unicornManagement.candyPowerToken());
    }

    function makeHybridization(uint _unicornId, uint _price) whenNotPaused public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(isUnfreezed(_unicornId));
        require(!breedingDB.hybridizationExists(_unicornId));
        require(unicornToken.getUnicornGenByte(_unicornId, 10) > 0);

        checkFreeze(_unicornId);
        breedingDB.createHybridization(_unicornId, _price);
        emit HybridizationAdd(_unicornId, _price);
        //свободная касса)
        if (_price == 0) {
            emit FreeHybridization(_unicornId);
        }
    }

    function acceptHybridization(uint _firstUnicornId, uint _secondUnicornId) whenNotPaused public payable {
        require(unicornToken.owns(msg.sender, _secondUnicornId));
        require(_secondUnicornId != _firstUnicornId);
        require(isUnfreezed(_firstUnicornId) && isUnfreezed(_secondUnicornId));
        require(breedingDB.hybridizationExists(_firstUnicornId));

        require(unicornToken.getUnicornGenByte(_firstUnicornId, 10) > 0 && unicornToken.getUnicornGenByte(_secondUnicornId, 10) > 0);
        require(msg.value == unicornManagement.oraclizeFee());

        uint price = breedingDB.hybridizationPrice(_firstUnicornId);

        if (price > 0) {
            require(candyToken.transferFrom(msg.sender, this, unicornManagement.getHybridizationFullPrice(price)));
        }

        plusFreezingTime(_firstUnicornId);
        plusFreezingTime(_secondUnicornId);
        uint256 newUnicornId = unicornToken.createUnicorn(msg.sender);
        blackBox.geneCore.value(unicornManagement.oraclizeFee())(newUnicornId, _firstUnicornId, _secondUnicornId);
        if (price > 0) {
            candyToken.transfer(unicornToken.ownerOf(_firstUnicornId), price);
        }
        emit HybridizationAccept(_firstUnicornId, _secondUnicornId, newUnicornId, price);
        emit CreateUnicorn(msg.sender, newUnicornId, _firstUnicornId, _secondUnicornId);
        _deleteHybridization(_firstUnicornId);
    }

    function selfHybridization(uint _firstUnicornId, uint _secondUnicornId) whenNotPaused public payable {
        require(unicornToken.owns(msg.sender, _firstUnicornId) && unicornToken.owns(msg.sender, _secondUnicornId));
        require(_secondUnicornId != _firstUnicornId);
        require(isUnfreezed(_firstUnicornId) && isUnfreezed(_secondUnicornId));
        require(unicornToken.getUnicornGenByte(_firstUnicornId, 10) > 0 && unicornToken.getUnicornGenByte(_secondUnicornId, 10) > 0);

        require(msg.value == unicornManagement.oraclizeFee());

        if (selfHybridizationPrice > 0) {
            require(candyToken.transferFrom(msg.sender, this, selfHybridizationPrice));
        }

        plusFreezingTime(_firstUnicornId);
        plusFreezingTime(_secondUnicornId);
        uint256 newUnicornId = unicornToken.createUnicorn(msg.sender);
        blackBox.geneCore.value(unicornManagement.oraclizeFee())(newUnicornId, _firstUnicornId, _secondUnicornId);
        emit SelfHybridization(_firstUnicornId, _secondUnicornId, newUnicornId, selfHybridizationPrice);
        emit CreateUnicorn(msg.sender, newUnicornId, _firstUnicornId, _secondUnicornId);
    }

    function cancelHybridization (uint _unicornId) whenNotPaused public {
        require(unicornToken.owns(msg.sender,_unicornId));
        //require(breedingDB.hybridizationExists(_unicornId));
        _deleteHybridization(_unicornId);
    }

    function deleteHybridization(uint _unicornId) onlyUnicornToken external {
        _deleteHybridization(_unicornId);
    }

    function _deleteHybridization(uint _unicornId) internal {
        if (breedingDB.deleteHybridization(_unicornId)) {
            emit HybridizationDelete(_unicornId);
        }
    }

    //Create new 0 gen
    function createUnicorn() public payable whenNotPaused returns(uint256)   {
        require(msg.value == getCreateUnicornPrice());
        return _createUnicorn(msg.sender);
    }

    function createUnicornForCandy() public payable whenNotPaused returns(uint256)   {
        require(msg.value == unicornManagement.oraclizeFee());
        require(candyToken.transferFrom(msg.sender, this, getCreateUnicornPriceInCandy()));
        return _createUnicorn(msg.sender);
    }

    function createPresaleUnicorns(uint _count, address _owner) public payable onlyManager whenPaused returns(bool) {
        require(breedingDB.gen0PresaleCount().add(_count) <= breedingDB.gen0PresaleLimit());
        uint256 newUnicornId;
        address owner = _owner == address(0) ? msg.sender : _owner;
        for (uint i = 0; i < _count; i++){
            newUnicornId = unicornToken.createUnicorn(owner);
            blackBox.createGen0(newUnicornId);
            emit CreateUnicorn(owner, newUnicornId, 0, 0);
            breedingDB.incGen0Count();
            breedingDB.incGen0PresaleCount();
        }
        return true;
    }

    function _createUnicorn(address _owner) private returns(uint256) {
        require(breedingDB.gen0Count() < breedingDB.gen0Limit());
        uint256 newUnicornId = unicornToken.createUnicorn(_owner);
        blackBox.createGen0.value(unicornManagement.oraclizeFee())(newUnicornId);
        emit CreateUnicorn(_owner, newUnicornId, 0, 0);
        breedingDB.incGen0Count();
        return newUnicornId;
    }

    function plusFreezingTime(uint _unicornId) private {
        checkFreeze(_unicornId);
        //если меньше 3 спарок увеличиваю просто спарки, если 3 тогда увеличиваю индекс
        if (breedingDB.freezeHybridizationsCount(_unicornId) < 3) {
            breedingDB.incFreezeHybridizationsCount(_unicornId);
        } else {
            if (breedingDB.freezeIndex(_unicornId) < freezing.length - 1) {
                breedingDB.incFreezeIndex(_unicornId);
                breedingDB.setFreezeHybridizationsCount(_unicornId,0);
            }
        }

        uint _time = _getFreezeTime(breedingDB.freezeIndex(_unicornId)) + now;
        breedingDB.setFreezeEndTime(_unicornId, _time);
        emit UnicornFreezingTimeSet(_unicornId, _time);
    }

    function checkFreeze(uint _unicornId) internal {
        if (!breedingDB.freezeExists(_unicornId)) {
            breedingDB.createFreeze(_unicornId, unicornToken.getUnicornGenByte(_unicornId, 163));
        }
        if (breedingDB.freezeMustCalculate(_unicornId)) {
            breedingDB.setFreezeMustCalculate(_unicornId, false);
            breedingDB.setStatsSumHours(_unicornId, _getStatsSumHours(_unicornId));
        }
    }

    function _getRarity(uint8 _b) internal pure returns (uint8) {
        //        [1; 188] common
        //        [189; 223] uncommon
        //        [224; 243] rare
        //        [244; 253] epic
        //        [254; 255] legendary
        return _b < 1 ? 0 : _b < 189 ? 1 : _b < 224 ? 2 : _b < 244 ? 3 : _b < 254 ? 4 : 5;
    }

    function _getStatsSumHours(uint _unicornId) internal view returns (uint) {
        uint8[5] memory physStatBytes = [
        //physical
        112, //strength
        117, //agility
        122, //speed
        127, //intellect
        132 //charisma
        ];
        uint8[10] memory rarity1Bytes = [
        //rarity old
        13, //body-form
        18, //wings-form
        23, //hoofs-form
        28, //horn-form
        33, //eyes-form
        38, //hair-form
        43, //tail-form
        48, //stone-form
        53, //ears-form
        58 //head-form
        ];
        uint8[10] memory rarity2Bytes = [
        //rarity new
        87, //body-form
        92, //wings-form
        97, //hoofs-form
        102, //horn-form
        107, //eyes-form
        137, //hair-form
        142, //tail-form
        147, //stone-form
        152, //ears-form
        157 //head-form
        ];

        uint sum = 0;
        uint i;
        for(i = 0; i < 5; i++) {
            sum += unicornToken.getUnicornGenByte(_unicornId, physStatBytes[i]);
        }

        for(i = 0; i < 10; i++) {
            //get v.2 rarity
            uint rarity = unicornToken.getUnicornGenByte(_unicornId, rarity2Bytes[i]);
            if (rarity == 0) {
                //get v.1 rarity
                rarity = _getRarity(unicornToken.getUnicornGenByte(_unicornId, rarity1Bytes[i]));
            }
            sum += rarity;
        }
        return sum * 1 hours;
    }

    function isUnfreezed(uint _unicornId) public view returns (bool) {
        return unicornToken.isUnfreezed(_unicornId) && breedingDB.freezeEndTime(_unicornId) <= now;
    }

    function enableFreezePriceRateRecalc(uint _unicornId) onlyGeneLab external {
        breedingDB.setFreezeMustCalculate(_unicornId, true);
    }

    /*
       (сумма генов + количество часов заморозки)/количество часов заморозки = стоимость снятия 1го часа заморозки в MegaCandy
    */
    function getUnfreezingPrice(uint _unicornId) public view returns (uint) {
        uint32 freezeHours = freezing[breedingDB.freezeIndex(_unicornId)];
        return unicornManagement.subFreezingPrice()
        .mul(breedingDB.freezeStatsSumHours(_unicornId).add(freezeHours))
        .div(freezeHours);
    }

    function _getFreezeTime(uint freezingIndex) internal view returns (uint time) {
        time = freezing[freezingIndex];
        if (freezingPlusCount[freezingIndex] != 0) {
            time += (uint(block.blockhash(block.number - 1)) % freezingPlusCount[freezingIndex]) * 1 hours;
        }
    }

    //change freezing time for megacandy
    function minusFreezingTime(uint _unicornId, uint _count) public {
        uint price = getUnfreezingPrice(_unicornId);
        require(megaCandyToken.burn(msg.sender, price.mul(_count)));
        //не минусуем на уже размороженных конях
        require(breedingDB.freezeEndTime(_unicornId) > now);
        //не используем safeMath, т.к. subFreezingTime в теории не должен быть больше now %)
        breedingDB.minusFreezeEndTime(_unicornId, uint(unicornManagement.subFreezingTime()).mul(_count));
    }

    function getHybridizationPrice(uint _unicornId) public view returns (uint) {
        return unicornManagement.getHybridizationFullPrice(breedingDB.hybridizationPrice(_unicornId));
    }

    function getEtherFeeForPriceInCandy() public view returns (uint) {
        return unicornManagement.oraclizeFee();
    }

    function getCreateUnicornPriceInCandy() public view returns (uint) {
        return unicornManagement.getCreateUnicornFullPriceInCandy();
    }


    function getCreateUnicornPrice() public view returns (uint) {
        return unicornManagement.getCreateUnicornFullPrice();
    }


    function withdrawTokens() onlyManager public {
        require(candyToken.balanceOf(this) > 0);
        candyToken.transfer(unicornManagement.walletAddress(), candyToken.balanceOf(this));
    }


    function transferEthersToDividendManager(uint _value) onlyManager public {
        require(address(this).balance >= _value);
        DividendManagerInterface dividendManager = DividendManagerInterface(unicornManagement.dividendManagerAddress());
        dividendManager.payDividend.value(_value)();
        emit FundsTransferred(unicornManagement.dividendManagerAddress(), _value);
    }


    function setGen0Limit() external onlyCommunity {
        require(breedingDB.gen0Count() == breedingDB.gen0Limit());
        breedingDB.incGen0Limit();
        emit NewGen0Limit(breedingDB.gen0Limit());
    }

    ////MARKET

    function sellUnicorn(uint _unicornId, uint _priceEth, uint _priceCandy) whenNotPaused public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(!breedingDB.offerExists(_unicornId));

        breedingDB.createOffer(_unicornId, _priceEth, _priceCandy);

        emit OfferAdd(_unicornId, _priceEth, _priceCandy);
        //налетай)
        if (_priceEth == 0 && _priceCandy == 0) {
            emit FreeOffer(_unicornId);
        }
    }

    function buyUnicornWithEth(uint _unicornId) whenNotPaused public payable {
        require(breedingDB.offerExists(_unicornId));
        uint price = breedingDB.offerPriceEth(_unicornId);
        //Выставлять на продажу за 0 можно. Но нужно проверить чтобы и вторая цена также была 0
        if (price == 0) {
            require(breedingDB.offerPriceCandy(_unicornId) == 0);
        }
        require(msg.value == getOfferPriceEth(_unicornId));

        address owner = unicornToken.ownerOf(_unicornId);

        emit UnicornSold(_unicornId, price, 0);
        //deleteoffer вызовется внутри transfer
        unicornToken.marketTransfer(owner, msg.sender, _unicornId);
        owner.transfer(price);
    }

    function buyUnicornWithCandy(uint _unicornId) whenNotPaused public {
        require(breedingDB.offerExists(_unicornId));
        uint price = breedingDB.offerPriceCandy(_unicornId);
        //Выставлять на продажу за 0 можно. Но нужно проверить чтобы и вторая цена также была 0
        if (price == 0) {
            require(breedingDB.offerPriceEth(_unicornId) == 0);
        }

        address owner = unicornToken.ownerOf(_unicornId);

        if (price > 0) {
            require(candyToken.transferFrom(msg.sender, this, getOfferPriceCandy(_unicornId)));
            candyToken.transfer(owner, price);
        }

        emit UnicornSold(_unicornId, 0, price);
        //deleteoffer вызовется внутри transfer
        unicornToken.marketTransfer(owner, msg.sender, _unicornId);
    }


    function revokeUnicorn(uint _unicornId) whenNotPaused public {
        require(unicornToken.owns(msg.sender, _unicornId));
        //require(breedingDB.offerExists(_unicornId));
        _deleteOffer(_unicornId);
    }


    function deleteOffer(uint _unicornId) onlyUnicornToken external {
        _deleteOffer(_unicornId);
    }


    function _deleteOffer(uint _unicornId) internal {
        if (breedingDB.offerExists(_unicornId)) {
            breedingDB.deleteOffer(_unicornId);
            emit OfferDelete(_unicornId);
        }
    }


    function getOfferPriceEth(uint _unicornId) public view returns (uint) {
        uint priceEth = breedingDB.offerPriceEth(_unicornId);
        return priceEth.add(valueFromPercent(priceEth, sellDividendPercentEth));
    }


    function getOfferPriceCandy(uint _unicornId) public view returns (uint) {
        uint priceCandy = breedingDB.offerPriceCandy(_unicornId);
        return priceCandy.add(valueFromPercent(priceCandy, sellDividendPercentCandy));
    }


    function setSellDividendPercent(uint _percentCandy, uint _percentEth) public onlyManager {
        //no more then 25%
        require(_percentCandy < 2500 && _percentEth < 2500);

        sellDividendPercentCandy = _percentCandy;
        sellDividendPercentEth = _percentEth;
        emit NewSellDividendPercent(_percentCandy, _percentEth);
    }


    function setSelfHybridizationPrice(uint _percentCandy) public onlyManager {
        selfHybridizationPrice = _percentCandy;
        emit NewSelfHybridizationPrice(_percentCandy);
    }


    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }

}