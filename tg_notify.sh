#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2020 Saurabh Charde <saurabhchardereal@gmail.com>
#

# Repos we'll fetching info from
README='https://raw.githubusercontent.com/ColtOS-Devices/official_devices/c10/README.md'
XDA='https://forum.xda-developers.com/showthread.php?t='
OTA_REPO='https://github.com/ColtOS-Devices/official_devices'

fetchInfo() {
    OTA_PATCH=$(curl -s ${OTA_REPO}/commit/${1}.patch)

    # get the basic requirement for any ota i.e, timestamp
    UNIX_DATE=$(echo "${OTA_PATCH}" | grep '^+' | grep "\"timestamp\"" | \
        awk -F"[:,]" '{print $2}' | sed 's/[[:space:]]//')

    # exit if $UNIX_DATE is empty (likely not an ota commit)
    [[ -z ${UNIX_DATE} ]] && OTA_COMMIT=false && return 1

    # covert unix timestamp to dd-"mm"-yy format
    BUILD_DATE=$(date +'%d-%b-%Y' -d @${UNIX_DATE})

    # fetch all other required info from recent ota commit patch
    FILENAME=$(echo "${OTA_PATCH}" | grep '^+' | grep "\"filename\"" | cut -d'"' -f4)
    COLT_VERSION=$(echo "${FILENAME}" | cut -d'-' -f2)
    DEVICE_CODE=$(echo "${FILENAME}" | cut -d'-' -f3)
    DEVICE_NAME=$(curl -s ${README} | grep -i ${DEVICE_CODE} | cut -d'|' -f3 | sed 's/[[:space:]]//')
    DEVICE=$(echo "${DEVICE_NAME} (${DEVICE_CODE})" | awk '$1=$1')
    MAINTAINER=$(echo "${OTA_PATCH}" | grep "From:" | awk -F"[:<]" '{print $2}' | sed 's/[[:space:]]//')
    SFLINK=$(echo "${OTA_PATCH}" | grep '^+' | grep "\"url\"" | cut -d'"' -f4)
    XDA=$(curl -s ${README} | grep -i ${DEVICE_CODE} | sed 's/.*\[XDA\]//' | awk -F"[()]" '{print $2}')

    # covert byte-size to hooman readable size (i.e, <size in bytes>/1024/1024 MB)
    SIZE=$(echo "${OTA_PATCH}" | grep '^+' | grep "\"size\"" | \
        awk -F"[:,]" '{print $2}' | awk '{printf "%.0f %s", $1/1024/1024, "MB"}')
}

getChangelog() {
    CHANGELOG_FILE=$(curl -s https://raw.githubusercontent.com/ColtOS-Devices/official_devices/c10/changelogs_${DEVICE_CODE}.txt)
    echo "$CHANGELOG_FILE" | sed -n '/device.*change.*/I,/source.*change.*/I{/device.*change.*/Ib;/source.*change.*/Ib;p}' \
        sed 's/^*/- /g' | sed '/^$/d'
}

# get latest commit hash (from branch: c10)
RECENT_COMMIT=$(git ls-remote ${OTA_REPO} | grep 'c10' | cut -f1)
fetchInfo "${RECENT_COMMIT}"

if [[ "$OTA_COMMIT" != "false" ]]; then
TG_POST=$(cat <<EOF
×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×
<b>         ColtOS Enigma - ${COLT_VERSION} - Update </b>
×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×

<b>• Build Date</b>: <i>${BUILD_DATE}</i>

<b>• Device</b>: <i>${DEVICE}</i>

<b>• Maintainer</b>: ${MAINTAINER}

<b>• ROM Changelog</b>: <a href='${ROM_CHANGELOG}'>Link</a>

<b>• Device Changelog</b>:
<i>$(getChangelog)</i>

<b>• Download</b>: <a href='${SFLINK}'>SourceForge</a> [${SIZE}]
<b>• XDA Thread</b>: <a href='${XDA}'>Here</a>

<b>• Colt Announcements</b>: @ColtOSOfficial
<b>• Colt Support</b>: @ColtEnigma
EOF
)
else
TG_POST="Timestamp could not be found or \
    <a href='${OTA_REPO}/commit/${RECENT_COMMIT}'>commit</a> is not an OTA!"
fi

# Make a nice post and send it to TG channel
# (shameless plug: check t.me/ColtOSOfficial to see this in action)
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=HTML" \
    -d text="${TG_POST}"
