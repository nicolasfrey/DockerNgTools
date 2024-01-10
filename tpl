#!/usr/bin/env bash

source "$(dirname "$0")/include/common.sh"
source "$(dirname "$0")/include/package.sh"
source "$(dirname "$0")/include/docker.sh"
source "$(dirname "$0")/include/template.sh"

createThemeVars() {
   THEME=''
   while [ $# -gt 0 ]; do
      if [[ $1 == "--"* ]]; then
         v="${1/--/}"
         if [[ $v = 'only-theme' ]]; then
            THEME=$2
         fi
         shift
      fi
      shift
   done
}

createProjectVars() {
   PROJECT=$2
   PROJECTS=$(cat app/angular.json | jq '.projects | to_entries | .[] | .key')
   if [[ ! "${PROJECTS[*]}" =~ "\""$PROJECT"\"" ]]; then
      PROJECT=''
   fi
}

checkOrigin() {
   ISLIB=true

   if [[ $(cat app/angular.json | jq -r '.projects | .[] | .projectType') == 'application' ]]; then
      ISLIB=false
   fi

   if [[ $1 == 'deploy' && $ISLIB == true ]]; then
      displayError "This command not work in angular libraries project"
      exit 1
   fi

   if [[ $1 != 'deploy' && $ISLIB == false ]]; then
      displayError "This command not work in angular application project"
      exit 1
   fi
}

usage () {
   createProjectVars

   local p=''
   local t=''
   local i=0
   for a in $PROJECTS; do
      if [[ $i -ne 0 ]]; then
        p+=" | "
      fi
      p+=${a//\"/}
      ((i=i+1))
   done;

   i=0
   for a in $(echo "${APP__THEMES}" | tr ',' "\n"); do
      if [[ $i -ne 0 ]]; then
        t+=" | "
      fi
      t+=${a//\"/}
      ((i=i+1))
   done;


   echo "usage: bin/tpl COMMAND [ARGUMENTS]

   config                                                            Configure npm registry
   install --only-theme <theme>                                      Installation des ressources. Use --only-theme for install specific theme.
   build <projet> --only-theme <theme>                               Compilation d'un projet. Use --only-theme for build specific theme.
   publish <projet>                                                  Publication d'un projet (${APP__THEMES})
   deploy <project> --preserve-cache --no-restart                    Déployer le projet en local (dev). Use --preserve-cache for keep cache. Use --no-restart for not restart serve.

ARGUMENTS :
   projet            Nom du projet à compiler                                    Requis
                     Valeur possible : $p
   --only-theme      Installation en ne compilant qu'un theme ou tous            Non requis
                     Valeur possible : null | $t

EXAMPLE :
   bin/tpl install
   bin/tpl install --only-theme default
   "
}

main() {
   # Check if uptodate
   packageCheckIfUpToDate

   # Get params
   dotenv

   # Get current user/group
   USER='node'
   GROUP='node'

   # Check method param
   if [[ -z $1 ]]; then
      usage
      exit 0
   fi

   # Methods allowed
   if [[ ! $1 =~ ^(usage|install|config|publish|build|deploy)$ ]]; then
      displayError "$1 is not a supported command"
      exit 1
   fi

   checkOrigin "$@"
   createProjectVars "$@"

   if [[ $1 =~ ^(publish|build)$ ]] && [[ $PROJECT == '' ]]; then
      displayError "Argument project <<$2>> is missing or not allowed ($PROJECTS)."
      usage
      exit 1
   fi

   # Run command
   "$@" "$THEME"
}

main "$@"
