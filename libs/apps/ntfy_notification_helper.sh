#!/usr/bin/env bash
#
# Author: GauchoCode - A Software Development Agency - https://gauchocode.com
# Version: 3.3.8
################################################################################


################################################################################
# Ntfy send notification
#
################################################################################

function ntfy_send_notification() {

    local notification_title="${1}"
    local notification_content="${2}"
    local notification_type="${3}"

    echo ${notification_title}

    curl -H "Title: ${notification_title}" -d "${notification_content}" -u "${NOTIFICATION_NTFY_USERNAME}:${NOTIFICATION_NTFY_PASSWORD}" "${NOTIFICATION_NTFY_SERVER}/${NOTIFICATION_NTFY_TOPIC}"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        # Log on success
        log_event "info" "ntfy notification sent!"
        display --indent 6 --text "- Sending ntfy notification" --result "DONE" --color GREEN

        return 0

    else
        # Log on failure
        log_event "error" "ntfy notification error." "false"
        log_event "error" "Please, check server url on .brolit_conf.json" "false"
        display --indent 6 --text "- Sending ntfy notification" --result "FAIL" --color RED
        display --indent 8 --text "Check server url on .brolit_conf.json" --tcolor YELLOW

        return 1

    fi
}