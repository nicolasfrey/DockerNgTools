#!/usr/bin/env bash

source "$(dirname "$0")/include/common.sh"
source "$(dirname "$0")/include/package.sh"
source "$(dirname "$0")/include/docker.sh"
source "$(dirname "$0")/include/template.sh"

checkOrigin() {
   if [[ $1 == 'new' ]]; then
      return
   fi

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

   config                                                            Configure npm registry.
   install                                                           Install resources.
   build                                                             Build a package.
   publish                                                           Publish a package.
   new <name> <parent-dir>                                           Create and configure new package.
   deploy --preserve-cache --no-restart                              Deploy the package locally (dev).
                                                                        * Use --preserve-cache to keep the cache.
                                                                        * Use --no-restart to not restart the server.

EXAMPLE :
   # Install
   bin/tpl install

   # Build
   bin/tpl build

   # Publish
   bin/tpl publish

   # New
   ## My struct is /home/user/projects
   ## I'm in a project that already has the script bin/tpl (ex: /home/user/projects/template.pkg1)
   ## I want to create template.pkg2
   bin/tpl new pkg2 /home/user/projects
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
   if [[ ! $1 =~ ^(usage|install|config|publish|build|new|deploy)$ ]]; then
      displayError "$1 is not a supported command"
      exit 1
   fi

   if [[ $1 == 'new' ]] && [[ -z $2 ]]; then
      displayError "Missing package name"
      exit 1
   fi

   checkOrigin "$@"

   # Run command
   "$@"
}

main "$@"
