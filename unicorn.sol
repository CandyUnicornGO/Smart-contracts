pragma solidity ^0.4.18;


contract ERC721 {
    // ERC20 compatible functions
    //function name() constant returns (string name);
    //function symbol() constant returns (string symbol);
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    // Functions that define ownership
    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function allowance(address _claimant, uint256 _tokenId) public view returns (bool);
    //TODO function takeOwnership(uint256 _tokenId);
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    //function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId);
    // Token metadata
    //function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);
    // Events
    //event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}


contract UnicornBase {

    event Birth(address owner, uint256 unicornId, uint256 genes);

    event Transfer(address from, address to, uint256 tokenId);

    struct Unicorn {
        uint256 genes;
        uint64 birthTime;
    }

    Unicorn[] unicorns;

    mapping (uint256 => address) public unicornIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public unicornIndexToApproved;
    mapping(address => mapping(uint256 => uint256)) private ownerTokens;



    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        unicornIndexToOwner[_tokenId] = _to;
        // When creating new kittens _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete unicornIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    function _createUnicorn(uint256 _genes, address _owner) internal returns (uint)
    {
        Unicorn memory _unicorn = Unicorn({
            genes: _genes,
            birthTime: uint64(now)
            });

        uint256 newUnicornId = unicorns.push(_unicorn) - 1;

        require(newUnicornId == uint256(uint32(newUnicornId)));

        Birth(_owner,newUnicornId,_genes);

        _transfer(0, _owner, newUnicornId);

        return newUnicornId;
    }
}


contract UnicornOwnership is UnicornBase, ERC721 {

    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return unicornIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return unicornIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        unicornIndexToApproved[_tokenId] = _approved;
    }

    function allowance(address _claimant, uint256 _tokenId) public view returns (bool) {
        return _approvedFor(_claimant,_tokenId);
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _tokenId) public
    {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }


    function approve(address _to, uint256 _tokenId) public
    {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public
    {
        require(_to != address(0));
        require(_to != address(this));

        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }


    function totalSupply() public constant returns (uint) {
        return unicorns.length;
    }


    function ownerOf(uint256 _tokenId) public constant returns (address owner)
    {
        owner = unicornIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    //function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId)
    //{
    // return ownerTokens[_owner][_index];
    //}



}

contract UnicornBreeding is UnicornOwnership {

    function newBirth(address _owner) public returns(uint256)
    {
        uint256 genes = createGen();
        uint256 unicornId = _createUnicorn(genes, _owner);
        return unicornId;
    }

    function createGen()  internal pure returns(uint256) {
        return 1;
    }
}

contract Crowdsale {
    UnicornBreeding public token;

    uint price = 100000000000000000;

    event TokenPurchase( address indexed beneficiary, uint256 unicornId);
    event TokenSale( address indexed beneficiary, uint256 unicornId);

    function Crowdsale(address _token) public {
        token = UnicornBreeding(_token);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value == price);

        uint unicornId = token.newBirth(beneficiary);
        TokenPurchase(msg.sender, unicornId);

        //forwardFunds();
    }

    function buyUnicorn(uint unicornId) public payable {
        require(msg.value == price);
        address own = token.ownerOf(unicornId);
        require(token.allowance(this,unicornId));
        token.transferFrom(own, msg.sender,unicornId);
        own.transfer(msg.value);
        TokenSale(msg.sender, unicornId);
    }
    
}
