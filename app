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
   dockerRuncli npm "$@"
}

# run the Angular console inside the app container
ng () {
   dockerRuncli ng "$@"
}

# run bash on phpcli
bash () {
   dockerRuncli sh
}

# init project
init () {
   # Login on artifactory
   dockerLogin

   # Start docker
   dockerStart

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
   dockerRuncli npm install || displayError
   echo " [OK] Dependency installed"

   echo ""
}

# remove containers, volumes and local images for this project
destroy () {
   echo "----> Stop and remove docker images"
   dockerStop --destroy
   echo " [OK] Docker images removed"
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

   if [[ ! $1 =~ ^(selfupdate|version|init|destroy|start|stop|restart|npm|ng|bash)$ ]]; then
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