#!/usr/bin/env bash
# Installs and uninstalls applescripts
set -euo pipefail

__install_script() {
	if [[ ! -d "${SCRIPT_DIR}" ]]; then
		mkdir -p "${SCRIPT_DIR}"
	fi
	if [[ "${TARGET}" == "all" ]]; then
		for file in scripts/*; do
			cp "${file}" "${SCRIPT_DIR}"
		done
	elif [[ -f "${TARGET}" ]]; then
		cp "${TARGET}" "${SCRIPT_DIR}"
	else
		echo "${TARGET} is not an installable script."
		__usage
	fi
}

__install_daemon() {
	if [[ "${TARGET}" == "all" ]]; then
		for file in launchd/*; do
			sed -e "s|{home}|${HOME}|" <"${file}" >"${LAUNCHD_DIR}/"
			launchctl load "${LAUNCHD_DIR}/${file}"
		done
	elif [[ -f "${TARGET}" ]]; then
		sed -e "s|{home}|${HOME}|" <"launchd/${REVERSE_DOM}.${TARGET%.*}.plist" >"${LAUNCHD_DIR}/"
		launchctl load "${LAUNCHD_DIR}/${REVERSE_DOM}.${TARGET%.*}"
	fi
}

__teardown() {
	if [[ "${TARGET}" == "all" ]]; then
		for file in launchd/*; do
			launchctl unload "${LAUNCHD_DIR}/${file}"
			rm "${LAUNCHD_DIR}/${file}"
		done
		for file in scripts/*; do
			rm "${SCRIPT_DIR}/${file}"
		done
		echo "Removed all scripts."
	else
		launchctl unload "${LAUNCHD_DIR}/${REVERSE_DOM}.${TARGET%.*}.plist"
		rm "${LAUNCHD_DIR}/${REVERSE_DOM}.${TARGET%.*}.plist"
		rm "${SCRIPT_DIR}/${file}"
		echo "Removed ${TARGET}"
	fi
}

__usage() {
	cat <<EOF
Usage: $0 <action> <target>

action              one of {install, uninstall}
target              a script in /scripts, or {all} to
                      install/uninstall all scripts
EOF
	exit 1
}

if [[ $# -lt 2 ]]; then
	__usage
fi

ACTION="${1}"
TARGET="${2}"
SCRIPT_DIR="${HOME}/Library/Scripts"
LAUNCHD_DIR="${HOME}/Library/LaunchAgents"
REVERSE_DOM="net.flurie.applescript"

case ${ACTION} in

install)
	__install_script
	__install_daemon
	echo "Installed ${TARGET}"
	;;

uninstall)
	__teardown
	;;

*)
	echo "Action ${1} not supported."
	__usage
	;;
esac
