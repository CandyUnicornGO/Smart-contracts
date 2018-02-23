pragma solidity ^0.4.18;

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



contract CandyCoinInterface {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}


contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _unicornId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _unicornId);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _unicornId) public view returns (address _owner);
    function transfer(address _to, uint256 _unicornId) public;
    function approve(address _to, uint256 _unicornId) public;
    function takeOwnership(uint256 _unicornId) public; //TODO
    function totalSupply() public constant returns (uint);
    function owns(address _claimant, uint256 _unicornId) public view returns (bool);
    function allowance(address _claimant, uint256 _unicornId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _unicornId) public;
}





contract BlackBoxAccessControl {
    address public owner;
    address public breedingAddress;
    UnicornBreeding public breedingContract;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function BlackBoxAccessControl() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    //TODO ?? LIST OF Address
    modifier onlyBreeding() {
        require(msg.sender == breedingAddress);
        _;
    }

    function setBreeding(address _breedingAddress) external onlyOwner {
        require(_breedingAddress != address(0));
        breedingAddress = _breedingAddress;
        breedingContract = UnicornBreeding(breedingAddress);
    }

}


contract BlackBoxController is BlackBoxAccessControl, usingOraclize  {

    event logRes(string res);
    event LogNewOraclizeQuery(string description);

    mapping(bytes32 => uint) validIds; //oraclize query hash -> unicorn_id - 1 for require validIds[hash] > 0
    //only for compile
    mapping(bytes => uint) test;

    function BlackBoxController() public {
        oraclize_setCustomGasPrice(2000000000 wei);
    }

    function() public payable {

    }

    //
    function __callback(bytes32 hash, string result) public {
        require(validIds[hash] > 0);
        require(msg.sender == oraclize_cbAddress());

        bytes memory gen = bytes(result);

        breedingContract.setGen(validIds[hash] - 1,gen);
        logRes(result);
        delete validIds[hash];
    }


    //only UnicornContract;
    //TODO gas limit
    function genCore(uint unicornId, bytes gen1, bytes gen2) onlyBreeding public payable returns (bool) {
        if (oraclize_getPrice("URL") > this.balance) {
            LogNewOraclizeQuery("GeneCore query was NOT sent, please add some ETH to cover for the query fee");
            return false;
        } else {

            string memory str1 = '\n{"unicron_blockchain_id":';
            string memory str2 = ',"gen1":';
            string memory str3 = ',"gen2":';

            str1 = strConcat(str1, uint2str(unicornId), str2, string(gen1), str3);

            string memory str4 = '}';


            LogNewOraclizeQuery("GeneCore query was sent, standing by for the answer..");

            bytes32 queryId =
            oraclize_query("URL", "json(http://core.unicorngo.io/v1/genetics/generate-unicorn).chain", strConcat(str1, string(gen2), str4), 400000);

            validIds[queryId] = unicornId + 1; //for require validIds[hash] > 0
            return true;
        }



        //FOR TEST ONLY;
        string memory str = "A76A95918C39eE40d4a43CFAF19C35050E32E271";
        breedingContract.setGen(unicornId,bytes(str));

        //__callback(queryId, 'A76A95918C39eE40d4a43CFAF19C35050E32E271');

        test[gen1] = 1;
        test[gen2] = 1;

        return true;
    }

    //TODO gas limit eth_gasPrice
    //only UnicornContract;
    function createGen0(uint unicornId) onlyBreeding public payable returns (bool) {
        if (oraclize_getPrice("URL") > this.balance) {
            LogNewOraclizeQuery("CreateGen0 query was NOT sent, please add some ETH to cover for the query fee");
            return false;
        } else {

            string memory str1 = '\n{"unicron_blockchain_id":';
            string memory str2 = '}';

            LogNewOraclizeQuery("CreateGen0 query was sent, standing by for the answer..");

            bytes32 queryId =
                oraclize_query("URL", "json(http://core.unicorngo.io/v1/genetics/generate-unicorn).chain", strConcat(str1, uint2str(unicornId),str2), 400000);

            validIds[queryId] = unicornId + 1; //for require validIds[hash] > 0
            return true;
        }
    }


    function setGasPrice(uint _newPrice) public onlyOwner {
        oraclize_setCustomGasPrice(_newPrice * 1 wei);
    }


    function isBlackBox() public pure returns (bool) {
        return true;
    }
}


contract BlackBoxInterface {
    function isBlackBox() public pure returns (bool);
    function createGen0(uint unicornId) public payable returns (bool);
    function genCore(uint unicornId,bytes gen1, bytes gen2) public payable returns (bool);
}



