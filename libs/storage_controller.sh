#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.3.0-beta
################################################################################
#
# Storage Controller: Controller to upload and download backups.
#
################################################################################

################################################################################
#
# Important: Backup/Restore utils selection.
#
#   Backup Uploader:
#       Simple way to upload backup file to this cloud service.
#
#   Rclone:
#       Good way to store backups on a SFTP Server and cloud services.
#       Option to "sync" files.
#       Read: https://forum.rclone.org/t/incremental-backups-and-efficiency-continued/10763
#
#   Duplicity:
#       Best way to backup projects of 10GBs+. Incremental backups.
#       Need to use SFTP option (non native cloud services support).
#       Read: https://zertrin.org/how-to/installation-and-configuration-of-duplicity-for-encrypted-sftp-remote-backup/
#
################################################################################

################################################################################
# List directory content
#
# Arguments:
#   ${1} = {remote_directory}
#
# Outputs:
#   ${remote_list}
################################################################################

function storage_list_dir() {

    local remote_directory="${1}"

    local remote_list

    if [[ ${BACKUP_DROPBOX_STATUS} == "enabled" ]]; then

        # Dropbox API returns files names on the third column
        remote_list="$(dropbox_list_directory "${remote_directory}")"

        storage_result=$?

    fi
    if [[ ${BACKUP_LOCAL_STATUS} == "enabled" ]]; then

        remote_list="$(ls "${remote_directory}")"

        storage_result=$?

        # Log
        log_event "info" "Listing directory: ${remote_directory}" "false"
        log_event "info" "Remote list: ${remote_list}" "false"
        log_event "debug" "Command executed: ls ${remote_directory}" "false"

    fi

    if [[ ${storage_result} -eq 0 && -n ${remote_list} ]]; then

        echo "${remote_list}" && return 0

    else

        return 1

    fi

}

################################################################################
# Create directory (dropbox, sftp, etc)
#
# Arguments:
#   ${1} = {file_to_download}
#   ${2} = {remote_directory}
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function storage_create_dir() {

    local remote_directory="${1}"

    local storage_result

    if [[ ${BACKUP_DROPBOX_STATUS} == "enabled" ]]; then

        dropbox_create_dir "${remote_directory}"

    fi
    if [[ ${BACKUP_LOCAL_STATUS} == "enabled" ]]; then

        mkdir --force "${BACKUP_LOCAL_CONFIG_BACKUP_PATH}/${remote_directory}"

    fi

    storage_result=$?
    [[ ${storage_result} -eq 1 ]] && return 1

}

################################################################################
# Move files or directory
#
# Arguments:
#   ${1} = {to_move}
#   ${2} = {destination}
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function storage_move() {

    local to_move="${1}"
    local destination="${2}"

    local dropbox_output
    local storage_result

    if [[ ${BACKUP_DROPBOX_STATUS} == "enabled" ]]; then

        dropbox_output="$(${DROPBOX_UPLOADER} move "${to_move}" "${destination}" 2>&1)"

        # TODO: if destination folder already exists, it will fail
        display --indent 6 --text "- Moving files to offline-projects on Dropbox" --result "DONE" --color GREEN

    fi
    if [[ ${BACKUP_LOCAL_STATUS} == "enabled" ]]; then

        move_files "${to_move}" "${destination}"

    fi

    storage_result=$?
    if [[ ${storage_result} -eq 1 ]]; then

        # Log
        log_event "error" "Moving files to offline-projects on Dropbox" "false"
        log_event "debug" "${DROPBOX_UPLOADER} move ${to_move} ${destination}" "false"
        log_event "debug" "dropbox_uploader output: ${dropbox_output}" "false"
        display --indent 6 --text "- Moving files to offline-projects on Dropbox" --result "FAIL" --color RED
        display --indent 8 --text "Please move files running: ${DROPBOX_UPLOADER} move ${to_move} ${destination}" --tcolor RED

        return 1

    fi

}

################################################################################
# Upload backup to configured storage (dropbox, sftp, etc)
#
# Arguments:
#   ${1} = {file_to_upload}
#   ${2} = {remote_directory}
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function storage_upload_backup() {

    local file_to_upload="${1}"
    local remote_directory="${2}"

    local got_error=0
    local error_type

    if [[ ${BACKUP_DROPBOX_STATUS} == "enabled" ]]; then

        dropbox_upload "${file_to_upload}" "${remote_directory}"

        [[ $? -eq 1 ]] && error_type="dropbox" && got_error=1

    fi
    if [[ ${BACKUP_LOCAL_STATUS} == "enabled" ]]; then

        # New folder
        #mkdir --force "${remote_directory}/${backup_type}"

        # New folder with $project_name
        #mkdir --force "${remote_directory}/${backup_type}/${project_name}"

        log_event "info" "Uploading backup to local storage..." "false"
        log_event "debug" "Running:  rsync --recursive  \"${file_to_upload}\" \"${BACKUP_LOCAL_CONFIG_BACKUP_PATH}/${remote_directory}\"" "false"

        rsync --recursive "${file_to_upload}" "${BACKUP_LOCAL_CONFIG_BACKUP_PATH}/${remote_directory}"

        # TODO: check if files need to be compressed (maybe an option?).

        [[ $? -eq 1 ]] && error_type="rsync,${error_type}" && got_error=1

    fi

    [[ ${error_type} != "none" ]] && echo "${error_type}"

    return ${got_error}

}

