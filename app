#!/usr/bin/env bash

source "$(dirname "$0")/include/common.sh"
source "$(dirname "$0")/include/docker.sh"
source "$(dirname "$0")/include/package.sh"

# Start docker project
start () {
   dockerStart "$1"
}

# Stop docker project
stop () {
   dockerStop "$@"
}

# Restart docker project
restart () {
   dockerRestart "$@"
}

# run npm inside the app container
npm () {
   dockerRunNpm "$@"
}

# run the Angular console inside the app container
ng () {
   dockerRunNpm "run ng ${*}"
}

# run bash on phpcli
bash () {
   docker compose run --rm -u "$USER":"$GROUP" nodejs sh
}

# init project
init () {
   # Login on artifactory
   dockerLogin

   # Create .npmrc if not exists
   if [ ! -f "$HOME/.npmrc" ]; then
      touch ~/.npmrc
   fi

   # Start docker
   dockerStart

   # NPM login on artifactory
   dockerRunNpm "login --scope=${APP__NPM_SCOPE} --registry=https://${APP__ARTIFACTORY_PATH}artifactory/api/npm/${APP__NPM_REPOSITORY_PATH} --auth-type=legacy"

   # Update()
   echo ""
   update
   echo ""

   displayMessage "  Project initialized successfully.
      - HTTP: http://${APP__APP_NAME}.local.gd
      - SSH (for tunnel): ssh://proxy:pass@ssh.local.gd:2222

      You can run the following command to start the project: 'bin/app npm start'
   "
}

# update project
update () {
   echo "----> Set executable"
   ls -d -1 bin/app
   chmod u+x bin/app
   echo " [OK] Set executable"

   echo ""

   echo "----> Install dependency"
   dockerRunNpm install || displayError
   echo " [OK] Dependency installed"

   echo ""
}

# remove containers, volumes and local images for this project
destroy () {
   echo "----> Remove directory"
   dockerRunBash "rm -rf node_modules"
   echo " [OK] Directories removed"
   echo ""

   echo "----> Stop and remove docker images"
   dockerStop --destroy
   echo " [OK] Docker images removed"
}

config () {
   if [[ -z $1 ]]; then
      packageInit
   elif [ "$1" == '--destroy' ]; then
      packageDestroy
   else
      displayError "Parameter \"${1}\" is not defined ! \n\n Did you mean one of these? \n    --destroy"
      exit
   fi
}

version () {
   packageVersion
}

selfupdate () {
   packageSelfUpdate
}

usage () {
    echo "usage: bin/app COMMAND [ARGUMENTS]

    selfupdate                                     Updates bin/app to the latest version.
    version                                        Display current version

    init                                           Initialize project
    config --destroy                               Initialize bin/app. Add --destroy for clean project
    destroy                                        Remove all the project Docker containers with their volumes

    start --force-recreate                         Start project
    stop --destroy --full --all                    Stop project. Add --destroy for remove images and orphans.
                                                   Add --full for stop common containers. Add --all for stop ALL DOCKER COMPOSE project.
    restart --full                                 Restart project. Add --full for restart common containers.

    npm                                            Use NPM inside the app container
    ng                                             Use the Angular console
    bash                                           Use bash inside the app container
    "
}

main () {
   if [[ -z $1 ]]; then
      usage
      exit 0
   fi

   if [[ ! $1 =~ ^(selfupdate|version|config|init|destroy|start|stop|restart|npm|ng|bash)$ ]]; then
      echo "$1 is not a supported command"
      exit 1
   fi

   # Run dotenv
   dotenv

   # Common project
   dockerGetCommonPath

   # Check if uptodate
   packageCheckIfUpToDate

   # Get current user/group
   USER='node'
   GROUP='node'

   # Run command
   "$@"
}

main "$@"