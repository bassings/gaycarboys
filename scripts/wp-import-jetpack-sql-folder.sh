#!/usr/bin/env bash
set -euo pipefail

# Script to import Jetpack backup with individual SQL files per table
# This handles the case where the backup has a sql/ folder with separate .sql files

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-sql-folder>"
  echo ""
  echo "This script imports individual SQL table files from a Jetpack backup."
  echo "It will combine all .sql files in the folder and import them."
  echo ""
  echo "Example:"
  echo "  $0 wordpress/sql"
  exit 1
fi

SQL_FOLDER="$1"

if [[ ! -d "$SQL_FOLDER" ]]; then
  echo "❌ Error: SQL folder not found: $SQL_FOLDER"
  exit 1
fi

# Check if containers are running
if ! docker compose ps | grep -q "wordpress.*Up"; then
  echo "❌ Error: WordPress container is not running. Start it with: make up"
  exit 1
fi

echo "=== Importing Jetpack SQL Files ==="
echo ""
echo "SQL folder: $SQL_FOLDER"
echo ""

# Count SQL files
SQL_COUNT=$(find "$SQL_FOLDER" -name "*.sql" -type f | wc -l | tr -d ' ')
if [[ $SQL_COUNT -eq 0 ]]; then
  echo "❌ Error: No .sql files found in $SQL_FOLDER"
  exit 1
fi

echo "Found $SQL_COUNT SQL table files"
echo ""

# Check if WordPress is installed
echo "Checking WordPress installation..."
if ! docker compose exec -T wordpress wp core is-installed 2>/dev/null; then
  echo "WordPress not installed. Running initial setup..."
  ./scripts/wp-install-local.sh
fi

# Import each SQL file
echo "Importing SQL tables..."
IMPORTED=0
FAILED=0

for sql_file in "$SQL_FOLDER"/*.sql; do
  if [[ -f "$sql_file" ]]; then
    table_name=$(basename "$sql_file" .sql)
    echo -n "  Importing $table_name... "
    
    if docker compose exec -T db sh -c "mysql -u\${MYSQL_USER:-gaycarboys} -p\${MYSQL_PASSWORD:-gaycarboys} \${MYSQL_DATABASE:-gaycarboys}" < "$sql_file" 2>/dev/null; then
      echo "✅"
      ((IMPORTED++))
    else
      echo "⚠️  (may already exist or have errors)"
      ((FAILED++))
    fi
  fi
done

echo ""
echo "=== Import Summary ==="
echo "✅ Successfully imported: $IMPORTED tables"
if [[ $FAILED -gt 0 ]]; then
  echo "⚠️  Warnings/errors: $FAILED tables"
  echo "   (Some tables may already exist or have minor issues)"
fi
echo ""

# Update URLs
LOCAL_URL="${WP_HOME:-http://localhost:8080}"
echo ""
echo "Updating URLs to local environment..."
echo "  Replacing https://gaycarboys.com with $LOCAL_URL..."
docker compose run --rm wpcli wp search-replace "https://gaycarboys.com" "$LOCAL_URL" --all-tables --skip-columns=guid 2>/dev/null || true
echo "  Replacing http://gaycarboys.com with $LOCAL_URL..."
docker compose run --rm wpcli wp search-replace "http://gaycarboys.com" "$LOCAL_URL" --all-tables --skip-columns=guid 2>/dev/null || true
echo "  Replacing gaycarboys.com (domain only) with $(echo $LOCAL_URL | sed 's|http://||' | sed 's|https://||')..."
docker compose run --rm wpcli wp search-replace "gaycarboys.com" "$(echo $LOCAL_URL | sed 's|http://||' | sed 's|https://||')" --all-tables --skip-columns=guid 2>/dev/null || true
echo "✅ URL replacement complete"

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Visit your local site: $LOCAL_URL"
echo "2. You may need to reset admin password:"
echo "   make wp CMD=\"user update admin --user_pass=yourpassword\""
echo "3. Check that everything looks correct"
echo "4. Some plugins may need reactivation"
echo ""