################################################################################
# Download backup from configured storage (dropbox, sftp, etc)
#
# Arguments:
#   ${1} = {file_to_download}
#   ${2} = {remote_directory}
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function storage_download_backup() {

    local file_to_download="${1}"
    local remote_directory="${2}"

    local got_error=0
    #local error_msg="none"
    local error_type="none"

    local error_type="none"

    if [[ ${BACKUP_DROPBOX_STATUS} == "enabled" ]]; then

        dropbox_download "${file_to_download}" "${remote_directory}"
        [[ $? -eq 1 ]] && error_type="dropbox" && got_error=1

    fi
    if [[ ${BACKUP_RCLONE_STATUS} == "enabled" ]]; then

        rclone_download "${file_to_download}" "${remote_directory}"
        [[ $? -eq 1 ]] && error_type="rsync" && got_error=1

    fi

    [[ ${error_type} != "none" ]] && echo "${error_type}"

    return ${got_error}
}

################################################################################
# Delete backup to configured storage (dropbox, sftp, etc)
#
# Arguments:
#   ${1} = {file_to_delete}
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function storage_delete_backup() {

    local file_to_delete="${1}"

    local got_error=0
    #local error_msg="none"
    local error_type="none"

    if [[ ${BACKUP_DROPBOX_STATUS} == "enabled" ]]; then

        dropbox_delete "${file_to_delete}" "false"
        [[ $? -eq 1 ]] && error_type="dropbox" && got_error=1

    fi
    if [[ ${BACKUP_LOCAL_STATUS} == "enabled" ]]; then

        rm --recursive --force "${file_to_delete}"
        # TODO: check if files need to be compressed (maybe an option?).
        [[ $? -eq 1 ]] && error_type="rsync" && got_error=1

    fi

    [[ ${error_type} != "none" ]] && echo "${error_type}"

    return ${got_error}

}

################################################################################
# Remote Server list from storage.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function storage_remote_server_list() {

  local remote_server_list # list servers directories
  local chosen_server      # whiptail var

  # Server selection
  remote_server_list="$(storage_list_dir "/")"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Show output
    chosen_server="$(whiptail --title "BACKUP SELECTION" --menu "Choose a server to work with" 20 78 10 $(for x in ${remote_server_list}; do echo "${x} [D]"; done) --default-item "${SERVER_NAME}" 3>&1 1>&2 2>&3)"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      log_event "debug" "chosen_server: ${chosen_server}" "false"

      echo "${chosen_server}" && return 0

    else

      return 1

    fi

  else

    log_event "error" "Storage list dir failed. Output: ${remote_server_list}. Exit status: ${exitstatus}" "false"

    return 1

  fi

}

################################################################################
# Remote Type list from storage.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function storage_remote_type_list() {

  local remote_type_list
  local chosen_restore_type

  # List options
  remote_type_list="project site database" # TODO: need to implement "other"

  chosen_restore_type="$(whiptail --title "BACKUP SELECTION" --menu "Choose a backup type. You can choose restore an entire project or only site files, database or config." 20 78 10 $(for x in ${remote_type_list}; do echo "${x} [D]"; done) 3>&1 1>&2 2>&3)"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    echo "${chosen_restore_type}" && return 0

  else

    return 1

  fi

}

################################################################################
# Remote Status list from storage.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function storage_remote_status_list() {

  local remote_status_list
  local chosen_restore_status

  # List options
  remote_status_list="online offline"

  chosen_restore_status="$(whiptail --title "BACKUP SELECTION" --menu "Choose a backup status." 20 78 10 $(for x in ${remote_status_list}; do echo "${x} [D]"; done) 3>&1 1>&2 2>&3)"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    echo "${chosen_restore_status}" && return 0

  else

    return 1

  fi

}

################################################################################
# Storage Backup selection
#
# Arguments:
#   ${1} = ${remote_backup_path}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function storage_backup_selection() {

  local remote_backup_path="${1}"

  local storage_project_list
  local chosen_project
  local remote_backup_path
  local remote_backup_list
  local chosen_backup_file

  # Get dropbox folders list
  storage_project_list="$(storage_list_dir "${remote_backup_path}/site")"

  # Select Project
  chosen_project="$(whiptail --title "BACKUP SELECTION" --menu "Choose a Project Backup to work with:" 20 78 10 $(for x in ${storage_project_list}; do echo "$x [D]"; done) 3>&1 1>&2 2>&3)"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then
    # Get backup list
    remote_backup_path="${remote_backup_path}/site/${chosen_project}"
    remote_backup_list="$(storage_list_dir "${remote_backup_path}")"

  else

    display --indent 6 --text "- Selecting Project Backup" --result "SKIPPED" --color YELLOW
    return 1

  fi

  # Select Backup File
  chosen_backup_file="$(whiptail --title "BACKUP SELECTION" --menu "Choose Backup to download" 20 78 10 $(for x in ${remote_backup_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    display --indent 6 --text "- Selecting project backup" --result "DONE" --color GREEN
    display --indent 8 --text "${chosen_backup_file}" --tcolor YELLOW

    # Remote backup path
    chosen_backup_file="${remote_backup_path}/${chosen_backup_file}"

    echo "${chosen_backup_file}"

    #storage_download_backup "${backup_to_dowload}" "${BROLIT_TMP_DIR}"
    #[[ $? -eq 1 ]] && display --indent 6 --text "- Downloading project backup" --result "ERROR" --color RED && return 1

  fi

}