contract UnicornAccessControl {
    event Pause();
    event Unpause();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;
    address public managerAddress;
    address public communityAddress;

    bool public paused = false;

    function UnicornAccessControl() public {
        owner = msg.sender;
        managerAddress = msg.sender;
        communityAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
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

    modifier onlyOLevel() {
        require(
            msg.sender == owner ||
            msg.sender == managerAddress
        );
        _;
    }

    function transferOwnership(address newOwner) external  onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    function setManager(address _newManager) external onlyOwner {
        require(_newManager != address(0));
        managerAddress = _newManager;
    }


    function setCommunity(address _newCommunityAddress) external onlyCommunity {
        require(_newCommunityAddress != address(0));
        communityAddress = _newCommunityAddress;
    }


    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }


    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}


contract UnicornBase is ERC721{
    using SafeMath for uint;
    event  UnicornBirth(address owner, uint256 unicornId);

    struct Unicorn {
        bytes gen;
        uint64 birthTime;

        uint freezingEndTime; //TODO
        uint16 freezingIndex; //TODO ????

        string name;
    }

    //TODO
    uint32[14] public freezing = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];


    // Total amount of unicorns
    uint256 private totalUnicorns;

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


    modifier onlyOwnerOf(uint256 _unicornId) {
        require(ownerOf(_unicornId) == msg.sender);
        _;
    }


    /**
    * @dev Gets the owner of the specified unicorn ID
    * @param _unicornId uint256 ID of the unicorn to query the owner of
    * @return owner address currently marked as the owner of the given unicorn ID
    */
    function ownerOf(uint256 _unicornId) public view returns (address) {
        address owner = unicornOwner[_unicornId];
        require(owner != address(0));
        return owner;
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
    function isApprovedFor(address _owner, uint256 _unicornId) internal view returns (bool) {
        return approvedFor(_unicornId) == _owner;
    }

    /**
    * @dev Approves another address to claim for the ownership of the given unicorn ID
    * @param _to address to be approved for the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be approved
    */
    function approve(address _to, uint256 _unicornId) public onlyOwnerOf(_unicornId) {
        address owner = ownerOf(_unicornId);
        require(_to != owner);
        if (approvedFor(_unicornId) != address(0) || _to != address(0)) {
            unicornApprovals[_unicornId] = _to;
            Approval(owner, _to, _unicornId);
        }
    }

    /**
    * @dev Claims the ownership of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn being claimed by the msg.sender
    */
    function takeOwnership(uint256 _unicornId) public {
        require(isApprovedFor(msg.sender, _unicornId));
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
        require(_to != address(0));
        require(_to != ownerOf(_unicornId));
        require(ownerOf(_unicornId) == _from);

        clearApproval(_from, _unicornId);
        removeUnicorn(_from, _unicornId);
        addUnicorn(_to, _unicornId);
        Transfer(_from, _to, _unicornId);
    }

    /**
    * @dev Internal function to clear current approval of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function clearApproval(address _owner, uint256 _unicornId) private {
        require(ownerOf(_unicornId) == _owner);
        unicornApprovals[_unicornId] = 0;
        Approval(_owner, 0, _unicornId);
    }

    /**
    * @dev Internal function to add a unicorn ID to the list of a given address
    * @param _to address representing the new owner of the given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be added to the unicorns list of the given address
    */
    function addUnicorn(address _to, uint256 _unicornId) private {
        require(unicornOwner[_unicornId] == address(0));
        unicornOwner[_unicornId] = _to;
        // use direct, due to decrease gas
        //        uint256 length = balanceOf(_to);
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
        require(ownerOf(_unicornId) == _from);

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
    }

    /**
    * @dev Mint unicorn function
    * @param _to The address that will own the minted unicorn
    * @param _unicornId uint256 ID of the unicorn to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _unicornId, Unicorn _unicorn) internal {
        require(_to != address(0));
        addUnicorn(_to, _unicornId);
        //store new unicorn data
        unicorns[_unicornId] = _unicorn;
        Transfer(0x0, _to, _unicornId);
    }

    /**
    * @dev Burns a specific unicorn
    * @param _unicornId uint256 ID of the unicorn being burned by the msg.sender
    */
    //TODO спросить геймдиза
    function _burn(uint256 _unicornId) onlyOwnerOf(_unicornId) internal {
        if (approvedFor(_unicornId) != 0) {
            clearApproval(msg.sender, _unicornId);
        }
        removeUnicorn(msg.sender, _unicornId);
        //destroy unicorn data
        delete unicorns[_unicornId];
        Transfer(msg.sender, 0x0, _unicornId);
    }

    //specific

    function _createUnicorn(address _owner) internal returns (uint)    {
        Unicorn memory _unicorn = Unicorn({
            gen : new bytes(1),
            birthTime : uint64(now),
            freezingEndTime : 0,
            freezingIndex : 4,//TODO GET FROM GEN
            name: ""
            });

        uint256 _unicornId = totalUnicorns;
        _mint(_owner, _unicornId, _unicorn);

        UnicornBirth(_owner, _unicornId);

        return _unicornId;
    }


    function owns(address _claimant, uint256 _unicornId) public view returns (bool) {
        return ownerOf(_unicornId) == _claimant;
    }


    function allowance(address _claimant, uint256 _unicornId) public view returns (bool) {
        return isApprovedFor(_claimant, _unicornId);
    }


    function transferFrom(address _from, address _to, uint256 _unicornId) public {
        require(_to != address(this));
        require(isApprovedFor(msg.sender, _unicornId));
        clearApprovalAndTransfer(_from, _to, _unicornId);
    }


    function setName(uint256 _unicornId, string _name ) public onlyOwnerOf(_unicornId) returns (bool) {
        bytes memory tmp = bytes(unicorns[_unicornId].name);
        require(tmp.length  == 0);

        unicorns[_unicornId].name = _name;
        return true;
    }


    function fromHexChar(uint8 _c) internal pure returns (uint8) {
        return _c - (_c < 58 ? 48 : (_c < 97 ? 55 : 87));
    }


    function getUnicornGenByte(uint _unicornId, uint _byteNo) public view returns (uint8 _byte) {
        uint n = _byteNo << 1; // = _byteNo * 2
        require(unicorns[_unicornId].gen.length >= n + 1);
        _byte = fromHexChar(uint8(unicorns[_unicornId].gen[n])) << 4 | fromHexChar(uint8(unicorns[_unicornId].gen[n + 1]));
    }

}


