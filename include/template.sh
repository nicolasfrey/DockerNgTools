#!/usr/bin/env bash

publish() {
   displayMessage "##### START PUBLISH STAGE"
   build "$@"
   dockerRunBash "(cd dist/${APP__NPM_REPOSITORY_PATH}/${1//'wel-'/} && npm publish --registry ${APP__REGISTRY})"
   displayMessage "##### END PUBLISH STAGE"
}

build() {
   displayMessage "##### START BUILD STAGE"
   install "$@"
   dockerRuncli npm run build "$PROJECT"
   displayMessage "##### END BUILD STAGE"
}

install() {
   displayMessage "##### START INSTALL STAGE"
   if [[ ! -f app/scripts/install.sh ]]; then
      displayError "File app/scripts/install.sh not found"
   fi
   createThemeVars "$@"
   dockerRunBash "scripts/install.sh ${APP__THEMES} $THEME"
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

   if [[ -z ${APP__LOCAL_TEMPLATE_DIR} ]]; then
      displayError "LOCAL_TEMPLATE_DIR is missing in env"
      exit 1
   fi

   if [[ ! -d ${APP__LOCAL_TEMPLATE_DIR} ]]; then
      displayError "Folder ${APP__LOCAL_TEMPLATE_DIR} not found"
      exit 1
   fi

   deployDefineArgs "$@"

   if [[ $PRESERVE_CACHE == false ]]; then
      echo '> Suppression du cache npm / angular'
      dockerRuncli npm cache clean --force
      dockerRunBash "rm -rf ${APP__LOCAL_TEMPLATE_DIR}/app/.angular"
      dockerRunBash "rm -rf ./app/.angular"
   fi

   PROJECT=$1
   (cd "${APP__LOCAL_TEMPLATE_DIR}" && build "$@")
   dockerRunBash "rm -Rf ./node_modules/${APP__NPM_SCOPE}/${1//'wel-'/}/*"
   dockerRunBash "cp -R ${APP__LOCAL_TEMPLATE_DIR}/app/dist/${APP__NPM_SCOPE}/${1//'wel-'/}/. ./node_modules/${APP__NPM_SCOPE}/${1//'wel-'/}"

   if [[ $RESTART == true ]]; then
      echo '> Redémarrage du service serve'
      dockerRuncli npm run start
   fi

   displayMessage "##### END DEPLOY STAGE"
}
