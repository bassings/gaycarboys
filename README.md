## Gay Car Boys – Local WordPress Dev & Validation

Local Dockerised WordPress environment for working on [`gaycarboys.com`](http://gaycarboys.com/) and running automated validation (lint, health checks, Playwright tests).

This uses a stack approximating typical shared hosting: Apache + PHP 8.1 (`wordpress:php8.1-apache`) and MariaDB 10.6.

### Prerequisites

- Docker Desktop on macOS
- Node.js (LTS) + npm
- Composer (for PHP tooling)

### Getting started

```bash
cd /Volumes/Storage/home/scott.b/repos/Gaycarboys
cp .env.example .env    # create and adjust local env if needed
make up                 # start containers
```

Then visit `http://localhost:8080` (or change `WEB_PORT` / `WP_HOME` in `.env`).

### Initial local install (no production data yet)

After containers are up:

```bash
./scripts/wp-install-local.sh
```

This will install a fresh WordPress site using the values from environment variables (`WP_HOME`, `WP_ADMIN_USER`, etc.).

### Import from production

**First, determine your hosting type:**

- **WordPress.com** (managed hosting) → See [WordPress.com export guide](docs/EXPORTING_FROM_WORDPRESS_COM.md)
- **Self-hosted WordPress** → See [self-hosted export guide](docs/EXPORTING_FROM_PRODUCTION.md)

**Quick helper:**

```bash
./scripts/wp-export-helper.sh
```

This interactive script will guide you based on your hosting type.

#### For WordPress.com Sites

**Option A: Jetpack Backup (Recommended - Most Complete)**

If you have Jetpack Backup enabled:

1. Export backup: WordPress.com dashboard → **Jetpack → Backups** → Download backup
2. Import locally:

```bash
./scripts/wp-import-jetpack-backup.sh ./jetpack-backup-YYYY-MM-DD.zip
```

This includes: complete database, wp-content (themes, plugins, uploads), and all media files.

**Option B: Standard XML Export (Content Only)**

If Jetpack Backup is not available:

1. Export content: WordPress.com dashboard → **Tools → Export** → Download XML
2. Import locally:

```bash
./scripts/wp-import-from-wordpress-com.sh ./gaycarboys-export.xml
```

**Note:** XML exports only include content (posts, pages, media references), not themes or plugins. You'll need to install a theme locally and configure plugins separately.

#### For Self-Hosted WordPress

**Once you have:**

- A DB dump from production (e.g. `prod.sql`)
- A copy of `wp-content` from production

**Import locally:**

```bash
./scripts/wp-import-from-prod.sh /path/to/prod.sql /path/to/wp-content
```

The script:

- Syncs `wp-content` into `wordpress/wp-content`
- Imports the DB into the `db` container
- Runs a search-replace from `http://gaycarboys.com` to your local `WP_HOME`

### Validation pipeline

Install JS/PHP tooling once:

```bash
npm install
composer install
```

Run the full local validation:

```bash
npm run validate
```

This will:

- Lint PHP code using WordPress Coding Standards (`phpcs.xml.dist`)
- Lint JS and CSS (if present under `wordpress/wp-content`)
- Run HTTP health checks against key URLs
- Run PHPUnit tests (placeholder bootstrap wired to local config)
- Run Playwright end-to-end tests (basic homepage/article flows)

You can also run pieces individually:

- `npm run lint`
- `npm run health`
- `npm run test:phpunit`
- `npm run test:e2e`

### Common Docker commands

- `make up` – start containers
- `make down` – stop containers and remove them
- `make logs` – follow logs
- `make wp CMD="plugin list"` – run WP-CLI commands

### CI (future)

The same `npm run validate` command is designed to be reusable in CI (e.g. GitHub Actions) once this repo is pushed. A workflow can:

- Build the Docker stack
- Run `composer install`, `npm install`
- Execute `npm run validate` on each push/PR