contract Unicorn is UnicornBase {
    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";
}



contract UnicornBreeding is Unicorn, UnicornAccessControl {
    using SafeMath for uint;


    event HybridizationAdded(uint indexed lastHybridizationId, uint indexed UnicornId, uint price);
    event HybridizationAccepted(uint indexed HybridizationId, uint indexed UnicornId, uint  NewUnicornId);
    event HybridizationCancelled(uint indexed HybridizationId);
    event FundsTransferred(address dividendManager, uint value);
    event CreateUnicorn(address indexed owner, uint indexed UnicornId);

    BlackBoxInterface public blackBoxContract; //onlyOwner
    address public blackBoxAddress; //onlyOwner
    CandyCoinInterface token; //SET on deploy

    uint public subFreezingPrice; //onlyCommunity price in CandyCoins
    uint public subFreezingTime; //onlyCommunity
    uint public dividendPercent; //OnlyManager 4 digits. 10.5% = 1050
    uint public createUnicornPrice; //OnlyManager price in weis
    address public dividendManagerAddress; //onlyCommunity

    //uint oraclizeFeeAmount;
    uint public oraclizeFee;


    uint public lastHybridizationId;

    struct Hybridization{
        uint unicorn_id;
        uint price;
        uint second_unicorn_id;
        bool accepted;
        bytes32 hash;
    }

    mapping (uint => Hybridization) public hybridizations;

    modifier onlyBlackBox() {
        require(msg.sender == blackBoxAddress);
        _;
    }

    function UnicornBreeding(address _token, address _dividendManagerAddress) public    {
        token = CandyCoinInterface(_token);
        dividendManagerAddress = _dividendManagerAddress;
        lastHybridizationId = 0;
        subFreezingPrice = 1; //TODO set with Decimals
        subFreezingTime = 1 minutes;
        dividendPercent = 375; //3.75%
        createUnicornPrice = 10000000000000000;
    }


    function setBlackBoxAddress(address _address) external onlyOwner    {
        require(_address != address(0));
        BlackBoxInterface candidateContract = BlackBoxInterface(_address);
        require(candidateContract.isBlackBox());
        blackBoxContract = candidateContract;
        blackBoxAddress = _address;
    }

    function setDividendManagerAddress(address _dividendManagerAddress) external onlyCommunity    {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;
    }


    //TODO ?? require _unicornId exists in Hybridizations
    function makeHybridization(uint _unicornId, uint _price)  public returns (uint HybridizationId)    {
        require(owns(msg.sender, _unicornId));
        require(isReadyForHybridization(_unicornId));

        lastHybridizationId += 1;
        Hybridization storage h = hybridizations[lastHybridizationId];

        h.unicorn_id = _unicornId;
        h.price = _price;

        h.second_unicorn_id = 0;
        h.accepted = false;

        h.hash = keccak256(lastHybridizationId,h.unicorn_id,h.price);

        HybridizationAdded(lastHybridizationId, h.unicorn_id,h.price);

        return lastHybridizationId;
    }


    function acceptHybridization(uint _hybridizationId, uint _unicornId) public payable    {
        Hybridization storage h = hybridizations[_hybridizationId];
        require (!h.accepted);
        require (keccak256(_hybridizationId,h.unicorn_id,h.price)==h.hash);
        require(owns(msg.sender, _unicornId));
        require(_unicornId != h.unicorn_id);

        //uint price = h.price.add(valueFromPercent(h.price,dividendPercent));

        require(msg.value == h.price.add(valueFromPercent(h.price,dividendPercent)).add(oraclizeFee));
        require(isReadyForHybridization(_unicornId));

        //oraclizeFeeAmount = oraclizeFeeAmount.add(oraclizeFee);

        h.second_unicorn_id = _unicornId;

        uint256 childUnicornId  = _createUnicorn(msg.sender);
        blackBoxContract.genCore.value(oraclizeFee)(childUnicornId,unicorns[h.unicorn_id].gen,unicorns[h.second_unicorn_id].gen);

        address own = ownerOf(h.unicorn_id);
        own.transfer(h.price);

        _setFreezing(_unicornId);

        h.accepted = true;
        HybridizationAccepted(_hybridizationId, _unicornId, childUnicornId);

        //TODO ?? delete hybridizations[hybridizationId]
    }


    function cancelHybridization (uint _hybridizationId) public     {
        Hybridization storage h = hybridizations[_hybridizationId];
        require (!h.accepted);
        require (keccak256(_hybridizationId,h.unicorn_id,h.price)==h.hash);
        require(owns(msg.sender, h.unicorn_id));

        h.accepted = true;

        HybridizationCancelled(_hybridizationId);
        //TODO ?? delete hybridizations[hybridizationId]
    }


    //Create new 0 gen
    function createUnicorn() public payable returns(uint256)   {
        require(msg.value == createUnicornPrice.add(oraclizeFee));

        //oraclizeFeeAmount = oraclizeFeeAmount.add(oraclizeFee);

        uint256 newUnicornId = _createUnicorn(msg.sender);
        if (!blackBoxContract.createGen0.value(oraclizeFee)(newUnicornId)) {
            revert();
        }


        CreateUnicorn(msg.sender,newUnicornId);
        return newUnicornId;
    }


    function isReadyForHybridization(uint _unicornId) public view returns (bool)    {
        return (unicorns[_unicornId].freezingEndTime <= uint64(now));
    }


    //TODO
    function _setFreezing(uint _unicornId) internal    {
        Unicorn storage unicorn = unicorns[_unicornId];

        unicorn.freezingEndTime = uint64((freezing[unicorn.freezingIndex]) + uint64(now));
    }


    //change freezing time for candy
    function subFreezingTime(uint _unicornId) public    {
        require(token.allowance(msg.sender, this) >= subFreezingPrice);
        require(token.transferFrom(msg.sender, this, subFreezingPrice));

        Unicorn storage unicorn = unicorns[_unicornId];

        unicorn.freezingEndTime = unicorn.freezingEndTime.sub(subFreezingTime);
    }


    //TODO decide roles and requires
    //price in CandyCoins
    function setSubFreezingPrice(uint _newPrice) public onlyCommunity    {
        subFreezingPrice = _newPrice;
    }

    //TODO decide roles and requires
    //time in minutes
    function setSubFreezingTime(uint _newTime) public onlyCommunity    {
        subFreezingTime = _newTime * 1 minutes;
    }

    //TODO decide roles and requires
    //1% = 100
    function setDividendPercent(uint _newPercent) public onlyManager    {
        require(_newPercent < 2500); //no more then 25%
        dividendPercent = _newPercent;
    }

    //TODO decide roles and requires
    //price in weis
    function setCreateUnicornPrice(uint _newPrice) public onlyManager    {
        createUnicornPrice = _newPrice;
    }

    //in weis
    function setOraclizeFee(uint _newFee) public onlyManager    {
        oraclizeFee = _newFee;
    }


    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns(uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }


    //TODO
    function withdrawTokens(address _to, uint _value) onlyManager public    {
        token.transfer(_to,_value);
    }


    function transferEthersToDividendManager(uint _valueInFinney) onlyManager public    {
        require(this.balance >= _valueInFinney * 1 finney);
        //require(this.balance.sub(oraclizeFeeAmount) >= _valueInFinney * 1 finney);
        dividendManagerAddress.transfer(_valueInFinney);
        FundsTransferred(dividendManagerAddress, _valueInFinney * 1 finney);
    }


    /*function transferOraclizeFee() onlyManager public    {
        require(oraclizeFeeAmount > 0);
        blackBoxContract.transfer(oraclizeFeeAmount);
        oraclizeFeeAmount = 0;
    }*/


    function setGen(uint _unicornId, bytes _gen) onlyBlackBox public {
        unicorns[_unicornId].gen = _gen;
    }


}





