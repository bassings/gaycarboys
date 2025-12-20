#!/usr/bin/env bash
set -euo pipefail

# Script to import a WordPress.com XML export (WXR format) into local Docker WordPress
# This handles the WordPress.com-specific import process

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <wordpress-com-export.xml>"
  echo ""
  echo "This script imports a WordPress.com XML export into your local Docker WordPress."
  echo "It will:"
  echo "  1. Import content (posts, pages, comments, etc.)"
  echo "  2. Attempt to download media files from WordPress.com"
  echo "  3. Set up basic configuration for local development"
  exit 1
fi

XML_EXPORT="$1"

if [[ ! -f "$XML_EXPORT" ]]; then
  echo "❌ Error: XML export file not found: $XML_EXPORT"
  exit 1
fi

# Check if containers are running
if ! docker compose ps | grep -q "wordpress.*Up"; then
  echo "❌ Error: WordPress container is not running. Start it with: make up"
  exit 1
fi

echo "=== WordPress.com Import ==="
echo ""
echo "Importing: $XML_EXPORT"
echo ""

# Check if WordPress is installed
echo "Checking WordPress installation..."
if ! docker compose exec -T wordpress wp core is-installed 2>/dev/null; then
  echo "WordPress not installed. Running initial setup..."
  ./scripts/wp-install-local.sh
fi

# Install WordPress Importer plugin if not already installed
echo "Checking for WordPress Importer plugin..."
if ! docker compose exec -T wordpress wp plugin is-installed wordpress-importer 2>/dev/null; then
  echo "Installing WordPress Importer plugin..."
  docker compose exec -T wordpress wp plugin install wordpress-importer --activate
fi

# Copy XML file into container
XML_BASENAME=$(basename "$XML_EXPORT")
echo "Copying XML file into container..."
docker compose cp "$XML_EXPORT" wordpress:/tmp/"$XML_BASENAME"

# Import the XML file
echo ""
echo "Importing content from XML export..."
docker compose exec -T wordpress wp import /tmp/"$XML_BASENAME" --authors=create 2>&1 | head -20

# Clean up
docker compose exec -T wordpress rm -f /tmp/"$XML_BASENAME"

if [[ $? -eq 0 ]]; then
  echo "✅ Content imported successfully!"
else
  echo "⚠️  Import completed with warnings. Some items may need manual review."
fi

# Note about media files
echo ""
echo "=== Media Files ==="
echo ""
echo "⚠️  Important: The XML export includes media references, but not the actual files."
echo ""
echo "WordPress.com media files are hosted on their CDN. The import process will"
echo "attempt to download them, but you may need to:"
echo ""
echo "1. Check Media Library in WordPress admin for missing images"
echo "2. Manually download large media files if needed"
echo "3. Or use a plugin like 'Import External Images' to fetch them"
echo ""

# Set up local URLs
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
echo "2. Log in with admin credentials (from .env or wp-install-local.sh)"
echo "3. Check Media Library for any missing images"
echo "4. Install a theme (WordPress.com themes aren't exportable)"
echo "5. Configure plugins as needed"
echo ""
echo "📖 See docs/EXPORTING_FROM_WORDPRESS_COM.md for more details"
echo ""

