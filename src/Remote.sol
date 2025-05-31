// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

// The import is used in the @inheritdoc, false positive
// solhint-disable-next-line no-unused-import
import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ModuleManager} from "./base/ModuleManager.sol";
import {Safe, Enum} from "./Safe.sol";

/**
 * @title Remote - A Safe contract implementation with cross-chain functionality via LayerZero and Stargate.
 * @notice Built during ETHGlobal Prague Hackathon 2025.
 */

contract Remote is Safe, ILayerZeroComposer {
    using OptionsBuilder for bytes;
    using ECDSA for bytes32;

    address public endpointAddress;
    address public portalRouterAddress;
    address public owner;
    uint256 public stargateFee;
    bool private initialized;

    mapping(address => bool) public isStargate;
    mapping(address => address) public stargateToToken;

    function init(
        address _owner,
        address _endpointAddress,
        address[] memory _stargateAddresses,
        address[] memory _tokenAddresses,
        address _portalRouterAddress,
        uint256 _stargateFee
    ) external {
        require(!initialized, "Already initialized");
        
        endpointAddress = _endpointAddress;
        portalRouterAddress = _portalRouterAddress;
        owner = _owner;
        stargateFee = _stargateFee;
        for (uint256 i = 0; i < _stargateAddresses.length; i++) {
            isStargate[_stargateAddresses[i]] = true;
            stargateToToken[_stargateAddresses[i]] = _tokenAddresses[i];
        }
        
        initialized = true;
    }

    function setStargateFee(uint256 _stargateFee) external {
        //require(msg.sender == owner, "!owner");
        stargateFee = _stargateFee;
    }

    function prepare(
        address _stargate,
        uint32 _dstEid,
        uint256 _amount,
        address _composer,
        bytes memory _composeMsg,
        uint256 _composeFunctionGasLimit
    )
        external
        view
        returns (
            uint256 valueToSend,
            SendParam memory sendParam,
            MessagingFee memory messagingFee
        )
    {
        return _prepare(_stargate, _dstEid, _amount, _composer, _composeMsg, _composeFunctionGasLimit);
    }

    function executeBatchStargate(
        address[] memory _stargateAddresses,
        SendParam[] memory _sendParams,
        MessagingFee[] memory _messagingFees,
        uint256[] memory _nativeAmounts
    ) external payable {
        require(msg.sender == owner, "!owner");
       for (uint256 i = 0; i < _stargateAddresses.length; i++) {
            _executeStargate(_stargateAddresses[i], _sendParams[i], _messagingFees[i], _nativeAmounts[i], msg.sender, true);
       }
    }

    function executeStargate(
        address _stargate,
        SendParam memory _sendParam,
        MessagingFee memory _messagingFee,
        uint256 _nativeAmount
    ) external payable {
        require(msg.sender == owner, "!owner"); 
        _executeStargate(_stargate, _sendParam, _messagingFee, _nativeAmount, msg.sender, true);
    }

    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable {
        require(isStargate[_from], "!stargate");
        require(msg.sender == endpointAddress, "!endpoint");

        address tokenAddress = stargateToToken[_from];
        //require(tokenAddress != address(0), "!token");

        uint256 amountLD = OFTComposeMsgCodec.amountLD(_message);
        bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);

        address _composeFrom = address(uint160(uint256(OFTComposeMsgCodec.composeFrom(_message))));
        require(_composeFrom == owner || _composeFrom == address(this), "!owner");

        (
            address _token,
            address _stargate,
            uint32 _dstEid,
            bool isDeposit,
            uint256 _amount,
            bytes memory _data
        ) = abi.decode(_composeMessage, (address, address, uint32, bool, uint256, bytes));

        if (isDeposit) {
            _handleDeposit(tokenAddress, amountLD, _data);
        } else {
            _handleWithdrawal(_token, _stargate, _dstEid, _amount, _data, tokenAddress);
        }
    }

    function _handleDeposit(
        address tokenAddress,
        uint256 amountLD,
        bytes memory _data
    ) internal {
        if (tokenAddress != address(0)) {
        // execute approve with function signature
        (bool approveSuccess,) = tokenAddress.call(abi.encodeWithSignature("approve(address,uint256)", portalRouterAddress, amountLD));
        require(approveSuccess, "Approve failed");

        // execute transaction with function signature
        (bool success,) = portalRouterAddress.call(_data);
        require(success, "Deposit failed");
        } else {
            //execute transaction with function signature
            (bool success,) = portalRouterAddress.call{value: amountLD }(_data);
            require(success, "Deposit failed");
        }
    }

    function _handleWithdrawal(
        address _token, //token to withdraw
        address _stargate,
        uint32 _dstEid,
        uint256 _amount,
        bytes memory _data,
        address tokenAddress //token 
    ) internal {
        // Approve and execute withdrawal
        (bool approveSuccess,) = _token.call(abi.encodeWithSignature("approve(address,uint256)", portalRouterAddress, _amount));
        require(approveSuccess, "Approve failed");

        (bool success,) = portalRouterAddress.call(_data);
        require(success, "Deposit failed");

        // Execute stargate transfer
        _executeStargateTransfer(_stargate, _dstEid, address(this).balance, tokenAddress);
    }


    function _executeStargateTransfer(
        address _stargate,
        uint32 _dstEid,
        uint256 finalAmount,
        address tokenAddress
    ) internal {

        uint256 amount = finalAmount - (finalAmount * stargateFee / 100000); //1%  //TODO: remove this

        // Prepare stargate send param
        (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) = _prepare(
            _stargate,
            _dstEid,
            amount,
            address(this),
            hex"00", //message to compose
            1000000 //1m gas limit
        );

        // Execute stargate
        _executeStargate(_stargate, sendParam, messagingFee, valueToSend, msg.sender, false);
    }

    function _prepare(
        address _stargate,
        uint32 _dstEid,
        uint256 _amount,
        address _composer,
        bytes memory _composeMsg,
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
                0, 
                uint128(_composeFunctionGasLimit), 
                0 
            ) 
            : bytes("");

        sendParam = SendParam({
            dstEid: _dstEid,
            to: _addressToBytes32(_composer),
            amountLD: _amount, 
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

    function _executeStargate(
        address _stargate,
        SendParam memory _sendParam,
        MessagingFee memory _messagingFee,
        uint256 _nativeAmount,  
        address _from,
        bool _isDeposit
    ) internal {
        address tokenAddress = stargateToToken[_stargate];
        //require(tokenAddress != address(0), "!token"); //TODO: remove this
        if (_isDeposit) {   
        
            (bool transferSuccess,) = tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, address(this), _sendParam.amountLD));
            require(transferSuccess, "Transfer failed");
        }
        if (tokenAddress != address(0)) {
        //approve the token to the stargate
        (bool approveSuccess,) = tokenAddress.call(abi.encodeWithSignature("approve(address,uint256)", _stargate, _sendParam.amountLD));
        require(approveSuccess, "Approve failed");

        IStargate stargate = IStargate(_stargate);
        stargate.sendToken(_sendParam, _messagingFee, address(this)); 
        } 
        else {
            IStargate stargate = IStargate(_stargate);
            stargate.sendToken{value: _nativeAmount}(_sendParam, _messagingFee, address(this));
        }
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

}


