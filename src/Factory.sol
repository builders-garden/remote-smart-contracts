// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Remote} from "./Remote.sol";

/**
 * @title Create2Factory
 * @dev Factory contract for deploying contracts using CREATE2 opcode
 * @notice This contract allows for deterministic contract deployment
 */
interface IRemote{

    function init(
        address _owner,
        address _endpointAddress,
        address[] memory _stargateAddresses,
        address[] memory _tokenAddresses,
        address _portalRouterAddress,
        uint256 _stargateFee
    ) external;
}

contract Create2Factory {
    using OptionsBuilder for bytes;
    // Events
    event ContractDeployed(address indexed deployedAddress, bytes32 indexed salt);
    event DeploymentFailed(bytes32 indexed salt, string reason);

    mapping(address owner=>address smartAccount) internal account;
    address public stargate;
    address public endpoint;
    address[] public stargateAddresses;
    address[] tokenAddresses;
    address public portalRouter;
    bytes public implBytecode;
    uint public stargateFee;


    constructor(
        address _stargate, 
        address _endpoint, 
        address[] memory _stargateAddresses, 
        address[] memory _tokenAddresses,  
        address _portalRouter, 
        uint256 _stargateFee,
        bytes memory _implBytecode
    ) {
        stargate = _stargate;
        endpoint = _endpoint;
        stargateAddresses = _stargateAddresses;
        tokenAddresses = _tokenAddresses;
        stargateFee = _stargateFee;
        portalRouter = _portalRouter;
        implBytecode = _implBytecode;
    }

   
    function getAccount(address owner) external view returns (address)  {
        return account[owner];
    }

    function setBytecode(bytes memory _implBytecode) external {
        implBytecode = _implBytecode;
    }


    /*
     * @dev Deploys a contract using CREATE2
     * @param owner The owner address to use as salt
     * @return deployedAddress The address of the deployed contract
     */
    function deploy(
        address owner
    ) public returns (address deployedAddress) /*OnlySigner*/ {

        // Create salt from msg.sender
        bytes32 salt = bytes32(uint256(uint160(owner)));
        bytes memory bytecode = implBytecode;
        // Deploy the contract using CREATE2
        assembly {
            deployedAddress := create2(
                0, // value
                add(bytecode, 0x20), // start of bytecode
                mload(bytecode), // length of bytecode
                salt // salt
            )
        }

        require(deployedAddress != address(0), "Create2Factory: deployment failed");
        emit ContractDeployed(deployedAddress, salt);

        IRemote(deployedAddress).init(
            owner,
            endpoint,
            stargateAddresses,
            tokenAddresses,
            portalRouter,
            stargateFee
        );

    }
 
    
}

