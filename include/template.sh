#!/usr/bin/env bash

publish() {
   displayMessage "##### START PUBLISH STAGE"
   build "$@"
   dockerRunBash "(cd dist && npm publish --registry ${APP__REGISTRY})"
   displayMessage "##### END PUBLISH STAGE"
}

build() {
   displayMessage "##### START BUILD STAGE"
   install "$@"
   dockerRuncli npm run build
   displayMessage "##### END BUILD STAGE"
}

install() {
   displayMessage "##### START INSTALL STAGE"
   dockerRuncli npm i
   displayMessage "##### END INSTALL STAGE"
}

config() {
   REGISTRY="https://${APP_ARTIFACTORY_PATH}artifactory/api/npm/${APP__NPM_REPOSITORY_PATH}"
   npm config set "${APP__NPM_SCOPE}":registry "$REGISTRY"
   npm login --scope="${APP__NPM_SCOPE}" --registry="$REGISTRY"
}

deployDefineArgs() {
   PRESERVE_CACHE=false
   RESTART=true
   while [ $# -gt 0 ]; do
      if [[ $1 == '--preserve-cache' ]]; then
         PRESERVE_CACHE=true
      elif [[ $1 == '--no-restart' ]]; then
         RESTART=false
      fi
      shift
   done
}

deploy() {
   displayMessage "##### START DEPLOY STAGE"

   # Check params
   if [[ -z ${APP__VOLUME_TPL_DIR} ]]; then
      displayError "VOLUME_TPL_DIR is missing in env"
      exit 1
   elif [[ -z ${APP__DEVTPL_PACKAGE_DIR} ]]; then
      displayError "LOCAL_TEMPLATE_DIR is missing in env"
      exit 1
   elif [[ ! -d ${APP__DEVTPL_PACKAGE_DIR} ]]; then
      displayError "Folder ${APP__DEVTPL_PACKAGE_DIR} not found"
      exit 1
   elif [[ ! -f "${APP__DEVTPL_PACKAGE_DIR}/app/angular.json" ]]; then
      displayError "Project ${APP__DEVTPL_PACKAGE_DIR} is not a library"
      exit 1
   elif [[ $(cat "${APP__DEVTPL_PACKAGE_DIR}/app/angular.json" | jq -r '.projects | .[] | .projectType') == 'application' ]]; then
      displayError "Project ${APP__DEVTPL_PACKAGE_DIR} is not a library"
      exit 1
   fi

   # Vars
   local VOLUME_PATH="/home/$USER/${APP__VOLUME_TPL_DIR}"
   local PROJECT=$(cat "${APP__DEVTPL_PACKAGE_DIR}/app/angular.json" | jq -r '.projects | keys_unsorted[0] | sub("template-"; "")')

   deployDefineArgs "$@"

   # Run
   (cd "${APP__DEVTPL_PACKAGE_DIR}" && build "$@")
   dockerRunBash "rm -Rf ./node_modules/${APP__NPM_SCOPE}/$PROJECT/*"
   dockerRunBash "cp -R ${VOLUME_PATH}/app/dist/. ./node_modules/${APP__NPM_SCOPE}/$PROJECT"

   if [[ $PRESERVE_CACHE == false ]]; then
      echo '> Suppression du cache npm / angular'
      dockerRuncli npm cache clean --force
      dockerRunBash "rm -rf ${VOLUME_PATH}/app/.angular"
      dockerRunBash "rm -rf ./.angular"
   fi

   if [[ $RESTART == true ]]; then
      echo '> Redémarrage du service serve'
      dockerRuncli npm run start
   fi

   displayMessage "##### END DEPLOY STAGE"
}