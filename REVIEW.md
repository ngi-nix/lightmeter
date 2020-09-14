A basic overview of the what should be reviewed.

### Prerequisites
- A mail server
  - This is not strictly required, since all that's needed is a postfix log(s)

### Sample Test Workflow
```bash
#! /usr/bin/env bash

nix build -L github:ngi-nix/lightmeter#nixosConfigurations.vm.config.system.build.vm
result/bin/run-vm-vm

# Login with user:user

# Start browser through terminal, Super+Enter
chromium &
disown
# Quit terminal with Super+Q

# Register an account at localhost:8080

# Play around with the UI, generally the first thing I do is use a custom range of the entire year
# Verify that your logs are parsed correctly (sent, bounced, deferred, etc.)
```
