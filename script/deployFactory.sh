#!/bin/bash

# Create a clean version of .env without carriage returns
clean_env_file() {
    tr -d '\r' < .env > .env.clean
}

# Function to read and clean environment variable
get_env_var() {
    local var_name=$1
    # Remove carriage returns and trim whitespace more thoroughly
    local value=$(grep "^$var_name=" .env.clean | cut -d '=' -f2- | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "$value"
}

# Clean the .env file first
clean_env_file

# Function to deploy to a specific chain
deploy_to_chain() {
    local chain_name=$1
    local chain_id=$2
    local rpc_url=$3
    local stargate=$4
    local endpoint=$5
    local stargateFee=$6
    local portalRouter=$7

    echo "Deploying to $chain_name..."
    
    # Set environment variables for this deployment
    export RPC_URL=$(get_env_var "$rpc_url")
    export STARGATE_ADDRESS=$(get_env_var "$stargate")
    export ENDPOINT_ADDRESS=$(get_env_var "$endpoint")
    export STARGATE_FEE=$(get_env_var "$stargateFee")
    export PORTAL_ROUTER_ADDRESS=$(get_env_var "$portalRouter")
    
    # Debug: Print the values to verify they're clean
    echo "RPC_URL: '$RPC_URL'"
    echo "STARGATE_ADDRESS: '$STARGATE_ADDRESS'"
    echo "ENDPOINT_ADDRESS: '$ENDPOINT_ADDRESS'"
    echo "STARGATE_FEE: '$STARGATE_FEE'"
    echo "PORTAL_ROUTER_ADDRESS: '$PORTAL_ROUTER_ADDRESS'"

    # Run the deployment
    forge script script/DeployFactory.s.sol:DeployFactory \
        --rpc-url "$RPC_URL" \
        --broadcast \
        -vvvv

    echo "Deployment to $chain_name completed!"
    echo "----------------------------------------"
}


# Deploy to Base
deploy_to_chain "Base" \
    "8453" \
    "BASE_RPC_URL" \
    "BASE_STARGATE_ADDRESS" \
    "BASE_ENDPOINT_ADDRESS" \
    "STARGATE_FEE" \
    "BASE_PORTAL_ROUTER_ADDRESS"

# Deploy to Flow
deploy_to_chain "Flow" \
    "747" \
    "FLOW_RPC_URL" \
    "FLOW_STARGATE_ADDRESS" \
    "FLOW_ENDPOINT_ADDRESS" \
    "STARGATE_FEE" \
    "BASE_PORTAL_ROUTER_ADDRESS"

# Clean up
rm .env.clean