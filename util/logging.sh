#!/bin/bash

_log(){
  NOCOLOR=$(echo -en '\033[0m')
  RED=$(echo -en '\033[0;31m')
  GREEN=$(echo -en '\033[0;32m')
  BLUE=$(echo -en '\033[0;34m')

  message="${1}" color="${2^^}" type="${3}"

  echo "${BLUE}[${!color}*${BLUE}] ${!color}${message}${NOCOLOR}"
  # [ "${4}" == "y" ] && echo "[$(date +"%D @ %T")] ${type^^} - ${message}" >> "$logfile"
}

success(){
  _log "${1}" "green" "success"
}
info(){
  _log "${1}" "blue" "info"
}
error(){
  message="${1}"
  [ ! "${2}" == "n" ] && message="An unexpected error occured while ${1}. Please check the above output for details. It is recommended to create an issue on GitHub with a considerable excerpt from the above logs."
  _log "${message}" "red" "error"
}

conf(){
  echo -en '\033[0;34m'
  read -rp "${1} [y/N] " response
  echo -en '\033[0m'
  if [[ "${response}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    true
  else
    false
  fi
}
