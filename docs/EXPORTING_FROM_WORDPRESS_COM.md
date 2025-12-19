# Exporting from WordPress.com

**Important:** WordPress.com is a managed hosting service, which means you have **limited access** compared to self-hosted WordPress. This affects what you can export.

## What You CAN Export from WordPress.com

✅ **Content (Posts, Pages, Comments, Media)**
- Via WordPress.com's built-in export tool
- Exports as XML (WXR format)
- Includes all posts, pages, comments, categories, tags, and media references

✅ **Jetpack Backups (BEST OPTION - Most Complete)**
- Full site backups including database and files
- Available if you have Jetpack Backup enabled
- More comprehensive than XML exports
- Includes themes, plugins, uploads, and database

## What You CANNOT Export from WordPress.com

❌ **Themes** - WordPress.com uses their own theme system (limited customization)
❌ **Plugins** - WordPress.com doesn't allow custom plugins (only their approved plugins)
❌ **Full Database** - No direct database access
❌ **File System** - No SSH, FTP, or file manager access
❌ **Custom Code** - No access to functions.php or custom PHP

## Export Process

### Method 1: Jetpack Backup (Recommended - Most Complete)

**If you have Jetpack Backup enabled**, this is the best option:

1. Log into your WordPress.com account at [wordpress.com](https://wordpress.com)
2. Go to your site's dashboard (gaycarboys.com)
3. Navigate to **Jetpack → Backups** (or **Backup** in the sidebar)
4. Find a recent backup point
5. Click **Download** or **Export** to download the backup
6. The backup will typically be a `.zip` or `.tar.gz` file containing:
   - Database dump (`.sql`)
   - Complete `wp-content` directory
   - Sometimes additional configuration files

**Import locally:**

```bash
# Extract the backup first
unzip jetpack-backup-YYYY-MM-DD.zip
# or
tar -xzf jetpack-backup-YYYY-MM-DD.tar.gz

# Then use the standard import script
./scripts/wp-import-from-prod.sh ./backup/database.sql ./backup/wp-content
```

**Note:** Jetpack backups from WordPress.com may have a specific structure. If the script doesn't work directly, see the troubleshooting section below.

### Method 2: Standard XML Export

### Step 1: Export Content from WordPress.com

1. Log into your WordPress.com account at [wordpress.com](https://wordpress.com)
2. Go to your site's dashboard (gaycarboys.com)
3. Navigate to **Tools → Export**
4. Choose what to export:
   - **All content** (recommended for first export)
   - Or select specific content types (posts, pages, etc.)
5. Click **Download Export File**
6. Save the XML file (e.g., `gaycarboys-export.xml`)

### Step 2: Download Media Files

The XML export includes references to media files, but **not the actual files**. You'll need to download them separately:

**Option A: Manual Download (Small Sites)**
1. Go to **Media → Library** in WordPress.com
2. Download images/videos manually (tedious for large sites)

**Option B: Use a Tool (Recommended)**
- Use a WordPress XML import tool that can fetch media automatically
- Or use the import script we provide (see below)

### Step 3: Import into Local Environment

Use the WordPress.com-specific import script:

```bash
./scripts/wp-import-from-wordpress-com.sh ./gaycarboys-export.xml
```

This script will:
- Import the XML content into your local WordPress
- Attempt to download media files from WordPress.com URLs
- Set up a basic theme (you'll need to customize this locally)
- Configure URLs for local development

## Jetpack Backup Details

### What's Included in Jetpack Backups

Jetpack backups are much more comprehensive than XML exports:

✅ **Complete Database** - All tables, settings, users, content
✅ **wp-content Directory** - Themes, plugins, uploads, customizations
✅ **Media Files** - All images, videos, and other uploads
✅ **Configuration** - Settings, widgets, menus, etc.

### Accessing Jetpack Backups on WordPress.com

1. **WordPress.com Dashboard:**
   - Go to your site → **Jetpack → Backups**
   - View available backup points
   - Download the backup you want

2. **Via WordPress.com API (if available):**
   - Some plans allow programmatic access
   - Check WordPress.com support for details

3. **Backup Format:**
   - Usually a compressed archive (`.zip` or `.tar.gz`)
   - Contains database dump and wp-content folder
   - May include additional metadata files

### Restoring Jetpack Backups Locally

Jetpack backups are designed to be restored through the Jetpack plugin, but we can extract and import them manually:

**Option A: Extract and Import Manually**

```bash
# 1. Extract the backup
unzip jetpack-backup.zip -d jetpack-backup-extracted/
# or
tar -xzf jetpack-backup.tar.gz -C jetpack-backup-extracted/

# 2. Find the database and wp-content
# Structure may vary, but typically:
# - database.sql or similar
# - wp-content/ directory

# 3. Import using our script
./scripts/wp-import-from-prod.sh \
  ./jetpack-backup-extracted/database.sql \
  ./jetpack-backup-extracted/wp-content
```

**Option B: Use Jetpack Plugin (Alternative)**

If you want to use Jetpack's restore feature:

1. Install Jetpack plugin in your local WordPress
2. Connect to WordPress.com
3. Use Jetpack's restore interface
4. Note: This may require a Jetpack plan with backup access

## Limitations & Workarounds

### Theme Customization

**WordPress.com limitation:** You can't export custom themes or access theme files.

**Workaround:**
1. Note the current theme name from WordPress.com
2. Install the same theme locally (if it's available for self-hosted WordPress)
3. Manually recreate any customizations in your local theme
4. Use your local Docker environment to develop a new, modern theme

### Plugins

**WordPress.com limitation:** No custom plugins, only WordPress.com's approved plugins.

**Workaround:**
- Identify which WordPress.com features you're using
- Find equivalent self-hosted WordPress plugins
- Install and configure them locally

### Custom Code

**WordPress.com limitation:** No access to functions.php or custom PHP.

**Workaround:**
- If you had custom functionality, you'll need to recreate it locally
- This is actually a good opportunity to modernize and improve the code

## Migration Strategy

Since you're modernizing the site, here's a recommended approach:

1. **Export content** from WordPress.com (XML)
2. **Import into local** Docker environment
3. **Develop new theme** locally (modern, responsive, fast)
4. **Add necessary plugins** for functionality
5. **Test everything** using the validation pipeline
6. **Deploy to new hosting** (when ready to move away from WordPress.com)

## Alternative: WordPress.com Migration Service

If you have a WordPress.com Business plan, you might have access to:
- **Site Migration Service** - WordPress.com can help migrate to self-hosted
- Contact WordPress.com support for details

## Quick Start

```bash
# 1. Export from WordPress.com (do this in browser)
# Tools → Export → Download Export File

# 2. Import locally
./scripts/wp-import-from-wordpress-com.sh ./gaycarboys-export.xml

# 3. Start developing!
make up
npm run validate
```

## Next Steps After Import

1. **Install a modern theme** or develop a custom one
2. **Configure plugins** for functionality you need
3. **Customize design** to modernize the look
4. **Test everything** with `npm run validate`
5. **Iterate and improve** using your local Docker environment

