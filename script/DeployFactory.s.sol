// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Factory.sol";
import "./Constants.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory rpcUrl = vm.envString("RPC_URL");
        address stargate = vm.envAddress("STARGATE_ADDRESS");
        address endpoint = vm.envAddress("ENDPOINT_ADDRESS");
        address portalRouter = vm.envAddress("PORTAL_ROUTER_ADDRESS");
        uint256 stargateFee = vm.envUint("STARGATE_FEE");
        
        address[] memory stargateAddresses = new address[](2);
        address[] memory tokenAddresses = new address[](2);

        if (block.chainid == BASE_CHAIN_ID) {
            stargateAddresses[0] = BASE_STARGATE_POOL_NATIVE; 
            stargateAddresses[1] = BASE_STARGATE_POOL_USDC;
            tokenAddresses[0] = address(0); 
            tokenAddresses[1] = BASE_USDC;
        }
        
        if (block.chainid == ARB_CHAIN_ID) {
            stargateAddresses[0] = ARB_STARGATE_POOL_NATIVE; 
            stargateAddresses[1] = ARB_STARGATE_POOL_USDC;
            tokenAddresses[0] = address(0); 
            tokenAddresses[1] = ARB_USDC;
        }

        if (block.chainid == FLOW_CHAIN_ID) {
            stargateAddresses[0] = FLOW_STARGATE_OFT_ETH; 
            stargateAddresses[1] = FLOW_STARGATE_POOL_USDC;
            tokenAddresses[0] = FLOW_WETH; 
            tokenAddresses[1] = FLOW_USDC;
        }

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Factory contract
        Create2Factory factory = new Create2Factory(
            stargate,
            endpoint,
            stargateAddresses,
            tokenAddresses,
            portalRouter,
            stargateFee,
            abi.encodePacked(type(Remote).creationCode)
        );

        vm.stopBroadcast();

        console.log("Factory deployed at:", address(factory));
    }
} 