/* The UnicornToken Token itself is a simple extension of the ERC20 that allows for granting other Unicorn Token contracts special rights to act on behalf of all transfers. */
contract UnicornToken {
    using SafeMath for uint256;

    /* Map all our our balances for issued tokens */
    mapping (address => uint256) balances;

    /* Map between users and their approval addresses and amounts */
    mapping(address => mapping (address => uint256)) allowed;

    /* List of all token holders */
    address[] allTokenHolders;
    mapping(address => uint) public holdersIndexes; //index start from 1

    string public constant name = "Unicorn Dividend Token";
    string public constant symbol = "UDT";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 100  * (10 ** uint256(decimals));

    /* Defines the current supply of the token in its own units */
    uint256 totalSupplyAmount = 0;

    /* Defines the address of the ICO contract which is the only contract permitted to mint tokens. */
    //address public icoContractAddress;

    /* Defines whether or not the fund is closed. */
    bool public isClosed;

    /* Defines the contract handling the ICO phase. */
    //IcoPhaseManagement icoPhaseManagement;

    /* Defines the admin contract we interface with for credentails. */
    //AuthenticationManager authenticationManager;

    /* Fired when the fund is eventually closed. */
    event FundClosed();

    /* Our transfer event to fire whenever we shift SMRT around */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Our approval event when one user approves another to control */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Create a new instance of this fund with links to other contracts that are required. */
    function UnicornToken() public {
        totalSupplyAmount = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        tokenOwnerAdd(msg.sender);
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /* Transfer funds between two addresses that are not the current msg.sender - this requires approval to have been set separately and follows standard ERC20 guidelines */
    function transferFrom(address _from, address _to, uint256 _amount) public onlyPayloadSize(3) returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
            bool isNew = balances[_to] == 0;
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);

            if (isNew)
                tokenOwnerAdd(_to);
            if (balances[_from] == 0)
                tokenOwnerRemove(_from);

            Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

    /* Returns the total number of holders of this currency. */
    function tokenHolderCount()  public constant returns (uint256) {
        return allTokenHolders.length;
    }

    /* Gets the token holder at the specified index. */
    function tokenHolder(uint256 _index)  public constant returns (address) {
        return allTokenHolders[_index];
    }

    /* Adds an approval for the specified account to spend money of the message sender up to the defined limit */
    function approve(address _spender, uint256 _amount) public onlyPayloadSize(2) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Gets the current allowance that has been approved for the specified spender of the owner address */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* Gets the total supply available of this token */
    function totalSupply() public constant returns (uint256) {
        return totalSupplyAmount;
    }

    /* Gets the balance of a specified account */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfer the balance from owner's account to another account */
    function transfer(address _to, uint256 _amount) public onlyPayloadSize(2) returns (bool) {
        /* Check if sender has balance and for overflows */
        if (balances[msg.sender] < _amount || balances[_to].add(_amount) < balances[_to])
            return false;

        /* Do a check to see if they are new, if so we'll want to add it to our array */
        bool isRecipientNew = balances[_to] == 0;

        /* Add and subtract new balances */
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        /* Consolidate arrays if they are new or if sender now has empty balance */
        if (isRecipientNew)
            tokenOwnerAdd(_to);
        if (balances[msg.sender] == 0)
            tokenOwnerRemove(msg.sender);

        /* Fire notification event */
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    //TODO TEST
    /* If the specified address is not in our owner list, add them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerAdd(address _addr) internal {
        if (holdersIndexes[_addr] == 0) {
            allTokenHolders.length++;
            allTokenHolders[allTokenHolders.length - 1] = _addr;
            //сохраняем индекс в мапинг (нумерация от 1)
            holdersIndexes[_addr] = allTokenHolders.length;
        }
    }

    /* If the specified address is in our owner list, remove them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerRemove(address _addr) internal {
        if (holdersIndexes[_addr] > 0) {
            //заменяем удаляемый элемент последним элементом из массива.
            allTokenHolders[holdersIndexes[_addr]-1] = allTokenHolders[allTokenHolders.length - 1];
            //меняем индексы у удлаенного элемента с последним.
            holdersIndexes[allTokenHolders[allTokenHolders.length - 1]] = holdersIndexes[_addr];
            //обнуляем индекс удаленного элемента
            holdersIndexes[_addr] = 0;
            //умменьшаем массив
            allTokenHolders.length--;
        }
    }

}


contract DividendManager {
    using SafeMath for uint256;

    /* Our handle to the UnicornToken contract. */
    UnicornToken unicornContract;

    /* Handle payments we couldn't make. */
    mapping (address => uint256) public dividends;

    /* Indicates a payment is now available to a shareholder */
    event PaymentAvailable(address addr, uint256 amount);

    /* Indicates a dividend payment was made. */
    event DividendPayment(uint256 paymentPerShare, uint256 timestamp);

    /* Create our contract with references to other contracts as required. */
    function DividendManager(address _unicornContract) public{
        /* Setup access to our other contracts and validate their versions */
        unicornContract = UnicornToken(_unicornContract);
    }

    //TODO
    /* Makes a dividend payment - we make it available to all senders then send the change back to the caller.  We don't actually send the payments to everyone to reduce gas cost and also to
       prevent potentially getting into a situation where we have recipients throwing causing dividend failures and having to consolidate their dividends in a separate process. */
    function () public payable {
        //if (unicornContract.isClosed())


        /* Determine how much to pay each shareholder. */
        uint256 validSupply = unicornContract.totalSupply();
        uint256 paymentPerShare = msg.value.div(validSupply);
        require (paymentPerShare > 0); //!!!

        /* Enum all accounts and send them payment */
        uint256 totalPaidOut = 0;
        for (uint256 i = 0; i < unicornContract.tokenHolderCount(); i++) {
            address addr = unicornContract.tokenHolder(i);
            uint256 dividend = paymentPerShare * unicornContract.balanceOf(addr);
            dividends[addr] = dividends[addr].add(dividend);
            PaymentAvailable(addr, dividend);
            totalPaidOut = totalPaidOut.add(dividend);
        }

        // Attempt to send change
        /*uint256 remainder = msg.value.sub(totalPaidOut);
        if (remainder > 0 && !msg.sender.send(remainder)) {
            dividends[msg.sender] = dividends[msg.sender].add(remainder);
            PaymentAvailable(msg.sender, remainder);
        }*/

        /* Audit this */
        DividendPayment(paymentPerShare, now);
    }

    /* Allows a user to request a withdrawal of their dividend in full. */
    function withdrawDividend() public{
        // Ensure we have dividends available
        require (dividends[msg.sender] > 0);//!!!
        // Determine how much we're sending and reset the count
        uint256 dividend = dividends[msg.sender];
        dividends[msg.sender] = 0;


        msg.sender.transfer(dividend); //!!!

    }
}


contract Crowdsale {

    Unicorn public token;

    mapping (uint256 => uint256) public prices; // if prices[id] = 0 then not for sale

    event TokenPurchase( address indexed beneficiary, uint256 unicornId);
    event TokenSale( address indexed beneficiary, uint256 unicornId);

    function Crowdsale(address _token) public {
        token = UnicornBreeding(_token);
    }

    function saleUnicorn(uint unicornId, uint price) public {
        prices[unicornId] = price;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        //require(msg.value == price);

        //uint unicornId = token.newBirth(beneficiary);
        //TokenPurchase(msg.sender, unicornId);

        //forwardFunds();
    }

    function buyUnicorn(uint unicornId) public payable {
        require(msg.value >= prices[unicornId]);
        uint dif = msg.value - prices[unicornId];
        address own = token.ownerOf(unicornId);
        require(token.allowance(this,unicornId));
        token.transferFrom(own, msg.sender,unicornId);
        own.transfer(prices[unicornId]);
        msg.sender.transfer(dif);  // give change
        prices[unicornId] = 0; // unicorn sold
        TokenSale(msg.sender, unicornId);
    }

}


