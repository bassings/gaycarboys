# Exporting WordPress Files & Database from Production

This guide covers the best methods to get your WordPress site files and database from `gaycarboys.com` into your local Docker environment.

## What You Need

1. **Database dump** (`.sql` file) - Contains all posts, pages, settings, users, etc.
2. **wp-content directory** - Contains themes, plugins, uploads (images/media), and custom code

## Method 1: SSH Access (Best - Fastest & Most Reliable)

If you have SSH access to the server, this is the fastest method.

### Export Database

```bash
# SSH into the server
ssh user@gaycarboys.com

# Find your database credentials (usually in wp-config.php)
cd /path/to/wordpress
grep DB_ wp-config.php

# Export the database
mysqldump -u DB_USER -p DB_NAME > ~/gaycarboys-export.sql
# Enter password when prompted

# Download it to your Mac
exit
scp user@gaycarboys.com:~/gaycarboys-export.sql ./prod.sql
```

### Export wp-content

```bash
# SSH into server
ssh user@gaycarboys.com

# Create a tar archive of wp-content
cd /path/to/wordpress
tar -czf ~/wp-content-backup.tar.gz wp-content/

# Download to your Mac
exit
scp user@gaycarboys.com:~/wp-content-backup.tar.gz ./
tar -xzf wp-content-backup.tar.gz
```

**Or use rsync (more efficient for large directories):**

```bash
# Direct rsync from server to local
rsync -avz --progress user@gaycarboys.com:/path/to/wordpress/wp-content/ ./wp-content-temp/
```

## Method 2: cPanel / Hosting Control Panel

Most shared hosting providers offer database and file export tools.

### Database Export

1. Log into cPanel (or your host's control panel)
2. Find **phpMyAdmin** or **MySQL Databases**
3. Select your WordPress database
4. Click **Export** tab
5. Choose **Quick** export method, format **SQL**
6. Click **Go** to download

### File Export

1. In cPanel, open **File Manager**
2. Navigate to your WordPress root directory (usually `public_html` or `www`)
3. Right-click the `wp-content` folder
4. Select **Compress** (choose `.zip` or `.tar.gz`)
5. Download the compressed file
6. Extract it on your Mac

## Method 3: FTP/SFTP

If you only have FTP access (no SSH), use an FTP client.

### Using FileZilla (Free)

1. Download [FileZilla](https://filezilla-project.org/)
2. Connect to `gaycarboys.com` using FTP credentials
3. Navigate to WordPress root
4. Download the entire `wp-content` folder

**For database:** You'll still need to use phpMyAdmin (Method 2) or ask your host to provide a dump.

### Using Command Line (sftp)

```bash
# Connect via SFTP
sftp user@gaycarboys.com

# Navigate to WordPress directory
cd /path/to/wordpress

# Download wp-content
get -r wp-content ./wp-content-temp/

# Exit
exit
```

## Method 4: WordPress Plugins (Easiest but Slower)

If you have WordPress admin access, use a migration plugin.

### All-in-One WP Migration

1. Install **All-in-One WP Migration** plugin in WordPress admin
2. Go to **All-in-One WP Migration → Export**
3. Choose **Export To → File**
4. Download the `.wpress` file (contains everything)
5. Use the plugin's import feature locally, or extract manually

**Note:** The `.wpress` file is a custom format. You can:
- Use the plugin's import feature in your local WordPress
- Or use a tool like `wpress-extractor` to extract files manually

### UpdraftPlus

1. Install **UpdraftPlus** plugin
2. Go to **Settings → UpdraftPlus Backups**
3. Click **Backup Now**
4. Download the database and files backups
5. Extract and use with the import script

## Method 5: WP-CLI (If Available)

If WP-CLI is installed on the server:

```bash
# SSH into server
ssh user@gaycarboys.com
cd /path/to/wordpress

# Export database
wp db export ~/gaycarboys-export.sql

# Download
exit
scp user@gaycarboys.com:~/gaycarboys-export.sql ./

# For wp-content, use rsync or tar as in Method 1
```

## Recommended Workflow

**For first-time setup:**

1. **Get database:** Use Method 1 (SSH) or Method 2 (cPanel/phpMyAdmin)
2. **Get wp-content:** Use Method 1 (SSH/rsync) for speed, or Method 2 (cPanel File Manager) if easier
3. **Import locally:** Use the provided script:

```bash
./scripts/wp-import-from-prod.sh ./gaycarboys-export.sql ./wp-content
```

## Security & Privacy Considerations

⚠️ **Important:** Production databases may contain:

- User email addresses
- User passwords (hashed, but still sensitive)
- Admin credentials
- Potentially sensitive content

**Best practices:**

1. **Never commit production data to git** - Add to `.gitignore`:
   ```
   prod.sql
   wp-content/
   wordpress/wp-content/
   *.sql
   ```

2. **Scrub sensitive data locally** (optional but recommended):
   - Change all admin passwords after import
   - Consider anonymizing user emails if sharing the repo
   - Remove any API keys or secrets from wp-config

3. **Use environment variables** for any secrets in your local setup

## Troubleshooting

### Database import fails

- Check file size limits in Docker/MySQL
- Ensure the SQL file isn't corrupted
- Verify database credentials in `.env`

### wp-content too large

- Exclude cache directories: `rsync --exclude='cache' --exclude='*.log'`
- Compress first: `tar -czf wp-content.tar.gz wp-content/`
- Use incremental sync for updates

### URL replacement issues

The import script runs `wp search-replace`, but you may need to also update:
- Serialized data (the script handles this)
- Hardcoded URLs in theme/plugin code
- `.htaccess` rules

## Quick Reference

**Fastest method (SSH):**
```bash
# On server
mysqldump -u DB_USER -p DB_NAME > ~/export.sql
tar -czf ~/wp-content.tar.gz wp-content/

# On your Mac
scp user@server:~/export.sql ./
scp user@server:~/wp-content.tar.gz ./
tar -xzf wp-content.tar.gz
./scripts/wp-import-from-prod.sh ./export.sql ./wp-content
```

**Easiest method (cPanel):**
1. Export DB via phpMyAdmin
2. Download wp-content.zip via File Manager
3. Extract and import locally

