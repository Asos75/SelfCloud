# SelfCloud

Self-hosted Nextcloud + OnlyOffice stack, deployed on [Dokploy](https://dokploy.com).

## Repo structure

```
compose/
  nextcloud.yml    # Nextcloud + MariaDB + Redis
  onlyoffice.yml    # OnlyOffice Document Server
scripts/
  install-prereqs.sh       # Installs Docker + Dokploy on the target server
  configure-firewall.sh    # Opens the required ports via ufw
  generate-jwt-secret.sh   # Generates the JWT secret OnlyOffice needs
```

## Prerequisites

- A Linux server (Ubuntu/Debian/RHEL family) with SSH access and a sudo-capable user.
- Ports `3000` (Dokploy dashboard), `8080` (Nextcloud), and `8088` (OnlyOffice) reachable from wherever you'll use them.

## Setup

1. **Install Docker and Dokploy on the server**

   ```bash
   ./scripts/install-prereqs.sh
   ```

   Idempotent — safe to re-run. Installs base dependencies, Docker Engine + the Compose plugin, and Dokploy if any are missing.

2. **Open the required ports**

   ```bash
   ./scripts/configure-firewall.sh
   ```

   Configures `ufw` to allow SSH, the Dokploy dashboard (`3000`), Traefik HTTP/HTTPS (`80`/`443`), Nextcloud (`8080`), and OnlyOffice (`8088`). Idempotent — safe to re-run.

3. **Create a compose deployment for Nextcloud**

   In Dokploy, create a new Compose service using [compose/nextcloud.yml](compose/nextcloud.yml) and set the required environment variables:

   | Variable | Description |
   |---|---|
   | `MYSQL_PASSWORD` | Password for the `nextcloud` DB user |
   | `MYSQL_ROOT_PASSWORD` | Root password for the MariaDB container |

   Deploy, then finish the Nextcloud web setup wizard at `http://<server>:8080`.

4. **Generate a JWT secret for OnlyOffice**

   ```bash
   ./scripts/generate-jwt-secret.sh
   ```

   Writes `compose/onlyoffice.generated.yml` (git-ignored) — a copy of [compose/onlyoffice.yml](compose/onlyoffice.yml) with the secret filled in; the original template is left untouched. Re-run to rotate the secret later.

5. **Create a compose deployment for OnlyOffice**

   Create a second Compose service in Dokploy using the contents of `compose/onlyoffice.generated.yml` from step 4. Deploy and confirm it's reachable at `http://<server>:8088`.

6. **Connect OnlyOffice to Nextcloud**

   In Nextcloud, install the **ONLYOFFICE** app (Apps → search "ONLYOFFICE"), then go to **Settings → ONLYOFFICE** and set:
   - **Document Editing Service address**: `http://<server>:8088`
   - **Secret key**: the `JWT_SECRET` value from step 4

## Notes

- Nextcloud and OnlyOffice are deployed as separate compose stacks so they can be scaled/updated independently.
- Named volumes (`nextcloud_data`, `nextcloud_db_data`, `onlyoffice_data`, `onlyoffice_log`) persist data across redeploys — back them up before making destructive changes.
