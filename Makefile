-include .env

.PHONY: all clean deploy fund install snapshot coverageReport gasReport anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std@v1.11.0 && forge install openzeppelin/openzeppelin-contracts@v5.5.0 && forge install eth-infinitism/account-abstraction@v0.9.0

# Update Dependencies
update:; forge update

# Create test coverage report and save to .txt file
coverageReport :; forge coverage --report debug > coverage.txt

# Generate Gas Snapshot
snapshot :; forge snapshot

# Generate table showing gas cost for each function
gasReport :; forge test --gas-report

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployBasicAccount.s.sol:DeployBasicAccount $(NETWORK_ARGS)