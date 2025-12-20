#!/usr/bin/env bash
set -euo pipefail

# Script to import a Jetpack backup into local Docker WordPress
# Handles extraction and import of Jetpack backup archives

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <jetpack-backup.zip|tar.gz>"
  echo ""
  echo "This script imports a Jetpack backup into your local Docker WordPress."
  echo "It will:"
  echo "  1. Extract the backup archive"
  echo "  2. Find the database dump and wp-content directory"
  echo "  3. Import both into your local environment"
  exit 1
fi

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "❌ Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

# Check if containers are running
if ! docker compose ps | grep -q "wordpress.*Up"; then
  echo "❌ Error: WordPress container is not running. Start it with: make up"
  exit 1
fi

echo "=== Jetpack Backup Import ==="
echo ""
echo "Processing: $BACKUP_FILE"
echo ""

# Create temporary extraction directory
EXTRACT_DIR=$(mktemp -d -t jetpack-backup-XXXXXX)
trap "rm -rf $EXTRACT_DIR" EXIT

echo "Extracting backup archive..."
if [[ "$BACKUP_FILE" == *.zip ]]; then
  unzip -q "$BACKUP_FILE" -d "$EXTRACT_DIR"
elif [[ "$BACKUP_FILE" == *.tar.gz ]] || [[ "$BACKUP_FILE" == *.tgz ]]; then
  tar -xzf "$BACKUP_FILE" -C "$EXTRACT_DIR"
else
  echo "❌ Error: Unsupported archive format. Expected .zip, .tar.gz, or .tgz"
  exit 1
fi

# Find database dump and wp-content
echo "Locating database and wp-content..."
DB_DUMP=$(find "$EXTRACT_DIR" -name "*.sql" -type f | head -1)
WP_CONTENT_DIR=$(find "$EXTRACT_DIR" -type d -name "wp-content" | head -1)

# Handle different backup structures
if [[ -z "$DB_DUMP" ]]; then
  # Sometimes database is in a subdirectory
  DB_DUMP=$(find "$EXTRACT_DIR" -name "*database*.sql" -o -name "*db*.sql" | head -1)
fi

if [[ -z "$WP_CONTENT_DIR" ]]; then
  # Sometimes wp-content is in a subdirectory
  WP_CONTENT_DIR=$(find "$EXTRACT_DIR" -type d -path "*/wp-content" | head -1)
fi

if [[ -z "$DB_DUMP" ]]; then
  echo "⚠️  Warning: Could not find database dump (.sql file) in backup"
  echo "   Looking in: $EXTRACT_DIR"
  echo "   You may need to import the database manually"
  DB_DUMP=""
fi

if [[ -z "$WP_CONTENT_DIR" ]]; then
  echo "⚠️  Warning: Could not find wp-content directory in backup"
  echo "   Looking in: $EXTRACT_DIR"
  echo "   You may need to import wp-content manually"
  WP_CONTENT_DIR=""
fi

if [[ -z "$DB_DUMP" && -z "$WP_CONTENT_DIR" ]]; then
  echo ""
  echo "❌ Error: Could not find database or wp-content in backup archive"
  echo ""
  echo "Backup structure:"
  find "$EXTRACT_DIR" -maxdepth 3 -type f -o -type d | head -20
  echo ""
  echo "Please check the backup file structure and import manually."
  exit 1
fi

# Check if WordPress is installed
echo "Checking WordPress installation..."
if ! docker compose exec -T wordpress wp core is-installed 2>/dev/null; then
  echo "WordPress not installed. Running initial setup..."
  ./scripts/wp-install-local.sh
fi

# Import database if found
if [[ -n "$DB_DUMP" ]]; then
  echo ""
  echo "Found database: $DB_DUMP"
  echo "Importing database..."
  docker compose exec -T db sh -c "mysql -u\${MYSQL_USER:-gaycarboys} -p\${MYSQL_PASSWORD:-gaycarboys} \${MYSQL_DATABASE:-gaycarboys}" < "$DB_DUMP"
  echo "✅ Database imported"
else
  echo "⚠️  Skipping database import (not found)"
fi

# Import wp-content if found
if [[ -n "$WP_CONTENT_DIR" ]]; then
  echo ""
  echo "Found wp-content: $WP_CONTENT_DIR"
  echo "Copying wp-content..."
  rsync -a "$WP_CONTENT_DIR"/ wordpress/wp-content/
  echo "✅ wp-content copied"
else
  echo "⚠️  Skipping wp-content import (not found)"
fi

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
echo "=== Import Complete ==="
echo ""
echo "✅ Jetpack backup imported successfully!"
echo ""
echo "Next steps:"
echo "1. Visit your local site: $LOCAL_URL"
echo "2. Log in with your WordPress.com credentials (or reset password)"
echo "3. Check that everything looks correct"
echo "4. Install/activate any missing plugins if needed"
echo ""
echo "Note: Some WordPress.com-specific features may not work locally."
echo "You may need to install equivalent plugins for self-hosted WordPress."
echo ""


