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
    address public communityAddress;
    address public breedingAddress;
    address public dividendManagerAddress;

    UnicornBreeding public breedingContract;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function BlackBoxAccessControl() public {
        owner = msg.sender;
        communityAddress = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == breedingAddress);
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == communityAddress);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    function setBreeding(address _breedingAddress) external onlyOwner {
        require(_breedingAddress != address(0));
        breedingAddress = _breedingAddress;
        breedingContract = UnicornBreeding(breedingAddress);
    }


    function setDividendManagerAddress(address _dividendManagerAddress) external onlyCommunity    {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;
    }


    function setCommunity(address _newCommunityAddress) external onlyCommunity {
        require(_newCommunityAddress != address(0));
        communityAddress = _newCommunityAddress;
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
    function genCore(uint unicornId, uint unicorn1_id, bytes gen1, uint unicorn2_id, bytes gen2) onlyBreeding public payable returns (bool) {
        if (oraclize_getPrice("URL") > this.balance) {
            LogNewOraclizeQuery("GeneCore query was NOT sent, please add some ETH to cover for the query fee");
            return false;
        } else {

            string memory str1 = '\n{"parents": [{"unicorn_blockchain_id":';
            string memory str2 = strConcat(str1, uint2str(unicorn1_id), ',"chain":"', string(gen1), '"},{"unicorn_blockchain_id":');
            str2 = strConcat(str2, uint2str(unicorn2_id), ',"chain":"', string(gen2), '"}],"parent_idx": 1,"unicorn_blockchain_id":');

            LogNewOraclizeQuery("GeneCore query was sent, standing by for the answer..");

            bytes32 queryId =
            oraclize_query("URL", "json(http://core.unicorngo.io/v1/unicorn/pair).chain",
                                    strConcat(str2,uint2str(unicornId),'}'), 400000);

            validIds[queryId] = unicornId + 1; //for require validIds[hash] > 0
            return true;

//            {"parents": [{"unicorn_blockchain_id":0,"chain":test},{"unicorn_blockchain_id":1,"chain":test}],"parent_idx": 1,"unicorn_blockchain_id":3}
        }
    }

    //TODO gas limit eth_gasPrice
    //only UnicornContract;
    function createGen0(uint _unicornId, uint _type) onlyBreeding public payable returns (bool) {
        if (oraclize_getPrice("URL") > this.balance) {
            LogNewOraclizeQuery("CreateGen0 query was NOT sent, please add some ETH to cover for the query fee");
            return false;
        } else {

            string memory str1 = '\n{"unicorn_blockchain_id":';
            string memory str2 = ',"type":';
            string memory str3 = ',"owner_blockchain_id":1}';
            //string memory str4 = '}';

            LogNewOraclizeQuery("CreateGen0 query was sent, standing by for the answer..");

            bytes32 queryId =
                oraclize_query("URL", "json(http://core.unicorngo.io/v1/unicorn/generate).chain",
                                strConcat(str1, uint2str(_unicornId), str2, uint2str(_type), str3), 400000);

            validIds[queryId] = _unicornId + 1; //for require validIds[hash] > 0
            return true;
        }
    }


    function setGasPrice(uint _newPrice) public onlyOwner {
        oraclize_setCustomGasPrice(_newPrice * 1 wei);
    }


    function isBlackBox() public pure returns (bool) {
        return true;
    }


    function transferEthersToDividendManager(uint _valueInFinney) onlyOwner public    {
        require(this.balance >= _valueInFinney * 1 finney);
        dividendManagerAddress.transfer(_valueInFinney);
        //FundsTransferred(dividendManagerAddress, _valueInFinney * 1 finney);
    }
}


contract BlackBoxInterface {
    function isBlackBox() public pure returns (bool);
    function createGen0(uint unicornId, uint typeId) public payable returns (bool);
    function genCore(uint unicornId, uint unicorn1_id, bytes gen1, uint unicorn2_id, bytes gen2) public payable returns (bool);
}



