#!/usr/bin/env bash
set -euo pipefail

# Script to import an already-extracted Jetpack backup
# Handles the case where the backup was manually extracted to wordpress/

echo "=== Importing Extracted Jetpack Backup ==="
echo ""
echo "This script will import the Jetpack backup you've already extracted."
echo ""

# Check if containers are running
if ! docker compose ps | grep -q "wordpress.*Up"; then
  echo "❌ Error: WordPress container is not running. Start it with: make up"
  exit 1
fi

# Check for wp-content
if [[ ! -d "wordpress/wp-content" ]]; then
  echo "❌ Error: wp-content directory not found in wordpress/"
  echo "   Make sure you've extracted the backup to the wordpress/ folder"
  exit 1
fi

echo "✅ Found wp-content directory"
echo ""

# Check for SQL files
SQL_FOLDER=""
if [[ -d "wordpress/sql" ]]; then
  SQL_FOLDER="wordpress/sql"
elif [[ -d "wordpress/database" ]]; then
  SQL_FOLDER="wordpress/database"
else
  # Look for any sql folder
  SQL_FOLDER=$(find wordpress -type d -name "sql" -o -name "database" | head -1)
fi

# Check if WordPress is installed
echo "Checking WordPress installation..."
if ! docker compose run --rm wpcli wp core is-installed 2>/dev/null; then
  echo "WordPress not installed. Running initial setup..."
  ./scripts/wp-install-local.sh
fi

# Import database if SQL folder found
if [[ -n "$SQL_FOLDER" && -d "$SQL_FOLDER" ]]; then
  SQL_COUNT=$(find "$SQL_FOLDER" -name "*.sql" -type f | wc -l | tr -d ' ')
  if [[ $SQL_COUNT -gt 0 ]]; then
    echo "✅ Found $SQL_COUNT SQL table files in $SQL_FOLDER"
    echo ""
    echo "Importing database tables..."
    ./scripts/wp-import-jetpack-sql-folder.sh "$SQL_FOLDER"
  else
    echo "⚠️  SQL folder found but no .sql files inside"
  fi
else
  echo "⚠️  No SQL/database folder found"
  echo "   The backup may not include database files"
  echo "   You'll need to import content via XML export instead"
  echo ""
  echo "   To get content:"
  echo "   1. Export from WordPress.com: Tools → Export → Download XML"
  echo "   2. Import: ./scripts/wp-import-from-wordpress-com.sh ./export.xml"
fi

# wp-content is already in place, just verify
echo ""
echo "✅ wp-content is already in wordpress/wp-content/"
echo "   (No action needed - it's already extracted)"
echo ""

# Update URLs
LOCAL_URL="${WP_HOME:-http://localhost:8080}"
echo "Updating URLs to local environment..."
echo "  Replacing https://gaycarboys.com with $LOCAL_URL..."
docker compose run --rm wpcli wp search-replace "https://gaycarboys.com" "$LOCAL_URL" --all-tables --skip-columns=guid 2>/dev/null || true
echo "  Replacing http://gaycarboys.com with $LOCAL_URL..."
docker compose run --rm wpcli wp search-replace "http://gaycarboys.com" "$LOCAL_URL" --all-tables --skip-columns=guid 2>/dev/null || true
echo "  Replacing gaycarboys.com (domain only) with $(echo $LOCAL_URL | sed 's|http://||' | sed 's|https://||')..."
docker compose run --rm wpcli wp search-replace "gaycarboys.com" "$(echo $LOCAL_URL | sed 's|http://||' | sed 's|https://||')" --all-tables --skip-columns=guid 2>/dev/null || true
echo "✅ URL replacement complete"

echo ""
echo "=== Import Complete ==="
echo ""
echo "Next steps:"
echo "1. Visit your local site: $LOCAL_URL"
echo "2. You may need to reset admin password:"
echo "   make wp CMD=\"user update admin --user_pass=yourpassword\""
echo "   OR find your username first:"
echo "   make wp CMD=\"user list\""
echo "3. Check that everything looks correct"
echo "4. Some plugins may need reactivation"
echo ""

