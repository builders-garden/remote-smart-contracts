// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Factory.sol";

contract CallDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = 0x12ee277c6C2c0E034210Db980FB9856330d66588;
        address ownerAddress = 0x69EF5048F40b66727aBC0F8B5EAf1eC2C31fDaEc;
        vm.startBroadcast(deployerPrivateKey);

        // Get the factory contract instance
        Create2Factory factory = Create2Factory(factoryAddress);

        // Call the deploy function
        address deployedRemote = factory.deploy(ownerAddress);

        console.log("Remote contract deployed at:", deployedRemote);
        console.log("Owner address:", ownerAddress);

        vm.stopBroadcast();
    }
} 