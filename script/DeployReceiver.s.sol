// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {Receiver} from "../src/Receiver.sol";
import {ENDPOINT, SEPOLIA_STARGATE, SEPOLIA_AAVE_WRAPPED_TOKEN} from "./Constants.sol";

import {WrappedTokenGatewayV3} from "aave-v3/helpers/WrappedTokenGatewayV3.sol";

// deploy on sepolia
contract DeployReceiver is Script {
    Receiver public receiver;

    uint256 internal deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
    address deployerAddr = vm.addr(deployerPrivateKey);

    function setUp() public {}

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        console.log("deployer balance", deployerAddr.balance, deployerAddr);

        // deploy receiver on arbitrum
        receiver = new Receiver(
            SEPOLIA_AAVE_WRAPPED_TOKEN,
            ENDPOINT,
            SEPOLIA_STARGATE
        );

        vm.stopBroadcast();
    }
}
