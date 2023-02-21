#!/usr/bin/env bash

BRANCHE='master'

# Version
packageVersion () {
   echo ""
   echo -e "\e[34mbin/app\e[39m version \e[33m$(packageGetVersion)\e[39m"
   echo ""

   packageIsUpToDate
}

packageGetVersion () {
   cat ./bin/VERSION
}

packageGetGitVersion () {
   curl -s "https://raw.githubusercontent.com/nicolasfrey/DockerNgTools/${BRANCHE}/VERSION"
}

packageIsUpToDate () {
   GIT_VERSION=$(versionToInt "$(packageGetGitVersion)")
   LOCAL_VERSION=$(versionToInt "$(packageGetVersion)")

   if [ "$LOCAL_VERSION" \< "$GIT_VERSION" ]; then
      echo -e "\e[31mUne nouvelle version est disponible (\e[33m$(packageGetGitVersion)\e[31m). Pensez à mettre à jour votre version avec la commande \"\e[39mbin/app selfupdate\e[31m\"\e[39m\n"
   fi
}

packageCheckIfUpToDate() {
   [ -f "$FILE" ]; touch ./bin/.last_check_version

   if [ "$(find ./bin -name '.last_check_version' -mtime +7)" ]; then
      packageIsUpToDate
   fi
}

packageSelfUpdate () {
   rm -rf ./bin
   git clone --branch ${BRANCHE} https://github.com/nicolasfrey/DockerNgTools.git bin
   packageCleanDirectory
   bin/app version
}

packageDestroy() {
   echo "----> Clean project directories"
   echo " [OK] Directories clean"
}

packageInit () {
   echo "----> Clean Git and directory structure"
   packageCleanDirectory
   echo " [OK] Directories remove"
}

# Remove unnecessary folders
packageCleanDirectory () {
   rm -rf bin/.git
}