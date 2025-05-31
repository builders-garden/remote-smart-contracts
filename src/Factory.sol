// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title Create2Factory
 * @dev Factory contract for deploying contracts using CREATE2 opcode
 * @notice This contract allows for deterministic contract deployment
 */
interface IRemote{

    function init(
        address _endpointAddress,
        address[] memory _stargateAddresses,
        address[] memory _tokenAddresses,
        address _portalRouterAddress
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
    address public localWeth;
    bytes public implBytecode;

    constructor(address _stargate, address _endpoint, address _localWeth) {
        stargate = _stargate;
        endpoint = _endpoint;
        localWeth = _localWeth;
    }

    function initializeSmartAccount(
        address[] memory _stargateAddresses,
        address[] memory _tokenAddresses,
        address _portalRouterAddress,
        address owner
    ) internal {
        address deployedAddress = deploy(owner);
        account[owner]=deployedAddress;
        IRemote(deployedAddress).init(
            endpoint,
            _stargateAddresses,
            _tokenAddresses,
            _portalRouterAddress
        );
    }

    function getAccount(address owner) external view returns (address)  {
        return account[owner];
    }


    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable {
        require(_from == stargate, "!stargate");
        require(msg.sender == endpoint, "!endpoint");
  
        bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);

        address scTxOrigin = address(uint160(uint(OFTComposeMsgCodec.composeFrom(_message))));
        
        address deployedAddress = deploy(scTxOrigin);
        account[scTxOrigin] = deployedAddress;
        
        (   
            address[] memory stargateAddresses,
            address[] memory tokenAddresses, 
            address portalRouterAddress
        ) = abi.decode(_composeMessage, (address[], address[], address));
        

        initializeSmartAccount(stargateAddresses, tokenAddresses, portalRouterAddress, scTxOrigin);

    }       


    function crosschainDeploy(
        uint32[] memory _destId, 
        address[] memory _stargates, 
        address[] memory _tokenAddresses, 
        address[] memory _portalRouter, 
        uint lesserRequiredAmount
    ) external {
        uint256 valueToSend;
        SendParam memory sendParam;
        MessagingFee memory messagingFee;

        address[] memory stargatesToCompose = new address[](2);
        address[] memory addressesToCompose = new address[](2);

        for (uint i; i < _destId.length; ++i){
   
        stargatesToCompose[0] = _stargates[i];
        stargatesToCompose[1] = _stargates[i+1];
        
        addressesToCompose[0] = _tokenAddresses[i];
        addressesToCompose[1] = _tokenAddresses[i+1];

        bytes memory _composeMsg = abi.encode(
           stargatesToCompose, addressesToCompose, _portalRouter[i]
        ); 
        

        (
            valueToSend,
            sendParam,
            messagingFee
        ) = prepare(_stargates[i], _destId[i], lesserRequiredAmount,  address(this), _composeMsg, 500_000);

        IERC20(localWeth).approve(_stargates[i], lesserRequiredAmount);

        IStargate(_stargates[i]).sendToken{value: valueToSend}(
            sendParam,
            messagingFee,
            address(this)
        );

            account[msg.sender] = deploy(msg.sender);  
        }


    }




    function prepare(
        address _stargate,
        uint32 _dstEid,
        uint256 _amount,
        address _composer,
        bytes memory _composeMsg, // abi encoded elements for the compose call
        uint256 _composeFunctionGasLimit
    )
        internal
        view
        returns (
            uint256 valueToSend,
            SendParam memory sendParam,
            MessagingFee memory messagingFee
        )
    {
        bytes memory extraOptions = _composeMsg.length > 0
            ? OptionsBuilder.newOptions().addExecutorLzComposeOption(
                0, // compose call function index
                uint128(_composeFunctionGasLimit), // compose function gas limit
                0 // compose function msg value
            ) // compose gas limit
            : bytes("");

        sendParam = SendParam({
            dstEid: _dstEid,
            to: addressToBytes32(_composer),
            amountLD: _amount, // amount to send
            minAmountLD: _amount,
            extraOptions: extraOptions,
            composeMsg: _composeMsg,
            oftCmd: ""
        });

        IStargate stargate = IStargate(_stargate);

        (, , OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
        sendParam.minAmountLD = receipt.amountReceivedLD;

        messagingFee = stargate.quoteSend(sendParam, false); // get the fee (stgFee and lzFee)
        valueToSend = messagingFee.nativeFee; // add the stargate fee to the value

        if (stargate.token() == address(0x0)) {
            valueToSend += sendParam.amountLD; // add the amount to send to the value
        }
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /**
     * @dev Deploys a contract using CREATE2
     * @param owner The owner address to use as salt
     * @return deployedAddress The address of the deployed contract
     */
    function deploy(
        address owner
    ) internal returns (address deployedAddress) {

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
    }


    fallback() external payable {}

    receive() external payable {}
    
}

