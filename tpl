#!/usr/bin/env bash

source "$(dirname "$0")/include/common.sh"
source "$(dirname "$0")/include/package.sh"
source "$(dirname "$0")/include/docker.sh"
source "$(dirname "$0")/include/template.sh"

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
   echo "usage: bin/tpl COMMAND [ARGUMENTS]

   config                                                            Configure npm registry
   install                                                           Install resources.
   build                                                             Build a project.
   publish                                                           Publish a project
   deploy --preserve-cache --no-restart                              Deploy the project locally (dev).
                                                                        * Use --preserve-cache to keep the cache.
                                                                        * Use --no-restart to not restart the server.

EXAMPLE :
   # Install
   bin/tpl install

   # Build
   bin/tpl build

   # Publish
   bin/tpl publish
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

   # Run command
   "$@" "$THEME"
}

main "$@"
