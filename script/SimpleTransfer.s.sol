// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimpleTransfer
 * @dev Simple script to transfer tokens and ETH - just hardcode what you need
 */
contract SimpleTransfer is Script {
    
    // HARDCODE THESE VALUES
    address constant RECIPIENT = 0x0000000000000000000000000000000000000000; // Change this
    uint256 constant ETH_AMOUNT = 0.001 ether; // Change this
    uint256 constant USDC_AMOUNT = 1e6; // 100 USDC (6 decimals)
    uint256 constant WETH_AMOUNT = 0.001 ether; // Change this
    
    // Token addresses - update for your chain
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base USDC
    address constant WETH = 0x4200000000000000000000000000000000000006; // Base WETH
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
   
        payable(RECIPIENT).transfer(ETH_AMOUNT);
        console.log("Transferred ETH:", ETH_AMOUNT);
    
        IERC20(USDC).transfer(RECIPIENT, USDC_AMOUNT);
        console.log("Transferred USDC:", USDC_AMOUNT);
    
        IERC20(WETH).transfer(RECIPIENT, WETH_AMOUNT);
        console.log("Transferred WETH:", WETH_AMOUNT);
    
    
        vm.stopBroadcast();
        console.log("Done!");
    }
} 