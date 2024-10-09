#!/bin/bash

#
# this script installs the Egnyte WebEdit LaunchAgent into /Library/LaunchAgent
# Egnyte's installer places this file into a user's LaunchAgent folder. If
# installed by root, the end user likely will never get the LaunchAgent.
#

# LaunchAgent locations
appLA="/Applications/Egnyte WebEdit.app/Contents/Resources/com.egnyte.egnyteWebEdit.plist"
libLA="/Library/LaunchAgents/com.egnyte.egnyteWebEdit.plist"

# Egnyte WebEdit Uninstaller app.
# uncomment if you want to delete the uninstaller app
# ewe_uninstaller="/Applications/Uninstall Egnyte WebEdit.app"

# variable to control if we want to load the LaunchAgent. There isn't a need to
# if the user is logged out.
shouldLoadAgent=true

# get user, default method and backup method
theUser=$(/usr/bin/stat -f "%Su" /dev/console)
if [[ "$theUser" == "root" ]]; then
    theUser=$(/usr/bin/defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName)
    shouldLoadAgent=false
fi

# get the UID
uid=$(/usr/bin/id -u "$theUser")

# check if the Egnyte installer loaded the LA incorrectly as root
# && unload it if they still haven't fixed this bug
/bin/launchctl print system/com.egnyte.egnyteWebEdit 2> /dev/null > /dev/null \
    && /bin/launchctl bootout system/com.egnyte.egnyteWebEdit

# unload the user's LA in case Egnyte failed to unload it during an update
/bin/launchctl print gui/$uid/com.egnyte.egnyteWebEdit 2> /dev/null > /dev/null \
    && /bin/launchctl bootout gui/$uid/com.egnyte.egnyteWebEdit

# copy the LaunchAgent from the app bundle into the proper spot
/bin/cp "$appLA" "$libLA"
# Egnyte's LaunchAgent has a generic path to launch the WebEdit app. Egnyte
# updates it in their post-install script. Since their post-install script drops
# the "fixed" version into root/lib/la but we're copying it from the app bundle,
# we need to run a similar fix.
/usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 /Applications/Egnyte WebEdit.app/Contents/MacOS/Egnyte WebEdit" "$libLA"
# set ownership permissions
/usr/sbin/chown root:wheel "$libLA"
# set Unix permissions
/bin/chmod 644 "$libLA"

# delete the Uninstall Egnyte WebEdit app
# uncomment if you want to delete the uninstaller app
# if [[ -e "$ewe_uninstaller" ]]; then
#     /bin/rm -r "$ewe_uninstaller"
# fi

# if the user is logged in, load the correctly placed LA as the user
if [[ $shouldLoadAgent == true ]]; then
    /bin/launchctl bootstrap gui/$uid $libLA \
        || echo "error loading LaunchAgent."
fi

exit 0
