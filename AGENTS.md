# AGENTS.md

## Objective
Help developers integrate ENS naming into Foundry deployment workflows using this library, with minimal friction and production-safe defaults.

## Project Map
- Library entrypoint: `src/Ens.sol`
- L1 naming logic: `src/L1NameSetter.sol`
- L2 naming logic: `src/L2NameSetter.sol`
- Shared ENS interfaces/utilities/constants: `src/CommonUtils.sol`
- Example target contract: `src/HelloWorld.sol`
- Deployment/naming scripts: `script/*.s.sol`
- Tests:
  - Core utility tests: `test/Ens.t.sol`
  - Local integration harness: `test/EnsIntegration.t.sol`

## Agent Operating Rules
1. Prefer editing/creating scripts in `script/` rather than changing core library logic unless explicitly requested.
2. Default to `Ens.setName(...)` (forward + reverse). Use `Ens.setForwardResolution(...)` only if user asks for forward-only.
3. Always pass `block.chainid` from script execution context.
4. Never hardcode secrets; require `--private-key` input or environment indirection.
5. Keep contract/script style consistent with existing repo patterns.

## ENS Preconditions To Check
- ENS name format:
  - Must include a dot (`label.parent` minimum).
  - Label and parent parts cannot be empty.
- Ownership:
  - Broadcast signer must own the parent node.
- Chain support:
  - Chain must be present in `CommonUtils` address mappings.
- Address validity:
  - Contract address must not be zero.

## Supported Agent Tasks
- Create or modify Foundry scripts to:
  - deploy then set name
  - deploy then set forward resolution
  - set name on existing deployed address
  - set forward resolution on existing deployed address
- Troubleshoot reverts from naming calls.
- Add/update tests for deterministic utility behavior.

## Recommended Command Sequence
1. `forge build`
2. `forge test --match-path test/Ens.t.sol`
3. If executing deployment:
   - `forge script <script-path>:<contract> --rpc-url <RPC_URL> --chain-id <CHAIN_ID> --broadcast --private-key <PRIVATE_KEY> -vvvv`

## Important Repository Caveat
- `test/EnsIntegration.t.sol` currently targets `CHAIN_ID = 31337`.
- `CommonUtils.getRegistry(31337)` returns `address(0)`, so this integration test fails on default local runs with `Ens: unsupported chainId`.
- Treat this as an environment/setup gap unless user asks to add local chain support.

## Troubleshooting Playbook
- `unsupported chainId`:
  - confirm target chain ID and `CommonUtils` mapping.
- `sender is not the owner of parent node`:
  - verify signer controls parent ENS name.
- `subname already exists and is owned by another address`:
  - choose a different label or transfer ownership.
- `resolver not set` / reverse resolution failures:
  - verify resolver configuration on parent/subname and chain-specific reverse registrar availability.

## Preferred Response Format For Agent Outputs
- `Changes`: file paths touched
- `Behavior`: forward-only vs forward+reverse
- `Commands`: exact commands user can run
- `Risks`: any ownership/chain/resolver caveats
# agents.md

## Objective
Help developers integrate ENS naming into Foundry deployment workflows using this library, with minimal friction and production-safe defaults.

## Project Map
- Library entrypoint: `src/Ens.sol`
- L1 naming logic: `src/L1NameSetter.sol`
- L2 naming logic: `src/L2NameSetter.sol`
- Shared ENS interfaces/utilities/constants: `src/CommonUtils.sol`
- Example target contract: `src/HelloWorld.sol`
- Deployment/naming scripts: `script/*.s.sol`
- Tests:
  - Core utility tests: `test/Ens.t.sol`
  - Local integration harness: `test/EnsIntegration.t.sol`

## Agent Operating Rules
1. Prefer editing/creating scripts in `script/` rather than changing core library logic unless explicitly requested.
2. Default to `Ens.setName(...)` (forward + reverse). Use `Ens.setForwardResolution(...)` only if user asks for forward-only.
3. Always pass `block.chainid` from script execution context.
4. Never hardcode secrets; require `--private-key` input or environment indirection.
5. Keep contract/script style consistent with existing repo patterns.

## ENS Preconditions To Check
- ENS name format:
  - Must include a dot (`label.parent` minimum).
  - Label and parent parts cannot be empty.
- Ownership:
  - Broadcast signer must own the parent node.
- Chain support:
  - Chain must be present in `CommonUtils` address mappings.
- Address validity:
  - Contract address must not be zero.

