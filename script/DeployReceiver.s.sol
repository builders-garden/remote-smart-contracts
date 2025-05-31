/* // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {Remote} from "../src/Remote.sol";
import {BASE_ENDPOINT, BASE_STARGATE_POOL_ETH} from "./Constants.sol";
// deploy on arbitrum-sepolia
contract DeployReceiver is Script {
    Remote public remote;

    uint256 internal deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
    address deployerAddr = vm.addr(deployerPrivateKey);

    function setUp() public {}

    function run() public {
        console.log("Deploying on Arbitrum Sepolia");
        console.log("Deployer address:", deployerAddr);
        console.log("Deployer balance:", deployerAddr.balance);

        vm.startBroadcast(deployerPrivateKey);


        console.log("remote deployed at:", address(remote));

        vm.stopBroadcast();
    }
}
 */