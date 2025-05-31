/* // SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Factory.sol";
import {FLOW_STARGATE_OFT_ETH, BASE_STARGATE_POOL_NATIVE, FLOW_CHAIN_EID, BASE_CHAIN_EID} from "./Constants.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrosschainDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
       
        address payable factoryAddress = payable(0x97E4dE257Cc9121210aF34339557ccE8eB7Bc08F);

        vm.startBroadcast(deployerPrivateKey);

        // Get the factory contract instance
        Create2Factory factory = Create2Factory(factoryAddress);

        // Configuration for multiple chains
        uint32[] memory destIds = new uint32[](2);
        destIds[0] = BASE_CHAIN_EID;  // Base
        destIds[1] = FLOW_CHAIN_EID;  // Flow

        address[] memory stargates = new address[](2);
        stargates[0] = 0xdc181Bd607330aeeBEF6ea62e03e5e1Fb4B6F7C7; // Base Stargate
        stargates[1] = 0x45f1A95A4D3f3836523F5c83673c797f4d4d263B; // Flow Stargate

        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = 0x0000000000000000000000000000000000000000; // Native ETH
        tokenAddresses[1] = 0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590; // Flow WETH

        address[] memory portalRouters = new address[](2);
        portalRouters[0] = 0x3c2269811836af69497E5F486A85D7316753cf62; // Base Router
        portalRouters[1] = 0x3c2269811836af69497E5F486A85D7316753cf62; // Flow Router

        uint256 lesserRequiredAmount = 1e13; // 0.00001 ETH

        // Approve tokens before calling (only for non-native tokens)
        IERC20(0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590).approve(
            address(factory), 
            lesserRequiredAmount * destIds.length // Approve enough for all destinations
        );

        // Calculate total ETH needed for the transaction
        uint256 totalEthNeeded = 0;
        for (uint256 i = 0; i < destIds.length; i++) {
            // You might want to call prepare() here to get exact values
            totalEthNeeded += 1e15; // Estimate, adjust based on actual prepare() results
        }

        // Call crosschainDeploy with the correct parameters
        factory.crosschainDeploy{value: totalEthNeeded}(
            destIds,
            stargates,
            tokenAddresses,
            portalRouters,  // ✅ Now passing the full array
            lesserRequiredAmount
        );

        console.log("Crosschain deployment completed successfully!");

        vm.stopBroadcast();
    }
} */