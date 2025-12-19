#!/usr/bin/env bash
set -euo pipefail

# Script to import a production DB dump and wp-content into the local Docker stack.

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <db_dump.sql> <wp_content_dir>"
  exit 1
fi

DB_DUMP="$1"
WP_CONTENT_SRC="$2"

if [[ ! -f "$DB_DUMP" ]]; then
  echo "DB dump not found: $DB_DUMP"
  exit 1
fi

if [[ ! -d "$WP_CONTENT_SRC" ]]; then
  echo "wp-content directory not found: $WP_CONTENT_SRC"
  exit 1
fi

echo "Copying wp-content..."
rsync -a "$WP_CONTENT_SRC"/ wordpress/wp-content/

echo "Importing database..."
docker compose exec -T db sh -c "mysql -u\${MYSQL_USER:-gaycarboys} -p\${MYSQL_PASSWORD:-gaycarboys} \${MYSQL_DATABASE:-gaycarboys}" < "$DB_DUMP"

echo "Running search-replace for URLs..."
docker compose run --rm wpcli wp search-replace "http://gaycarboys.com" "${WP_HOME:-http://gaycarboys.local}" --skip-columns=guid

echo "Done."


