// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
 * @title Create2Factory
 * @dev Factory contract for deploying contracts using CREATE2 opcode
 * @notice This contract allows for deterministic contract deployment
 */
contract Create2Factory {
    // Events
    event ContractDeployed(address indexed deployedAddress, bytes32 indexed salt);
    event DeploymentFailed(bytes32 indexed salt, string reason);

    /**
     * @dev Deploys a contract using CREATE2
     * @param bytecode The bytecode of the contract to deploy
     * @return deployedAddress The address of the deployed contract
     */
    function deploy(
        bytes memory bytecode
    ) public returns (address deployedAddress) {
        require(bytecode.length > 0, "Create2Factory: bytecode cannot be empty");

        // Create salt from msg.sender
        bytes32 salt = bytes32(uint256(uint160(msg.sender)));
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
}

