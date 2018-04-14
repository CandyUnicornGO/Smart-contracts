pragma solidity 0.4.21;

contract UnicornManagementInterface {
    function blackBoxAddress() external view returns (address);
    //service
//    function registerInit(address _contract) external;
}


contract UnicornAccessControl {
    UnicornManagementInterface public unicornManagement;

    function UnicornAccessControl(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
//        unicornManagement.registerInit(this);
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }
}

contract UnicornFamilyTree is UnicornAccessControl {
    struct UnicornAncestors {
        uint parent1Id;
        uint parent2Id;
    }
    mapping(uint => UnicornAncestors) public unicornAncestors;
    function UnicornFamilyTree(address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {}

//    function init() onlyManagement external view {}

    function setAncestors(uint unicornId, uint parent1Id, uint parent2Id) external onlyBlackBox {
        unicornAncestors[unicornId] = UnicornAncestors({
            parent1Id:parent1Id,
            parent2Id:parent2Id
        });
    }
    function () external {}
}