## Supported Agent Tasks
- Create or modify Foundry scripts to:
  - deploy then set name
  - deploy then set forward resolution
  - set name on existing deployed address
  - set forward resolution on existing deployed address
- Troubleshoot reverts from naming calls.
- Add/update tests for deterministic utility behavior.

## Recommended Command Sequence
1. `forge build`
2. `forge test --match-path test/Ens.t.sol`
3. If executing deployment:
   - `forge script <script-path>:<contract> --rpc-url <RPC_URL> --chain-id <CHAIN_ID> --broadcast --private-key <PRIVATE_KEY> -vvvv`

## Important Repository Caveat
- `test/EnsIntegration.t.sol` currently targets `CHAIN_ID = 31337`.
- `CommonUtils.getRegistry(31337)` returns `address(0)`, so this integration test fails on default local runs with `Ens: unsupported chainId`.
- Treat this as an environment/setup gap unless user asks to add local chain support.

## Troubleshooting Playbook
- `unsupported chainId`:
  - confirm target chain ID and `CommonUtils` mapping.
- `sender is not the owner of parent node`:
  - verify signer controls parent ENS name.
- `subname already exists and is owned by another address`:
  - choose a different label or transfer ownership.
- `resolver not set` / reverse resolution failures:
  - verify resolver configuration on parent/subname and chain-specific reverse registrar availability.

## Preferred Response Format For Agent Outputs
- `Changes`: file paths touched
- `Behavior`: forward-only vs forward+reverse
- `Commands`: exact commands user can run
- `Risks`: any ownership/chain/resolver caveats
# agents.md

## Objective
Help developers integrate ENS naming into Foundry deployment workflows using this library, with minimal friction and production-safe defaults.

## Project Map
- Library entrypoint: `src/Ens.sol`
- L1 naming logic: `src/L1NameSetter.sol`
- L2 naming logic: `src/L2NameSetter.sol`
- Shared ENS interfaces/utilities/constants: `src/CommonUtils.sol`
- Example target contract: `src/HelloWorld.sol`
- Deployment/naming scripts: `script/*.s.sol`
- Tests:
  - Core utility tests: `test/Ens.t.sol`
  - Local integration harness: `test/EnsIntegration.t.sol`

## Agent Operating Rules
1. Prefer editing/creating scripts in `script/` rather than changing core library logic unless explicitly requested.
2. Default to `Ens.setName(...)` (forward + reverse). Use `Ens.setForwardResolution(...)` only if user asks for forward-only.
3. Always pass `block.chainid` from script execution context.
4. Never hardcode secrets; require `--private-key` input or environment indirection.
5. Keep contract/script style consistent with existing repo patterns.

## ENS Preconditions To Check
- ENS name format:
  - Must include a dot (`label.parent` minimum).
  - Label and parent parts cannot be empty.
- Ownership:
  - Broadcast signer must own the parent node.
- Chain support:
  - Chain must be present in `CommonUtils` address mappings.
- Address validity:
  - Contract address must not be zero.

## Supported Agent Tasks
- Create or modify Foundry scripts to:
  - deploy then set name
  - deploy then set forward resolution
  - set name on existing deployed address
  - set forward resolution on existing deployed address
- Troubleshoot reverts from naming calls.
- Add/update tests for deterministic utility behavior.

## Recommended Command Sequence
1. `forge build`
2. `forge test --match-path test/Ens.t.sol`
3. If executing deployment:
   - `forge script <script-path>:<contract> --rpc-url <RPC_URL> --chain-id <CHAIN_ID> --broadcast --private-key <PRIVATE_KEY> -vvvv`

## Important Repository Caveat
- `test/EnsIntegration.t.sol` currently targets `CHAIN_ID = 31337`.
- `CommonUtils.getRegistry(31337)` returns `address(0)`, so this integration test fails on default local runs with `Ens: unsupported chainId`.
- Treat this as an environment/setup gap unless user asks to add local chain support.

## Troubleshooting Playbook
- `unsupported chainId`:
  - confirm target chain ID and `CommonUtils` mapping.
- `sender is not the owner of parent node`:
  - verify signer controls parent ENS name.
- `subname already exists and is owned by another address`:
  - choose a different label or transfer ownership.
- `resolver not set` / reverse resolution failures:
  - verify resolver configuration on parent/subname and chain-specific reverse registrar availability.

## Preferred Response Format For Agent Outputs
- `Changes`: file paths touched
- `Behavior`: forward-only vs forward+reverse
- `Commands`: exact commands user can run
- `Risks`: any ownership/chain/resolver caveats
