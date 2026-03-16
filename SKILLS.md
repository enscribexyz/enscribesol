# SKILLS.md

## Skill: foundry-contract-deploy-and-name-with-enscribe

### Purpose
Use this skill when a developer wants to deploy a Solidity contract with Foundry and immediately assign an ENS name (forward + reverse), or set naming for an already deployed contract, using this repository's `Ens` library.

### Trigger Phrases
- "deploy and name contract"
- "set ENS name in foundry script"
- "forward resolution only"
- "name existing deployed contract"
- "set primary name/reverse record"
- "use enscribe"

### Codebase Awareness
- Core entry point: `src/Ens.sol`
  - `Ens.setName(chainId, contractAddress, fullName)` -> sets forward + reverse.
  - `Ens.setForwardResolution(chainId, contractAddress, fullName)` -> forward only.
- Routing:
  - L2 chains route to `src/L2NameSetter.sol`.
  - Other chains route to `src/L1NameSetter.sol`.
- Utilities and chain/address constants: `src/CommonUtils.sol`.
- Script examples:
  - Deploy + name: `script/HelloWorldDeployAndSetName.s.sol`
  - Deploy + forward-only: `script/HelloWorldDeployAndSetFwdRes.s.sol`
  - Existing + name: `script/HelloWorldSetNameForExisting.s.sol`
  - Existing + forward-only: `script/HelloWorldSetFwdResForExisting.s.sol`

### Required Inputs
- `fullName` must contain at least one dot (for example, `counter.abhi.eth`).
- Caller must own the parent node (for example, own `abhi.eth` to create `counter.abhi.eth`).
- `contractAddress` must be non-zero.
- Correct `chainId` must be passed; unsupported chain IDs revert.

### Canonical Agent Workflow
1. Confirm target chain and ENS name from user.
2. Decide operation:
   - New deployment + naming
   - Existing address + naming
   - Forward-only naming
3. Update/create a Foundry script under `script/`.
4. Use one of:
   - `Ens.setName(block.chainid, address(target), "<fullName>");`
   - `Ens.setForwardResolution(block.chainid, address(target), "<fullName>");`
5. Run validation:
   - `forge build`
   - `forge test --match-path test/Ens.t.sol`
6. Execute script:
   - `forge script <script-path>:<contract> --rpc-url <RPC_URL> --chain-id <CHAIN_ID> --broadcast --private-key <PRIVATE_KEY> -vvvv`

### Safe Defaults For Agents
- Prefer `Ens.setName(...)` unless the user explicitly asks for forward-only behavior.
- Use `block.chainid` in scripts to avoid hardcoded chain IDs.
- Keep existing example script style and naming conventions.
- If user requests local Anvil integration, explain that current integration test uses chain ID `31337` which is unsupported by `CommonUtils.getRegistry(...)` unless code is extended.

### Known Failure Modes
- `Ens: unsupported chainId`
- `Ens: sender is not the owner of parent node`
- `Ens: name must contain a dot`
- `Ens: subname already exists and is owned by another address`
- `Ens: resolver not set for parent node`
- `Ens: setReverseResolution failed` (reverse registrar/resolver issue)

### Project-Specific Validation Notes
- `forge test` in this repo currently includes one expected failing integration path on default local setup:
  - `test/EnsIntegration.t.sol` fails with `Ens: unsupported chainId` due to chain ID `31337`.
- For utility and deterministic library checks, use:
  - `forge test --match-path test/Ens.t.sol`

### Output Contract For Agent Responses
When using this skill, the agent should return:
- exact file paths modified
- exact command(s) to run
- final ENS name used
- whether behavior is forward-only or forward+reverse
# skills.md

## Skill: foundry-contract-deploy-and-name-with-enscribe

### Purpose
Use this skill when a developer wants to deploy a Solidity contract with Foundry and immediately assign an ENS name (forward + reverse), or set naming for an already deployed contract, using this repository's `Ens` library.

### Trigger Phrases
- "deploy and name contract"
- "set ENS name in foundry script"
- "forward resolution only"
- "name existing deployed contract"
- "set primary name/reverse record"
- "use enscribe"

### Codebase Awareness
- Core entry point: `src/Ens.sol`
  - `Ens.setName(chainId, contractAddress, fullName)` -> sets forward + reverse.
  - `Ens.setForwardResolution(chainId, contractAddress, fullName)` -> forward only.
- Routing:
  - L2 chains route to `src/L2NameSetter.sol`.
  - Other chains route to `src/L1NameSetter.sol`.
- Utilities and chain/address constants: `src/CommonUtils.sol`.
- Script examples:
  - Deploy + name: `script/HelloWorldDeployAndSetName.s.sol`
  - Deploy + forward-only: `script/HelloWorldDeployAndSetFwdRes.s.sol`
  - Existing + name: `script/HelloWorldSetNameForExisting.s.sol`
  - Existing + forward-only: `script/HelloWorldSetFwdResForExisting.s.sol`

### Required Inputs
- `fullName` must contain at least one dot (for example, `counter.abhi.eth`).
- Caller must own the parent node (for example, own `abhi.eth` to create `counter.abhi.eth`).
- `contractAddress` must be non-zero.
- Correct `chainId` must be passed; unsupported chain IDs revert.

### Canonical Agent Workflow
1. Confirm target chain and ENS name from user.
2. Decide operation:
   - New deployment + naming
   - Existing address + naming
   - Forward-only naming
