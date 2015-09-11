#! /bin/bash

# deploy-git-wordpress

# By: Gabriel Pérez S
# https://github.com/33themes/deploy-git-wordpress-org
# Version: 1.0
# Based on: https://github.com/aubreypwd/deploy-git-wordpress-org

# By: Aubrey Portwood, Brad Parbs
# https://github.com/aubreypwd/deploy-git-wordpress-org
# Version: 1.0
# Based on: https://github.com/brainstormmedia/deploy-plugin-to-wordpress-dot-org/blob/master/deploy.sh

# HEADERS MUST BE FORMATTED LIKE:
#
# /*
# Plugin Name: Google Destination URL
# Plugin URI: https://bitbucket.org/aubreypwd/gdurl
# Description: Perform a Google Search when adding a link in the editor.
# Version: 1.0
# Author: Aubrey Portwood
# Author URI: http://profiles.wordpress.org/aubreypwd/
# License: GPL2
# */
#
# DOCBLOCKS DO NOT WORK!


# Deps
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Usage: sh deploy.wordpress.org.sh [plugin_file_with_header.php] [WordPress.org Username] [Update type: readme|assets|version]";
	echo "I.e.: sh deploy.wordpress.org.sh index.php aubreypwd false";
	exit 1;
fi

echo "Starting Deployment to WP.org..."
echo "================================"

# Current directory
PLUGINSLUG=${PWD##*/}
CURRENTDIR=$(pwd)
SVNIGNORE="deploy-git-wordpress-org
	README.md
	readme.md
	.hg
	.hgcheck
	.hgignore
	.git
	.gitignore"

# Temp place to put the SVN
SVNPATH="/tmp/$PLUGINSLUG"
SVNURL="http://plugins.svn.wordpress.org/$PLUGINSLUG"


if [ -d "$SVNPATH" ]; then
    rm -Rf $SVNPATH;
fi

echo "- Checking to make sure that your plugin and the stable tag in readme.txt are the same..."

# readme.txt Checks
# NEWVERSION1=$(grep "^[\*\#\s]*Stable tag" "$CURRENTDIR"/readme.txt | awk -F' ' '{print $3}' | sed 's/[[:space:]]//g')
NEWVERSION1=$(cat readme.txt | perl -ne 'if (m/^[\*\s\=]*(Stable tag:?):\s*([0-9\.]+)\s*/i){ print "$2"; }')

	echo "- readme.txt Version: $NEWVERSION1"

NEWVERSION2=$(grep "^Version" "$CURRENTDIR"/"$1" | awk -F' ' '{print $2}' | sed 's/[[:space:]]//g')

	echo "- $1 Version: $NEWVERSION2"

# Commit Message
echo "- SVN Commit Message: \c"
read COMMITMSG

# SVN Work
svn co "$SVNURL" "$SVNPATH"
echo "- Just made a temporary copy of your SVN repo to $SVNPATH"

LANG1="- Just copied your Git repo to our temporary clone of your svn repo to $SVNPATH/trunk"
LANG2="- Committing your changes to WP.org..."

# Exit if they don't match
if [ "$NEWVERSION1" != "$NEWVERSION2" ]; then echo "- Versions don't match, sorry. Try again. Exiting...."; exit 1; fi

# If readme $3 is true
if [ "$3" = "readme" ]; then

	echo "- You are just updating your readme.txt to the stable tag $SVNPATH/tags/$NEWVERSION2..."

	# Export master to SVN
	git checkout-index -a -f --prefix="$SVNPATH"/trunk/
	echo "$LANG1"

	cd "$SVNPATH"/trunk/

	# Ignore some common files
	svn propset svn:ignore "$SVNIGNORE" "$SVNPATH/trunk/"

	# Copy the readme from trunk to the stable tag.
	cp "$SVNPATH"/trunk/readme.txt "$SVNPATH"/tags/"$NEWVERSION1"/readme.txt
	echo "- Just copied readme.txt from $SVNPATH/trunk/readme.txt to $SVNPATH/tags/$NEWVERSION1/readme.txt."

	cd "$SVNPATH"

	echo "$LANG2"
	svn commit --username="$2" -m "$COMMITMSG"

fi

# If version $3 is true
if [ "$3" = "version" ]; then 

	# Export master to SVN
	git checkout-index -a -f --prefix="$SVNPATH"/trunk/
	echo "$LANG1"

    # Sync trunk
    rsync -ahz --progress --exclude=".git" --exclude="*.md" --exclude="assets" --delete "$CURRENTDIR"/ "$SVNPATH"/trunk/

	# Ignore some common files
	svn propset svn:ignore "$SVNIGNORE" "$SVNPATH/trunk/"

	# More SVN Work (commit)
	cd "$SVNPATH"/trunk

    if [ -d "${SVNPATH}/trunk/assets" ]; then 
        svn rm --force "${SVNPATH}/trunk/assets" 
    fi 

	# Addremove (YES!)
	svn status | grep -v "^.[ \t]*\..*" | grep "^?" | awk '{print $2}' | xargs svn add
    svn status | grep -v "^.[ \t]*\..*" | grep "^[\!D]" | awk '{ print $2}' | xargs svn rm --force

	# Commit the code
	echo "$LANG2"
	svn commit --username="$2" -m "$COMMITMSG"

	# Commit the tag
	cd "$SVNPATH"

	echo "- Copying files from $SVNPATH/trunk to $SVNPATH/tags/$NEWVERSION2"
	svn copy trunk/ tags/"$NEWVERSION1"/
	cd "$SVNPATH"/tags/"$NEWVERSION1"

	echo "- Committing $NEWVERSION2 to WP.org..."
	svn commit --username="$2" -m "Version/Tag: $NEWVERSION1"

fi

# If assets $3 is true
if [ "$3" = "assets" ]; then 

	# Export master to SVN
    git checkout-index -a -f --prefix="$SVNPATH"/assets/
	echo "$LANG1"

    # Copy new assets
    echo "Copy new assets files"
    rsync -ahz --progress --exclude=".git" --delete "$CURRENTDIR"/assets/ "$SVNPATH"/assets/

	# More SVN Work (commit)
    cd "$SVNPATH"/assets

	# Addremove (YES!)
	svn status | grep -v "^.[ \t]*\..*" | grep "^?" | awk '{print $2}' | xargs svn add
    svn status | grep -v "^.[ \t]*\..*" | grep "^[\!D]" | awk '{ print $2}' | xargs svn rm --force
	echo LANG1

	# Commit the tag
	cd "$SVNPATH"

    echo "- Committing $NEWVERSION1 to WP.org..."
    svn commit --username="$2" -m "Assets update: $NEWVERSION1"

fi   

# Cleanup!
set -x
echo "- Removing the SVN repo at $SVNPATH"
rm -Rf "${SVNPATH:?}/"

echo "Deployment finished."
