* контракт BlackBoxController
  - event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  - event logRes(string res); - для тестов, уберем
  - event LogNewOraclizeQuery(string description); - собитие ораклиза, не несет полезной информации, надо заменить на что-то другое

* contract UnicornBreeding 
    address public owner;
    address public managerAddress;
    address public communityAddress;

    bool public paused = false;

    mapping(address => bool) tournaments;//address 1 exists
    
     uint32[14] public freezing = [];


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
        bytes32 hash;
    }

    mapping (uint => Hybridization) public hybridizations;


  - event Pause(); - не импользуется
  - event Unpause(); - не используется

  - event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  - event Transfer(address indexed _from, address indexed _to, uint256 _unicornId);  - стандартный event ERC721
  - event Approval(address indexed _owner, address indexed _approved, uint256 _unicornId); - стандартный event ERC721
        
  - event HybridizationAdded(uint indexed lastHybridizationId, uint indexed UnicornId, uint price);
  - event HybridizationAccepted(uint indexed HybridizationId, uint indexed UnicornId, uint  NewUnicornId);
  - event HybridizationCancelled(uint indexed HybridizationId);
  - event FundsTransferred(address dividendManager, uint value); - перечисление средств на didvidendmanager
  - event CreateUnicorn(address indexed owner, uint indexed UnicornId); - создание уникорна
  - event UnicornBirth(address owner, uint256 unicornId); - по логике дублирует CreateUnicorn - можно убрать 
      
* contract Crowdsale 
  - в работе
  
* contract UnicornDividendToken
  - стандарт ERC20
  
* contract DividendManager
  - нет, возможно сделать публичным адрес двивдент токена