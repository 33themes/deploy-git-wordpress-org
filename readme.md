# Usage

Usage: `sh deploy.wordpress.org.sh [plugin_file_with_header.php] [WordPress.org Username] [Type of update: readme|version|assets]`
I.e.: `sh deploy.wordpress.org.sh index.php 33themes readme`


_______________________

# Changelog

## 1.0

- Adapted version to simple updates, assets and new version
- Sync svn folder with source. Remove missing files and adds new.
- Auto remove "assets" folder from tags (version) folder