3. Update/create a Foundry script under `script/`.
4. Use one of:
   - `Ens.setName(block.chainid, address(target), "<fullName>");`
   - `Ens.setForwardResolution(block.chainid, address(target), "<fullName>");`
5. Run validation:
   - `forge build`
   - `forge test --match-path test/Ens.t.sol`
6. Execute script:
   - `forge script <script-path>:<contract> --rpc-url <RPC_URL> --chain-id <CHAIN_ID> --broadcast --private-key <PRIVATE_KEY> -vvvv`

### Safe Defaults For Agents
- Prefer `Ens.setName(...)` unless the user explicitly asks for forward-only behavior.
- Use `block.chainid` in scripts to avoid hardcoded chain IDs.
- Keep existing example script style and naming conventions.
- If user requests local Anvil integration, explain that current integration test uses chain ID `31337` which is unsupported by `CommonUtils.getRegistry(...)` unless code is extended.

### Known Failure Modes
- `Ens: unsupported chainId`
- `Ens: sender is not the owner of parent node`
- `Ens: name must contain a dot`
- `Ens: subname already exists and is owned by another address`
- `Ens: resolver not set for parent node`
- `Ens: setReverseResolution failed` (reverse registrar/resolver issue)

### Project-Specific Validation Notes
- `forge test` in this repo currently includes one expected failing integration path on default local setup:
  - `test/EnsIntegration.t.sol` fails with `Ens: unsupported chainId` due to chain ID `31337`.
- For utility and deterministic library checks, use:
  - `forge test --match-path test/Ens.t.sol`

### Output Contract For Agent Responses
When using this skill, the agent should return:
- exact file paths modified
- exact command(s) to run
- final ENS name used
- whether behavior is forward-only or forward+reverse
# skills.md

## Skill: foundry-contract-deploy-and-name-with-enscribe

### Purpose
Use this skill when a developer wants to deploy a Solidity contract with Foundry and immediately assign an ENS name (forward + reverse), or set naming for an already deployed contract, using this repository's `Ens` library.

### Trigger Phrases
- "deploy and name contract"
- "set ENS name in foundry script"
- "forward resolution only"
- "name existing deployed contract"
- "set primary name/reverse record"
- "use enscribe"

### Codebase Awareness
- Core entry point: `src/Ens.sol`
  - `Ens.setName(chainId, contractAddress, fullName)` -> sets forward + reverse.
  - `Ens.setForwardResolution(chainId, contractAddress, fullName)` -> forward only.
- Routing:
  - L2 chains route to `src/L2NameSetter.sol`.
  - Other chains route to `src/L1NameSetter.sol`.
- Utilities and chain/address constants: `src/CommonUtils.sol`.
- Script examples:
  - Deploy + name: `script/HelloWorldDeployAndSetName.s.sol`
  - Deploy + forward-only: `script/HelloWorldDeployAndSetFwdRes.s.sol`
  - Existing + name: `script/HelloWorldSetNameForExisting.s.sol`
  - Existing + forward-only: `script/HelloWorldSetFwdResForExisting.s.sol`

### Required Inputs
- `fullName` must contain at least one dot (for example, `counter.abhi.eth`).
- Caller must own the parent node (for example, own `abhi.eth` to create `counter.abhi.eth`).
- `contractAddress` must be non-zero.
- Correct `chainId` must be passed; unsupported chain IDs revert.

### Canonical Agent Workflow
1. Confirm target chain and ENS name from user.
2. Decide operation:
   - New deployment + naming
   - Existing address + naming
   - Forward-only naming
3. Update/create a Foundry script under `script/`.
4. Use one of:
   - `Ens.setName(block.chainid, address(target), "<fullName>");`
   - `Ens.setForwardResolution(block.chainid, address(target), "<fullName>");`
5. Run validation:
   - `forge build`
   - `forge test --match-path test/Ens.t.sol`
6. Execute script:
   - `forge script <script-path>:<contract> --rpc-url <RPC_URL> --chain-id <CHAIN_ID> --broadcast --private-key <PRIVATE_KEY> -vvvv`

### Safe Defaults For Agents
- Prefer `Ens.setName(...)` unless the user explicitly asks for forward-only behavior.
- Use `block.chainid` in scripts to avoid hardcoded chain IDs.
- Keep existing example script style and naming conventions.
- If user requests local Anvil integration, explain that current integration test uses chain ID `31337` which is unsupported by `CommonUtils.getRegistry(...)` unless code is extended.

### Known Failure Modes
- `Ens: unsupported chainId`
- `Ens: sender is not the owner of parent node`
- `Ens: name must contain a dot`
- `Ens: subname already exists and is owned by another address`
- `Ens: resolver not set for parent node`
- `Ens: setReverseResolution failed` (reverse registrar/resolver issue)

### Project-Specific Validation Notes
- `forge test` in this repo currently includes one expected failing integration path on default local setup:
  - `test/EnsIntegration.t.sol` fails with `Ens: unsupported chainId` due to chain ID `31337`.
- For utility and deterministic library checks, use:
  - `forge test --match-path test/Ens.t.sol`

### Output Contract For Agent Responses
When using this skill, the agent should return:
- exact file paths modified
- exact command(s) to run
- final ENS name used
- whether behavior is forward-only or forward+reverse
