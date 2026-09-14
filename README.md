# SelfCloud

Self-hosted Nextcloud + OnlyOffice stack, deployed on [Dokploy](https://dokploy.com).

## Repo structure

```
compose/
  nextcloud.yml    # Nextcloud + MariaDB + Redis
  onlyoffice.yml    # OnlyOffice Document Server
scripts/
  install-prereqs.sh       # Installs Docker + Dokploy on the target server
  generate-jwt-secret.sh   # Generates the JWT secret OnlyOffice needs
```

## Prerequisites

- A Linux server (Ubuntu/Debian/RHEL family) with SSH access and a sudo-capable user.
- Ports `8080` (Nextcloud) and `8088` (OnlyOffice) reachable from wherever you'll use them.

## Setup

1. **Install Docker and Dokploy on the server**

   ```bash
   ./scripts/install-prereqs.sh
   ```

   Idempotent — safe to re-run. Installs base dependencies, Docker Engine + the Compose plugin, and Dokploy if any are missing.

2. **Create a compose deployment for Nextcloud**

   In Dokploy, create a new Compose service using [compose/nextcloud.yml](compose/nextcloud.yml) and set the required environment variables:

   | Variable | Description |
   |---|---|
   | `MYSQL_PASSWORD` | Password for the `nextcloud` DB user |
   | `MYSQL_ROOT_PASSWORD` | Root password for the MariaDB container |

   Deploy, then finish the Nextcloud web setup wizard at `http://<server>:8080`.

3. **Generate a JWT secret for OnlyOffice**

   ```bash
   ./scripts/generate-jwt-secret.sh
   ```

   Prints a random secret and saves it to `compose/onlyoffice.env` (git-ignored). Re-run to rotate it later.

4. **Create a compose deployment for OnlyOffice**

   Create a second Compose service using [compose/onlyoffice.yml](compose/onlyoffice.yml) and set the `JWT_SECRET` environment variable to the value generated in step 3. Deploy and confirm it's reachable at `http://<server>:8088`.

5. **Connect OnlyOffice to Nextcloud**

   In Nextcloud, install the **ONLYOFFICE** app (Apps → search "ONLYOFFICE"), then go to **Settings → ONLYOFFICE** and set:
   - **Document Editing Service address**: `http://<server>:8088`
   - **Secret key**: the `JWT_SECRET` value from step 3

## Notes

- Nextcloud and OnlyOffice are deployed as separate compose stacks so they can be scaled/updated independently.
- Named volumes (`nextcloud_data`, `nextcloud_db_data`, `onlyoffice_data`, `onlyoffice_log`) persist data across redeploys — back them up before making destructive changes.
