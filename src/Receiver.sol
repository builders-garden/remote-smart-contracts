// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

import {WrappedTokenGatewayV3} from "aave-v3/helpers/WrappedTokenGatewayV3.sol";

contract Receiver is ILayerZeroComposer {
    WrappedTokenGatewayV3 public immutable aaveWETHGateway;
    address public immutable endpoint;
    address public immutable stargate;

    event ReceivedOnDestination(address sender, address executor, address from);

    event ReceivedOnSource(
        address _tokenReceiver,
        address _oftOnDestination,
        address _tokenOut,
        uint _amountOutMinDest,
        uint _deadline
    );

    constructor(
        address _aaveWETHGateway,
        address _endpoint,
        address _stargate
    ) {
        aaveWETHGateway = WrappedTokenGatewayV3(payable((_aaveWETHGateway)));
        endpoint = _endpoint;
        stargate = _stargate;
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

        uint256 amountLD = OFTComposeMsgCodec.amountLD(_message);
        bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);

        address _to = abi.decode(_composeMessage, (address));

        // deposit eth on aave weth gateway
        aaveWETHGateway.depositETH{value: amountLD}(address(0), _to, 0);
    }

    fallback() external payable {}

    receive() external payable {}
}
