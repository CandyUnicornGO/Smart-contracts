* контракт BlackBoxController
  - event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  - event logRes(string res); - для тестов, уберем
  - event LogNewOraclizeQuery(string description); - собитие ораклиза, не несет полезной информации, надо заменить на что-то другое

* contract UnicornBreeding 
  - event GamePaused();
  - event GameResumed();

  - event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  - event Transfer(address indexed _from, address indexed _to, uint256 _unicornId);  - стандартный event ERC721
  - event Approval(address indexed _owner, address indexed _approved, uint256 _unicornId); - стандартный event ERC721
        
  - event HybridizationAdded(uint indexed lastHybridizationId, uint indexed unicornId, uint price);
  - event HybridizationAccepted(uint indexed hybridizationId, uint indexed unicornId, uint newUnicornId);
  - event HybridizationCancelled(uint indexed hybridizationId);  - event FundsTransferred(address dividendManager, uint value); - перечисление средств на didvidendmanager
  - event CreateUnicorn(address indexed owner, uint indexed UnicornId); - создание уникорна
  - event UnicornGeneSet(uint indexed unicornId); - установлен ген 
      
* contract Crowdsale
  - event NewOffer(address indexed beneficiary, uint256 unicornId, uint price);
  - event UnicornSold(address indexed newOwner, uint256 unicornId);
  - event FundsTransferred(address dividendManager, uint value); 
  
* contract UnicornDividendToken
  - event Transfer(address indexed from, address indexed to, uint256 value);
  - event Approval(address indexed owner, address indexed spender, uint256 value);
  
* contract DividendManager
  - нет  