// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";

import {MessagingFee, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import {Script, console} from "forge-std/Script.sol";

import {Receiver} from "../src/Receiver.sol";
import {StargateComposer} from "../src/StargateComposer.sol";
import {ENDPOINT, SEPOLIA_STARGATE, SEPOLIA_CHAIN_EID, OPT_CHAIN_EID} from "./Constants.sol";

// sent eth from source to destination
contract TransferEth is Script {
    StargateComposer public stargateComposer;

    uint256 internal deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
    address deployerAddr = vm.addr(deployerPrivateKey);

    uint32 internal sourceChainEID = SEPOLIA_CHAIN_EID;
    uint32 internal destinationChainEID = OPT_CHAIN_EID;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        // ! fill with the deployed addresses
        stargateComposer = StargateComposer(
            0x285aE9Ccf043252203C43C65FAcCE36aF08258C3 // address on sepolia
        );

        bytes memory _composeMsg;

        (
            uint256 valueToSend,
            SendParam memory sendParam,
            MessagingFee memory messagingFee
        ) = stargateComposer.prepare(
                SEPOLIA_STARGATE, // stargate
                destinationChainEID, // destinationEndpointId
                0.02 ether, // amount
                address(deployerAddr), // to
                _composeMsg, // composeMsg
                200_000 // composeFunctionGasLimit
            );

        IStargate(SEPOLIA_STARGATE).sendToken{value: valueToSend}(
            sendParam,
            messagingFee,
            deployerAddr
        );

        vm.stopBroadcast();
    }
}
