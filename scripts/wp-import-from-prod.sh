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

LOCAL_URL="${WP_HOME:-http://localhost:8080}"
echo "Running search-replace for URLs..."
echo "  Replacing https://gaycarboys.com with $LOCAL_URL..."
docker compose run --rm wpcli wp search-replace "https://gaycarboys.com" "$LOCAL_URL" --all-tables --skip-columns=guid 2>/dev/null || true
echo "  Replacing http://gaycarboys.com with $LOCAL_URL..."
docker compose run --rm wpcli wp search-replace "http://gaycarboys.com" "$LOCAL_URL" --all-tables --skip-columns=guid 2>/dev/null || true
echo "  Replacing gaycarboys.com (domain only) with $(echo $LOCAL_URL | sed 's|http://||' | sed 's|https://||')..."
docker compose run --rm wpcli wp search-replace "gaycarboys.com" "$(echo $LOCAL_URL | sed 's|http://||' | sed 's|https://||')" --all-tables --skip-columns=guid 2>/dev/null || true
echo "✅ URL replacement complete"

echo "Done."


