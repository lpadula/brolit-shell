#!/bin/bash

# Por cada direcorio existenten en /www/var generar un archivo .yml

BROLIT_MAIN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BROLIT_MAIN_DIR=$(cd "$(dirname "${BROLIT_MAIN_DIR}")" && pwd)

[[ -z "${BROLIT_MAIN_DIR}" ]] && exit 1 # error; the path is not accessible

directorio="/var/www"

if [ ! -d "$directorio" ]; then
	echo "El directorio '$directorio' no existe"
	exit 1
fi

function _json_read_field() {

    local json_file="${1}"
    local json_field="${2}"

    local json_field_value

    json_field_value="$(cat "${json_file}" | jq -r ".${json_field}")"

    # Return
    echo "${json_field_value}"

}

function _brolit_configuration_load_backup_borg() {
    local server_config_file="${1}"

    #Globals
    declare -g BACKUP_BORG_USER
    declare -g BACKUP_BORG_SERVER
    declare -g BACKUP_BORG_PORT
    declare -g BACKUP_BORG_GROUP

    BACKUP_BORG_STATUS="$(_json_read_field "${server_config_file}" "BACKUPS.methods[].borg[].status")"

    if [[ ${BACKUP_BORG_STATUS} == "enabled" ]]; then

        BACKUP_BORG_USER="$(_json_read_field "${server_config_file}" "BACKUPS.methods[].borg[].config[].user")"
        [[ -z "${BACKUP_BORG_USER}" ]] && die "Error reading BACKUP_BORG_USER from server config file."

        BACKUP_BORG_SERVER="$(_json_read_field "${server_config_file}" "BACKUPS.methods[].borg[].config[].server")"
        [[ -z "${BACKUP_BORG_SERVER}" ]] && die "Error reading BACKUP_BORG_SERVER from server config file."

        BACKUP_BORG_PORT="$(_json_read_field "${server_config_file}" "BACKUPS.methods[].borg[].config[].port")"
        [[ -z "${BACKUP_BORG_PORT}" ]] && die "Error reading BACKUP_BORG_PORT from server config file."

        BACKUP_BORG_GROUP="$(_json_read_field "${server_config_file}" "BACKUPS.methods[].borg[].config[].group")"
        [[ -z "${BACKUP_BORG_GROUP}" ]] && die "Error reading BACKUP_BORG_GROUP from server config file."

    fi 

    export BACKUP_BORG_STATUS BACKUP_BORG_USER BACKUP_BORG_SERVER BACKUP_BORG_PORT BACKUP_BORG_GROUP
}

# shellcheck source=${BROLIT_MAIN_DIR}/libs/commons.sh

	# Iteramos las carpetas sobre el directorio

_brolit_configuration_load_backup_borg "/root/.brolit_conf.json"

echo $BACKUP_BORG_GROUP

echo ${BACKUP_BORG_GROUP}


if [ "${BACKUP_BORG_STATUS}" == "enabled" ]; then
	for carpeta in "$directorio"/*; do
	if [ -d "$carpeta" ]; then
			nombre_carpeta=$(basename "$carpeta")
			archivo_yml="$nombre_carpeta.yml"

			if [ $nombre_carpeta == "html" ]; then
				continue
			fi

			if [ ! -f "/etc/borgmatic.d/$archivo_yml" ]; then
				borgmatic config generate --destination "/etc/borgmatic.d/$archivo_yml"
				cp /root/brolit-shell/config/borg/borgmatic.template.yml "/etc/borgmatic.d/$archivo_yml"

				PROJECT=$nombre_carpeta yq -i '.constants.project = strenv(PROJECT)' "/etc/borgmatic.d/$archivo_yml"
				GROUP=$BACKUP_BORG_GROUP yq -i '.constants.group = strenv(GROUP)' "/etc/borgmatic.d/$archivo_yml"
				HOST=$HOSTNAME yq -i '.constants.hostname = strenv(HOST)' "/etc/borgmatic.d/$archivo_yml"
				USER=$BACKUP_BORG_USER yq -i '.constants.username = strenv(USER)' "/etc/borgmatic.d/$archivo_yml"
				SERVER=$BACKUP_BORG_SERVER yq -i '.constants.server = strenv(SERVER)' "/etc/borgmatic.d/$archivo_yml"
				PORT=$BACKUP_BORG_PORT yq -i '.constants.port = strenv(PORT)' "/etc/borgmatic.d/$archivo_yml"
				echo "Archivo $archivo_yml generado."
				echo "Esperando 3 segundos..."
				sleep 3
			else
				echo "El archivo $archivo_yml ya existe."	
				sleep 1
			fi	
			echo "Inicializando repo"
			ssh -p ${BACKUP_BORG_PORT} ${BACKUP_BORG_USER}@${BACKUP_BORG_SERVER} 'mkdir -p /home/applications/'$BACKUP_BORG_GROUP'/'$hostname'/projects-online/site/'$nombre_carpeta''
			sleep 1
			borgmatic init --encryption=none --config "/etc/borgmatic.d/$archivo_yml"
		fi
	done
else
	echo "Borg no esta habilitado"
fi