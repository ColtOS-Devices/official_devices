DEVICE_JSON_URL="https://raw.githubusercontent.com/ColtOS-Devices/official_devices/c11"
DEVICE_CHANGELOG_URL="https://raw.githubusercontent.com/ColtOS-Devices/official_devices/c11/changelogs"
CHANGED_FILE="$(git diff --name-only HEAD~1 | head -1)"

if ! [[ "${CHANGED_FILE}" =~ "json" ]]; then
    echo "Skipping since no json file was changed!"
    exit 0
fi

# Grab necessary stuff from uodated json file
COLT_VERSION="$(jq '.filename' "${CHANGED_FILE}" | cut -d'-' -f3)"
BUILD_DATE="$(date +'%d-%b-%Y' -d @$(jq .datetime ${CHANGED_FILE}))"
DEVICE_NAME="$(jq -r '.devicename' "${CHANGED_FILE}")"
DEVICE_CODE="$(jq '.filename' "${CHANGED_FILE}" | cut -d'-' -f4)"
MAINTAINER="$(jq -r '.maintainer' "${CHANGED_FILE}")"
CHANGELOG="${DEVICE_CHANGELOG_URL}/${DEVICE_CODE}/$(jq -r '.filename' "${CHANGED_FILE}")"
SFLINK="$(jq -r '.url' "${CHANGED_FILE}")"
SIZE="$(jq .size "${CHANGED_FILE}" | awk '{printf "%.0f %s", $1/1024/1024, "MB"}')"

# Format post
read -r -d '' msg <<EOF
×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×
<b>         ColtOS Enigma - ${COLT_VERSION} - Update </b>
×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×=×

<b>• Build Date</b>: <i>${BUILD_DATE}</i>

<b>• Device</b>: <i>${DEVICE_NAME} (${DEVICE_CODE})</i>

<b>• Maintainer</b>: <i>${MAINTAINER}</i>

<b>• Changelog</b>: <a href='${CHANGELOG}.txt'>Link</a>

<b>• Download</b>: <a href='${SFLINK}'>SourceForge</a> [${SIZE}]

<b>• Colt Announcements</b>: @ColtOSOfficial
<b>• Colt Support</b>: @ColtEnigma
EOF

# Make a nice post and send it to TG channel
# (shameless plug: check t.me/ColtOSOfficial to see this in action)
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=HTML" \
    -d text="$msg"
