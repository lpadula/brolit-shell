#!/bin/bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0-rc06
################################################################################
#
# Refs: 
#       https://certbot.eff.org/docs/using.html
#       https://certbot.eff.org/docs/using.html#certbot-commands
#
################################################################################

# shellcheck source=${SFOLDER}/libs/commons.sh
source "${SFOLDER}/libs/commons.sh"

################################################################################

certbot_certificate_install() {

  #$1 = EMAIL
  #$2 = DOMAINS

  local email=$1
  local domains=$2

  echo -e ${B_CYAN}" > Running: certbot --nginx --non-interactive --agree-tos --redirect -m ${email} -d ${domains}"${ENDCOLOR}
  echo " > Running: certbot --nginx --non-interactive --agree-tos --redirect -m ${email} -d ${domains}" >>$LOG
  certbot --nginx --non-interactive --agree-tos --redirect -m "${email}" -d "${domains}"

}

certbot_certificate_expand(){
  
  #$1 = EMAIL
  #$2 = DOMAINS

  local email=$1
  local domains=$2

  echo -e ${B_CYAN}" > Running: certbot --nginx --non-interactive --agree-tos --expand --redirect -m ${email} -d ${domains}"${ENDCOLOR}
  echo " > Running: certbot --nginx --non-interactive --agree-tos --expand --redirect -m ${email} -d ${domains}" >>$LOG
  certbot --nginx --non-interactive --agree-tos --expand --redirect -m "${email}" -d "${domains}"

}

certbot_certificate_renew() {

  #$1 = DOMAINS

  local domains=$1

  echo -e ${B_CYAN}" > Running: certbot renew -d ${domains}"${ENDCOLOR}
  echo " > Running: certbot renew -d ${domains}" >>$LOG
  certbot renew -d "${domains}"

}

certbot_certificate_renew_test() {

  # Test renew for all installed certificates

  echo -e ${B_CYAN}" > certbot renew --dry-run"${ENDCOLOR}
  echo " > Running: certbot renew --dry-run" >>$LOG
  certbot renew --dry-run

}



certbot_certificate_force_renew() {

  #$1 = DOMAINS

  local domains=$1

  echo -e ${B_CYAN}" > Running: certbot --nginx --non-interactive --agree-tos --force-renewal --redirect -m ${email} -d ${domains}"${ENDCOLOR}
  echo " > Running: certbot --nginx --non-interactive --agree-tos --force-renewal --redirect -m ${email} -d ${domains}" >>$LOG
  certbot --nginx --non-interactive --agree-tos --force-renewal --redirect -m "${email}" -d "${domains}"

}

certbot_renew_test() {

  #$1 = DOMAINS

  local domains=$1

  certbot renew --dry-run -d "${domains}"

}

