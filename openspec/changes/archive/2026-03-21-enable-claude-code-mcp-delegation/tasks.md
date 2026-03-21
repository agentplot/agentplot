## 1. Analyze Existing Delegation Code

- [x] 1.1 Read and verify the MCP delegation logic in services/linkding/default.nix (mkClientConfig, mcpConfig, cc.hmModule)
- [x] 1.2 Read the existing composition test in tests/hmModules-composition.nix to understand the test pattern

## 2. Create MCP Delegation Evaluation Test

- [x] 2.1 Create tests/mcp-delegation.nix with mock client configs exercising: single client MCP enabled, MCP disabled (default), profile-scoped MCP, both default and profile MCP, and multi-client MCP coexistence
- [x] 2.2 Assert programs.claude-code.mcpServers contains correct keys, args, and env for each scenario
- [x] 2.3 Assert programs.claude-code.profiles.<name>.mcpServers contains correct entries for profile-scoped scenarios

## 3. Run and Fix

- [x] 3.1 Run nix-instantiate --eval tests/mcp-delegation.nix and verify it passes
- [x] 3.2 Fix any bugs found in the delegation code in services/linkding/default.nix
- [x] 3.3 Re-run test after any fixes to confirm all assertions pass
