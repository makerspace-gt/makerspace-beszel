# Makerspace GT Beszel Monitoring

Ansible playbooks to deploy [Beszel](https://github.com/henrygd/beszel) monitoring across the makerspace infrastructure.

## Architecture

- **Hub**: Runs on the Proxmox laptop (Tailscale), accessible at port 8090
- **Agents**: Lightweight containers on Debian/Ubuntu VMs, listening on port 45876
- **Connection**: Hub SSHs into agents (not the other way around)

## Setup

Install Ansible and pre-commit:

```bash
# Arch Linux
sudo pacman -S --needed ansible pre-commit

# Debian / Ubuntu
sudo apt update && sudo apt install -y ansible pre-commit
```

Then enable the git hooks (secret detection, YAML linting, and a guard that refuses to
commit/push an unencrypted vault — this repo is public):

```bash
pre-commit install --hook-type pre-commit --hook-type pre-push
```

You also need:

- `ansible-vault` password in `.vault_pass`
- SSH access (as root) to all target hosts

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

## Notifications & alerts

Beszel sends alerts via [shoutrrr](https://containrrr.dev/shoutrrr/) URLs, configured in the hub
UI (**Settings → Notifications**); the alerts themselves (status/down, CPU, memory, disk) are
enabled per system. The notification URLs are recorded in the vault (`beszel_notify_*`,
`beszel_signal_apprise_url`) so they are not lost.

### Discord

Supported natively by shoutrrr. Convert a Discord webhook
`https://discord.com/api/webhooks/<id>/<token>` into:

```
discord://<token>@<id>
```

### Signal (via apprise-api sidecar)

shoutrrr has no Signal service, so the hub role runs an **apprise-api** sidecar — deployed only
when `beszel_signal_apprise_url` is set in the vault. `deploy-hub.yaml` starts it next to the hub
and seeds it with the Apprise Signal URL under the config key `beszel`. Beszel then posts to it
with a generic webhook:

```
generic://apprise:8000/notify/beszel?disabletls=yes&template=json&messagekey=body
```

- `apprise:8000` — the sidecar, reached by container name on the hub's compose network.
- `disabletls=yes` — this hop is plain HTTP but never leaves the Pi (container-to-container) and
  carries only the alert text, no credentials.
- `template=json&messagekey=body` — builds `{"title": ..., "body": ...}`, which apprise-api requires.

`beszel_signal_apprise_url` is an [Apprise Signal URL](https://github.com/caronc/apprise/wiki/Notify_signal)
— scheme `signals://`, then HTTP basic-auth credentials, the bridge host, a `+<from>` number, and a
`group.<id>` recipient — pointing at the makerspace signal-cli-rest-api bridge (on koorax, behind
traefik basic-auth). It lives only in apprise-api's config, never in Beszel.

## Secrets

All secrets, IPs, and Tailscale addresses live in `inventory/group_vars/all.yaml` (vault-encrypted).
Never commit unencrypted secrets — `detect-secrets` and a pre-commit hook enforce this.