certbot_helper_installer_menu() {

  #$1 = EMAIL
  #$2 = DOMAINS

  local email=$1
  local domains=$2

  CB_INSTALLER_OPTIONS="01 INSTALL_WITH_NGINX 02 INSTALL_WITH_CLOUDFLARE"
  CHOSEN_CB_INSTALLER_OPTION=$(whiptail --title "CERTBOT INSTALLER OPTIONS" --menu "Please choose an option:" 20 78 10 $(for x in ${CB_INSTALLER_OPTIONS}; do echo "$x"; done) 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    if [[ ${CHOSEN_CB_INSTALLER_OPTION} == *"01"* ]]; then
      certbot_certificate_install "${email}" "${domains}"
      #certbot_helper_installer_menu

    fi
    if [[ ${CHOSEN_CB_INSTALLER_OPTION} == *"02"* ]]; then
      certbot_certonly "${email}" "${domains}"
      #certbot_helper_installer_menu

    fi

  fi

}

certbot_certonly() {

  # ATENCION: creo que el mejor camino es correr primero el certbot --nginx y luego el certbot certonly
  # por que el certbot --nginx ya te modifica los archivos de configuracion de nginx y agrega los .pem etc
  # entonces al quedar ya agregados luego el certonly solo pisa esos .pem pero las referencias a esos archivos
  # ya quedaron en los archivos de conf de nginx

  # Ref: https://mangolassi.it/topic/18355/setup-letsencrypt-certbot-with-cloudflare-dns-authentication-ubuntu/2

  # $1 = EMAIL
  # $2 = DOMAINS (domain.com,www.domain.com)

  local email=$1
  local domains=$2

  echo -e ${B_CYAN}"Running: certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare.conf -m ${email} -d ${domains} --preferred-challenges dns-01"${ENDCOLOR}
  certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare.conf -m ${email} -d ${domains} --preferred-challenges dns-01

  # Maybe add a non interactive mode?
  # certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare.conf --non-interactive --agree-tos --redirect -m ${EMAIL} -d ${DOMAINS} --preferred-challenges dns-01

  echo -e ${MAGENTA}"Now you need to follow the next steps:"${ENDCOLOR}
  echo -e ${MAGENTA}"1- Login to your Cloudflare account and select the domain we want to work."${ENDCOLOR}
  echo -e ${MAGENTA}"2- Go to de 'DNS' option panel and Turn ON the proxy Cloudflare setting over the domain/s"${ENDCOLOR}
  echo -e ${MAGENTA}"3- Go to 'SSL/TLS' option panel and change the SSL setting from 'Flexible' to 'Full'."${ENDCOLOR}

}

certbot_show_certificates_info() {

  echo -e ${B_CYAN}"Running: certbot certificates"${ENDCOLOR}
  certbot certificates

}

certbot_show_domain_certificates_expiration_date() {

  # $1 = DOMAINS (domain.com,www.domain.com)

  local domains=$1

  #echo -e ${CYAN}"Running: certbot certificates --cert-name ${DOMAINS}"${ENDCOLOR}
  certbot certificates --cert-name "${domains}" | grep 'Expiry' | cut -d ':' -f2 | cut -d ' ' -f2

}

certbot_show_domain_certificates_valid_days() {

  # $1 = DOMAINS (domain.com,www.domain.com)

  local domains=$1

  #echo -e ${CYAN}"Running: certbot certificates --cert-name ${DOMAINS}"${ENDCOLOR}
  certbot certificates --cert-name "${domains}" | grep 'VALID' | cut -d '(' -f2 | cut -d ' ' -f2
}

certbot_certificate_delete() {

  # $1 = DOMAINS (domain.com,www.domain.com)

  local domains=$1

  if [[ -z "${domains}" ]]; then

    #Run certbot delete wizard
    certbot --nginx delete

  else

    while true; do
      echo -e ${YELLOW}"> Do you really want to delete de certificates for ${domains}?"${ENDCOLOR}
      read -p "Please type 'y' or 'n'" yn

      case $yn in
      [Yy]*)
        certbot delete --cert-name "${domains}"
        break
        ;;
      [Nn]*)
        echo -e ${YELLOW}"Aborting ..."${ENDCOLOR}
        break
        ;;
      *) echo " > Please answer yes or no." ;;
      esac

    done

fi

}

certbot_helper_ask_domains() {

  local domains

  domains=$(whiptail --title "CERTBOT MANAGER" --inputbox "Insert the domain and/or subdomains that you want to work with. Ex: broobe.com,www.broobe.com" 10 60 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    echo "${domains}"
    #exit 0;

  else

    exit 1;

  fi

}

certbot_helper_menu() {

  local domains certbot_options chosen_cb_options

  certbot_options="01 INSTALL_CERTIFICATE 02 EXPAND_CERTIFICATE 03 TEST_RENEW_ALL_CERTIFICATES 04 FORCE_RENEW_CERTIFICATE 05 DELETE_CERTIFICATE 06 SHOW_INSTALLED_CERTIFICATES"
  chosen_cb_options=$(whiptail --title "CERTBOT MANAGER" --menu "Please choose an option:" 20 78 10 $(for x in ${certbot_options}; do echo "$x"; done) 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    if [[ ${chosen_cb_options} == *"01"* ]]; then
      domains=$(certbot_helper_ask_domains)
      certbot_helper_installer_menu "${MAILA}" "${domains}"
      #certbot_helper_menu

    fi
    if [[ ${chosen_cb_options} == *"02"* ]]; then
      domains=$(certbot_helper_ask_domains)
      certbot_certificate_expand "${MAILA}" "${domains}"
      #certbot_helper_menu

    fi
    if [[ ${chosen_cb_options} == *"03"* ]]; then
      certbot_certificate_renew_test
      #certbot_helper_menu

    fi
    if [[ ${chosen_cb_options} == *"04"* ]]; then
      domains=$(certbot_helper_ask_domains)
      certbot_certificate_force_renew "${domains}"
      #certbot_helper_menu

    fi
    if [[ ${chosen_cb_options} == *"05"* ]]; then
      domains=$(certbot_helper_ask_domains)
      certbot_certificate_delete "${domains}"
      #certbot_helper_menu

    fi
    if [[ ${chosen_cb_options} == *"06"* ]]; then
      certbot_show_certificates_info
      read -n 1 -p "Press any key to return to the certbot menu" "mainmenuinput"
      certbot_helper_menu

    fi

  else
    prompt_return_or_finish
    certbot_helper_menu

  fi

}