contract UnicornAccessControl {
    event Pause();
    event Unpause();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;
    address public managerAddress;
    address public communityAddress;

    bool public paused = false;

    mapping(address => bool) tournaments;//address 1 exists

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


    modifier onlyTournament() {
        require(tournaments[msg.sender]);
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


    function setTournament(address _newTournamentAddress) external onlyCommunity {
        require(_newTournamentAddress != address(0));
        tournaments[_newTournamentAddress] = true;
    }


    function delTournament(address _tournamentAddress) external onlyCommunity {
        require (tournaments[_tournamentAddress]);
        delete tournaments[_tournamentAddress];
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

        uint freezingEndTime;//TODO ????
        uint freezingTourEndTime;//TODO ????
        uint16 freezingIndex; //TODO ????

        string name;

        uint parent1_id;
        uint parent2_id;
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
//        address owner = unicornOwner[_unicornId];
//        require(owner != address(0));
//        return owner;
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
            Approval(msg.sender, _to, _unicornId);
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
        Transfer(_from, _to, _unicornId);
    }

    /**
    * @dev Internal function to clear current approval of a given unicorn ID
    * @param _unicornId uint256 ID of the unicorn to be transferred
    */
    function clearApproval(address _owner, uint256 _unicornId) private {
        require(owns(_owner, _unicornId));
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

    function _createUnicorn(address _owner, uint _parent1, uint _parent2) internal returns (uint)    {
        Unicorn memory _unicorn = Unicorn({
            gen : new bytes(1),
            birthTime : uint64(now),
            freezingEndTime : 0,
            freezingTourEndTime: 0,
            freezingIndex : 4,//TODO GET FROM GEN
            name: "",
            parent1_id: _parent1,
            parent2_id: _parent2
        });

        uint256 _unicornId = totalUnicorns;
        _mint(_owner, _unicornId, _unicorn);

        UnicornBirth(_owner, _unicornId);

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
    CandyCoinInterface public token; //SET on deploy

    uint public subFreezingPrice; //onlyCommunity price in CandyCoins
    uint public subFreezingTime; //onlyCommunity
    uint public dividendPercent; //OnlyManager 4 digits. 10.5% = 1050
    uint public createUnicornPrice; //OnlyManager price in weis
    uint public createUnicornPriceInCandy; //OnlyManager price in CandyCoin
    address public dividendManagerAddress; //onlyCommunity

    uint public gen0Count;

    uint public oraclizeFee;


    uint public lastHybridizationId;

    struct Hybridization{
        uint unicorn_id;
        uint price;
        uint second_unicorn_id;
        bool accepted;
        bool exists;
    }

    // Mapping from hybridization ID to Hybridization struct
    mapping (uint => Hybridization) public hybridizations;

    // Mapping from unicorn ID to list of it hybridization IDs
    mapping (uint => uint[]) private unicornHybridizations;

    // Mapping from hybridization ID to index of the unicorn ID hybridizations list
    mapping(uint => uint) private unicornHybridizationsIndex;

    modifier onlyBlackBox() {
        require(msg.sender == blackBoxAddress);
        _;
    }

    //fallback payable функция, на случай возврата эфира с девиденд-менеджера
    function() public payable {
    }

    function UnicornBreeding(address _token, address _dividendManagerAddress) public    {
        token = CandyCoinInterface(_token);
        dividendManagerAddress = _dividendManagerAddress;
        lastHybridizationId = 0;
        subFreezingPrice = 1000000000000000000;
        subFreezingTime = 5 minutes;
        dividendPercent = 375; //3.75%
        createUnicornPrice = 10000000000000000;
        createUnicornPriceInCandy = 1000000000000000000; //1 token
        oraclizeFee = 10000000000000000;
        gen0Count = 0;
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
    // думаю, не надо, пусть выставят хоть 100 раз,
    // может какой-то уникорн будет пользоваться гипер популярностью
    function makeHybridization(uint _unicornId, uint _price) public returns (uint) {
        require(owns(msg.sender, _unicornId));
        require(isReadyForHybridization(_unicornId));

        uint256 _hybridizationId = ++lastHybridizationId;
        Hybridization storage h = hybridizations[_hybridizationId];

        h.unicorn_id = _unicornId;
        h.price = _price;
        //it will be set by default
        //        h.second_unicorn_id = 0;
        //        h.accepted = false;
        h.exists = true;

        // save hybridization in mapping for unicorn
        uint256 newHIndex = unicornHybridizations[h.unicorn_id].length;
        unicornHybridizations[h.unicorn_id].push(_hybridizationId); //save hybridization ID in array
        unicornHybridizationsIndex[_hybridizationId] = newHIndex; //save index for hybridization
        //fire event
        HybridizationAdded(_hybridizationId, h.unicorn_id, h.price);

        return _hybridizationId;
    }

    function acceptHybridization(uint _hybridizationId, uint _unicornId) public payable {
        require(owns(msg.sender, _unicornId));

        Hybridization storage h = hybridizations[_hybridizationId];
        require(h.exists && !h.accepted);
        require(_unicornId != h.unicorn_id);

        //uint price = h.price.add(valueFromPercent(h.price,dividendPercent));

        require(msg.value == getHybridizationPrice(_hybridizationId));
        require(isReadyForHybridization(_unicornId));
        require(isReadyForHybridization(h.unicorn_id));

        h.second_unicorn_id = _unicornId;

        uint256 childUnicornId  = _createUnicorn(msg.sender,h.unicorn_id,h.second_unicorn_id);
        blackBoxContract.genCore.value(oraclizeFee)(childUnicornId, h.unicorn_id, unicorns[h.unicorn_id].gen,
                                                    h.second_unicorn_id, unicorns[h.second_unicorn_id].gen);

        address own = ownerOf(h.unicorn_id);
        own.transfer(h.price);

        _setFreezing(_unicornId);

        h.accepted = true;
        //fire event
        HybridizationAccepted(_hybridizationId, _unicornId, childUnicornId);
    }

    function cancelHybridization (uint _hybridizationId) public     {
        Hybridization storage h = hybridizations[_hybridizationId];
        require(owns(msg.sender, h.unicorn_id));
        require (h.exists && !h.accepted);

        //так нельзя, т.к. фронтенд может посчитать, что это выполненная гибридизация
        //h.accepted = true;


        // remove hybridization in mapping for unicorn
        uint256 hIndex = unicornHybridizationsIndex[_hybridizationId];
        uint256 lastHIndex = unicornHybridizations[h.unicorn_id].length;
        uint256 lastHId = unicornHybridizations[h.unicorn_id][lastHIndex];

        unicornHybridizations[h.unicorn_id][hIndex] = lastHId; //replace hybridization ID with last
        unicornHybridizations[h.unicorn_id][lastHIndex] = 0; //reset hybridization ID at last postion
        unicornHybridizations[h.unicorn_id].length--; //reduce array size
        //        unicornHybridizationsIndex[_hybridizationId] = 0; // reset hybridization ID index
        delete unicornHybridizationsIndex[_hybridizationId];
        unicornHybridizationsIndex[lastHId] = hIndex; //update index for last hybridization ID

        //удаляем бесполезную гибридизацию
        delete hybridizations[_hybridizationId];
        //fire event
        HybridizationCancelled(_hybridizationId);
        //TODO ?? delete hybridizations[hybridizationId]
        // да, зачем ее хранить?
    }

    // Gets the list of hybridizations of unicorn
    function hybridizationsOf(uint _unicornId) public view returns (uint256[]) {
        return unicornHybridizations[_unicornId];
    }


    //Create new 0 gen
    function createUnicorn() public payable returns(uint256)   {
        require(gen0Count <= 30000);
        require(msg.value == getCreateUnicornPrice());

        //oraclizeFeeAmount = oraclizeFeeAmount.add(oraclizeFee);

        uint256 newUnicornId = _createUnicorn(msg.sender,0,0);

        gen0Count = gen0Count.add(1);

        if (!blackBoxContract.createGen0.value(oraclizeFee)(newUnicornId,0)) {
            revert();
        }

        CreateUnicorn(msg.sender,newUnicornId);
        return newUnicornId;
    }


    function createUnicornForCandy() public returns(uint256)   {
        require(gen0Count <= 30000);
        //without oraclize fee
        require(token.allowance(msg.sender, this) >= createUnicornPriceInCandy);
        require(token.transferFrom(msg.sender, this, createUnicornPriceInCandy));

        uint256 newUnicornId = _createUnicorn(msg.sender,0,0);

        gen0Count = gen0Count.add(1);

        blackBoxContract.createGen0(newUnicornId,0);

        CreateUnicorn(msg.sender,newUnicornId);
        return newUnicornId;
    }


    //Create new 0 gen
    function createPresaleUnicorn(address _owner, uint _type) public payable onlyManager returns(uint256)   {
        require(gen0Count <= 30000);
        //TODO require rare counter
        require(msg.value == oraclizeFee);

        uint256 newUnicornId = _createUnicorn(_owner,0,0);

        gen0Count = gen0Count.add(1);

        if (!blackBoxContract.createGen0.value(oraclizeFee)(newUnicornId,_type)) {
            revert();
        }

        CreateUnicorn(msg.sender,newUnicornId);
        return newUnicornId;
    }


    function isReadyForHybridization(uint _unicornId) public view returns (bool)    {
        return (unicorns[_unicornId].freezingEndTime <= uint64(now));
    }


    //change freezing time for candy
    function minusFreezingTime(uint _unicornId) public    {
        require(token.allowance(msg.sender, this) >= subFreezingPrice);
        require(token.transferFrom(msg.sender, this, subFreezingPrice));

        Unicorn storage unicorn = unicorns[_unicornId];

        unicorn.freezingEndTime = unicorn.freezingEndTime.sub(subFreezingTime);
    }


    //TODO
    function _setFreezing(uint _unicornId) internal {
        Unicorn storage unicorn = unicorns[_unicornId];

        unicorn.freezingEndTime = uint64((freezing[unicorn.freezingIndex]) + uint64(now));
    }


    function _setTourFreezing(uint _unicornId) public onlyTournament   {
        Unicorn storage unicorn = unicorns[_unicornId];

        unicorn.freezingTourEndTime = uint64((freezing[unicorn.freezingIndex]) + uint64(now));
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
    function setCreateUnicornPrice(uint _newPrice, uint _candyPrice) public onlyManager    {
        createUnicornPrice = _newPrice;
        createUnicornPriceInCandy = _candyPrice;
    }

    //in weis
    function setOraclizeFee(uint _newFee) public onlyManager    {
        oraclizeFee = _newFee;
    }

    function getHybridizationPrice(uint _hybridizationId) public view returns (uint) {
        Hybridization storage h = hybridizations[_hybridizationId];
        require(h.exists);
        uint price = h.price.add(valueFromPercent(h.price,dividendPercent)).add(oraclizeFee);
        return price;
    }

    function getCreateUnicornPrice() public view returns (uint) {
        uint price = createUnicornPrice.add(oraclizeFee);
        return price;
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


    function setGen(uint _unicornId, bytes _gen) onlyBlackBox public {
        unicorns[_unicornId].gen = _gen;
    }


    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns(uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }

}




contract Crowdsale {

    Unicorn public token;

    mapping (uint256 => uint256) public prices; // if prices[id] = 0 then not for sale

    event UnicornPurchase( address indexed beneficiary, uint256 unicornId);
    event UnicornSale( address indexed beneficiary, uint256 unicornId);

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
        //UnicornPurchase(msg.sender, unicornId);

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
        UnicornSale(msg.sender, unicornId);
    }

}


