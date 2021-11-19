#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.1.1
################################################################################

function fail2ban_installer() {

  log_subsection "Fail2ban Installer"

  # Updating Repos
  display --indent 6 --text "- Updating repositories"

  apt-get --yes update -qq >/dev/null

  clear_previous_lines "1"
  display --indent 6 --text "- Updating repositories" --result "DONE" --color GREEN

  # Installing fail2ban
  display --indent 6 --text "- Installing fail2ban"
  log_event "info" "Installing fail2ban" "false"

  # apt command
  apt-get --yes install fail2ban -qq >/dev/null

  # Log
  clear_previous_lines "1"
  display --indent 6 --text "- Installing fail2ban" --result "DONE" --color GREEN
  log_event "info" "fail2ban installation finished" "false"

}

function fail2ban_purge() {

  log_subsection "Fail2ban Installer"

  # Log
  display --indent 6 --text "- Removing fail2ban and libraries"
  log_event "info" "Removing fail2ban and libraries ..." "false"

  # apt command
  apt-get --yes purge fail2ban -qq >/dev/null

  # Log
  clear_previous_lines "1"
  display --indent 6 --text "- Removing fail2ban and libraries" --result "DONE" --color GREEN
  log_event "info" "fail2ban removed" "false"

}

function fail2ban_installer_menu() {

  package_is_installed "fail2ban"

  exitstatus=$?

  if [[ ${exitstatus} -eq 1 ]]; then

    fail2ban_installer_title="FAIL2BAN INSTALLER"
    fail2ban_installer_message="Choose an option to run:"
    fail2ban_installer_options=(
      "01)" "INSTALL FAIL2BAN"
    )

    chosen_fail2ban_installer_options="$(whiptail --title "${fail2ban_installer_title}" --menu "${fail2ban_installer_message}" 20 78 10 "${fail2ban_installer_options[@]}" 3>&1 1>&2 2>&3)"
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      if [[ ${chosen_fail2ban_installer_options} == *"01"* ]]; then

        fail2ban_installer

      fi

    fi

  else

    fail2ban_installer_title="FAIL2BAN INSTALLER"
    fail2ban_installer_message="Choose an option to run:"
    fail2ban_installer_options=(
      "01)" "UNINSTALL FAIL2BAN"
    )

    chosen_fail2ban_installer_options="$(whiptail --title "${fail2ban_installer_title}" --menu "${fail2ban_installer_message}" 20 78 10 "${fail2ban_installer_options[@]}" 3>&1 1>&2 2>&3)"
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      if [[ ${chosen_fail2ban_installer_options} == *"01"* ]]; then

        fail2ban_purge

      fi

    fi

  fi

}
