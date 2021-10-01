pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20Basic.sol";

contract OMS {

    address public oms;
    //  mapping para relacionar centros de salud con validez del sistema de gestion
    mapping(address => bool) isAvailableByOMS;
    mapping(address => address) public healthCenterContractMapping;
    address[] public healthContractAddressList;
    address[] requestList;

    constructor () public {
        oms = msg.sender;
    }

    event newAvailableContractEvent(address);
    event newContractEvent(address, address);
    event accessRequestEvent(address);

    modifier onlyExecuteByOMS(address generalAddress) {
        require(generalAddress == oms, "Denied, dont have permission to execute");
        _;
    }

    function accessRequest() public {
        requestList.push(msg.sender);
        emit accessRequestEvent(msg.sender);
    }

    function retrieveAccessRequest() public view onlyExecute(msg.sender) returns (address[] memory) {
        return requestList;
    }

    function createNewHealthCentral(address healthCenterAddress) public onlyExecute(msg.sender) {
        isAvailableByOMS[healthCenterAddress] = true;
        emit newAvailableContractEvent(healthCenterAddress);
    }

    function healthCenterFactory() public {
        require(isAvailableByOMS[msg.sender] == true, "Denied, dont have permission to execute");
        address newHealthCenter = address(new HealthCenter(msg.sender));
        healthContractAddressList.push(newHealthCenter);
        //  relacion entre centro de salud y direccion de contrato
        healthCenterContractMapping[msg.sender] = newHealthCenter;
        emit newContractEvent(newHealthCenter, msg.sender);
    }
}

contract HealthCenter {

    address public contractAddress;
    address public healthCenterAddress;
    /*mapping(bytes32 => bool) covidResultMapping;
    mapping(bytes32 => string) ipfsCovidResultMapping;*/
    mapping(bytes32 => CovidResultStruct) CovidResultMapping;

    struct CovidResultStruct {
        bool diagnostic;
        string ipfsCode;
    }

    event newCovidResultEvent(string, bool);

    constructor (address healthCenterAddress) public {
        healthCenterAddress = healthCenterAddress;
        contractAddress = address(this);
    }

    modifier onlyExecuteByHealthCenter(address requireAddress) {
        require(requireAddress == healthCenterAddress, "Denied, dont have permission to execute");
        _;
    }

    function covidResultTest(string memory idPerson,
        bool resultCovid, string memory ipfsCode) public onlyExecuteByHealthCenter(msg.sender) {
        //  hash del id
        bytes32 hashIdPerson = keccak256(abi.encodePacked(idPerson));
        /*covidResultMapping[hashIdPerson] = resultCovid;
        ipfsCovidResultMapping[hashIdPerson] = ipfsCode;*/
        CovidResultMapping[hashIdPerson] = CovidResultStruct(resultCovid, ipfsCode);
        emit newCovidResultEvent(ipfsCode, resultCovid);
    }

    function retrieveResultsCovid(
        string memory idPerson) public view returns (string memory _testResult, string memory ipfsCode) {
        //  hash de la persona
        bytes32 hashIdPerson = keccak256(abi.encodePacked(idPerson));
        string memory testResult;
        if (CovidResultMapping[hashIdPerson].diagnostic == true) {
            testResult = "Positivo";
        } else {
            testResult = "Negativo";
        }
        _testResult = testResult;
        ipfsCode = CovidResultMapping[hashIdPerson].ipfsCode;
    }
}