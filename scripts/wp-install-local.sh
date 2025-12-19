#!/usr/bin/env bash
set -euo pipefail

SITE_URL="${WP_HOME:-http://gaycarboys.local}"
SITE_TITLE="${WP_SITE_TITLE:-Gay Car Boys Local}"
ADMIN_USER="${WP_ADMIN_USER:-admin}"
ADMIN_PASS="${WP_ADMIN_PASS:-password}"
ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"

docker compose run --rm wpcli wp core install \
  --url="$SITE_URL" \
  --title="$SITE_TITLE" \
  --admin_user="$ADMIN_USER" \
  --admin_password="$ADMIN_PASS" \
  --admin_email="$ADMIN_EMAIL"


