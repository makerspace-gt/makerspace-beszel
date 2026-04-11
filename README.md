# Makerspace GT Beszel Monitoring

Ansible playbooks to deploy [Beszel](https://github.com/henrygd/beszel) monitoring across the makerspace infrastructure.

## Architecture

- **Hub**: Runs on the Proxmox laptop (Tailscale), accessible at port 8090
- **Agents**: Lightweight containers on Debian/Ubuntu VMs, listening on port 45876
- **Connection**: Hub SSHs into agents (not the other way around)

## Prerequisites

- Ansible
- `ansible-vault` password in `.vault_pass`
- SSH access (as root) to all target hosts
- Use the devcontainer!

## Deployment

```bash
# Deploy the hub
ansible-playbook playbooks/deploy-hub.yaml

# Copy the SSH public key from hub UI → "Add System" dialog
ansible-vault edit inventory/group_vars/all.yaml
# Set beszel_hub_key to the copied key

# Deploy agents
ansible-playbook playbooks/deploy-agents.yaml
```

## Adding a new host

1. Add the host's address to `inventory/group_vars/all.yaml` (vault-encrypted):
   ```bash
   ansible-vault edit inventory/group_vars/all.yaml
   ```
   Add an entry under `host_addresses`.

2. Add the host to `inventory/hosts.yaml` under the `agents` group:
   ```yaml
   new-host:
     ansible_host: "{{ host_addresses['new-host'] }}"
   ```

3. Deploy: `ansible-playbook playbooks/deploy-agents.yaml --limit new-host`

4. Register the host in the Beszel hub UI (hostname + port 45876).

## Secrets

All secrets, IPs, and Tailscale addresses live in `inventory/group_vars/all.yaml` (vault-encrypted).
Use the devcontainer!
Never commit unencrypted secrets — `detect-secrets` and a pre-commit hook enforce this.
