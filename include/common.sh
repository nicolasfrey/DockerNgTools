#!/usr/bin/env bash

displayError () {
   TEXT=${1:-"An error occurred !!! Please, check your command history."}

   echo -e "\e[41m"
   echo -e "\n ${TEXT}"
   echo -e "\e[49m"
   exit
}

displayMessage () {
   TEXT=${1}

   echo -e "\e[44m\e[30m"
   echo -e "\n ${TEXT}"
   echo -e "\e[49m\e[39m"
}

displayWarning () {
   TEXT=${1}
   echo -e "\e[31m${TEXT}\e[39m"
}

# .env loading in the shell
dotenv () {

   if [[ ! -f .env ]]; then
      displayError "Config file not found. Check, if you have .env file !"
   fi

   checkLineSeparators ".env"

   # Ajout d'un prefix APP__ sur les variables, sinon, on a un conflit avec docker
   if [[ -f .env ]]; then
      # shellcheck disable=SC2046
      eval $(grep -v -e "^#" .env | sed "/^$/d" | xargs -I {} echo export \'APP__{}\')
   fi

   if [[ -f .env.local ]]; then
      # shellcheck disable=SC2046
      eval $(grep -v -e "^#" .env.local | sed "/^$/d" | xargs -I {} echo export \'APP__{}\')
   fi
}

checkLineSeparators() {
   if isDosFile "$1" ; then
      echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo -e "! Check line separator configuration for $1"
      echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      exit 1
   fi
}

isDosFile () {
   if [[ -f $1 ]]; then
      [[ $(dos2unix < $1 | cmp - $1 | wc -c) -gt 0 ]]
   fi
}

testParam () {
   local PARAM=${1}
   local PARAM_NAME=${2}

   if [[ -n "${PARAM}" ]] && [[ ${PARAM} != "--${PARAM_NAME}" ]]; then
      echo -e "\e[41m"
      echo -e "\n Parameter \"${PARAM}\" is not defined ! \n\n Did you mean one of these? \n    --${PARAM_NAME}"
      echo -e "\e[49m"
      exit
   fi
}

versionToInt() {
    local IFS=.
    parts=($1)
    let val=1000000*parts[0]+1000*parts[1]+parts[2]
    echo $val
}