#!/usr/bin/env bash

publish() {
   displayMessage "##### START PUBLISH STAGE"
   build
   dockerRunBash "(cd dist && npm publish --registry ${APP__REGISTRY})"
   displayMessage "##### END PUBLISH STAGE"
}

build() {
   displayMessage "##### START BUILD STAGE"
   install
   dockerRunNpm "run build"
   displayMessage "##### END BUILD STAGE"
}

install() {
   displayMessage "##### START INSTALL STAGE"
   dockerRunNpm "install"
   if [[ -f app/scripts/install.sh ]]; then
      dockerRunBash "scripts/install.sh"
   fi
   displayMessage "##### END INSTALL STAGE"
}

config() {
   REGISTRY="https://${APP_ARTIFACTORY_PATH}artifactory/api/npm/${APP__NPM_REPOSITORY_PATH}"
   dockerRunNpm "config set ${APP__NPM_SCOPE}:registry $REGISTRY"
   dockerRunNpm "login --scope=${APP__NPM_SCOPE} --registry=$REGISTRY --auth-type=legacy"
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

   if [[ -z ${APP__VOLUME_PACKAGE_DIR} ]]; then
      displayError "VOLUME_PACKAGE_DIR is missing in env"
      exit 1
   elif [[ -z ${APP__LOCAL_PACKAGE_DIR} ]]; then
      displayError "LOCAL_PACKAGE_DIR is missing in env"
      exit 1
   elif [[ ! -d ${APP__LOCAL_PACKAGE_DIR} ]]; then
      displayError "Folder ${APP__LOCAL_PACKAGE_DIR} not found"
      exit 1
   fi

   local VOLUME_PATH="/home/$USER/${APP__VOLUME_PACKAGE_DIR}"

   deployDefineArgs "$@"

   (cd "${APP__LOCAL_PACKAGE_DIR}" && build)
   local PKG_NAME=$(jq -r '.name' "${APP__LOCAL_PACKAGE_DIR}"/app/dist/package.json  | sed "s|${APP__NPM_SCOPE}/||")
   dockerRunBash "rm -Rf ./node_modules/${APP__NPM_SCOPE}/$PKG_NAME/*"
   dockerRunBash "cp -R ${VOLUME_PATH}/app/dist/. ./node_modules/${APP__NPM_SCOPE}/$PKG_NAME"

   if [[ $PRESERVE_CACHE == false ]]; then
      echo '> Suppression du cache npm / angular'
      dockerRunNpm "cache clean --force"
      dockerRunBash "rm -rf ${VOLUME_PATH}/app/.angular"
      dockerRunBash "rm -rf ./.angular"
   fi

   if [[ $RESTART == true ]]; then
      echo '> Redémarrage du service serve'
      dockerRunNpm "run start"
   fi

   displayMessage "##### END DEPLOY STAGE"
}

new() {
   if [[ ! -d $2 ]]; then
      displayError "Parent folder $2 not found"
      exit 1
   fi

   local BASE_PATH="$(pwd)"
   local TEMPLATES_PATH="$BASE_PATH/bin/template/"

   local PKG_NAME="template.$1"
   local LIB_NAME="template-$1"

   local ANGULAR_CLI_VERSION=$(jq -r '.devDependencies["@angular/cli"]' app/package.json)

   cd "$2" || exit # Déplacement parent structure dir

   displayMessage "Create angular workspace <<$PKG_NAME>>"
   echo "> $2/$PKG_NAME"
   mkdir "$PKG_NAME" "$PKG_NAME/app" || exit 1

   displayMessage '>>> Create bases files'
   cp "$TEMPLATES_PATH/docker-compose.yml.tpl" "$PKG_NAME/docker-compose.yml" && echo "> $2/$PKG_NAME/docker-compose.yml"
   cp "$TEMPLATES_PATH/package.json.tpl" "$PKG_NAME/package.json" && echo "> $2/$PKG_NAME/package.json"
   cp "$BASE_PATH/.env" "$PKG_NAME/.env" && echo "> $2/$PKG_NAME/.env"

   cd "$PKG_NAME" || exit 2 # Déplacement project dir
   mkdir .docker .docker/node || exit 1
   touch ".docker/node/Dockerfile" || exit 1
   {
      echo "FROM ${APP__ARTIFACTORY_PATH}${APP__DOCKER_REPOSITORY_PATH}node/18:latest"
      echo "USER root"
      echo "USER RUN npm i -g @angular/cli@$ANGULAR_CLI_VERSION"
      echo "USER node"
   } > ".docker/node/Dockerfile" && echo "> $2/$PKG_NAME/.docker/node/Dockerfile" || exit 1

   displayMessage "Add DockerNgTools"
   git clone --branch master https://github.com/nicolasfrey/DockerNgTools.git bin && bin/app config || exit 1

   displayMessage 'Create angular project (library)'
   dockerRunBash "ng new $1 --no-create-application --directory=. --skip-install" || exit 1

   displayMessage 'Generate lib'
   dockerRunBash "ng generate library $LIB_NAME --skip-install --project-root=projects" || exit 1

   displayMessage 'Configuration'
   echo '> Rewriting the file app/projects/ng-package.json'
   jq --arg new_dest '../dist' '.dest = $new_dest' app/projects/ng-package.json > temp.json && mv temp.json app/projects/ng-package.json || exit 1

   echo '> Rewriting the file app/projects/package.json'
   jq --arg new_name "${APP__NPM_SCOPE}/$1" '.name = $new_name' app/projects/package.json > temp.json && mv temp.json app/projects/package.json || exit 1

   echo '> Rewriting the file app/projects/tsconfig.lib.json'
   cp "$TEMPLATES_PATH/tsconfig.lib.json.tpl" app/projects/tsconfig.lib.json || exit 1

   echo '> Rewriting the file app/.editorconfig'
   cp "$TEMPLATES_PATH/.editorconfig.tpl" app/.editorconfig || exit 1

   echo '> Rewriting the file app/.eslintrc.json'
   cp "$TEMPLATES_PATH/.eslintrc.json.tpl" app/.eslintrc.json || exit 1

   echo '> Rewriting the file app/.prettierrc'
   cp "$TEMPLATES_PATH/.prettierrc.tpl" app/.prettierrc || exit 1

   echo '> Rewriting the file app/angular.json'
   jq '.projects."'"$LIB_NAME"'"|.cli.schematicCollections += ["@angular-eslint/schematics"]' app/angular.json > app/angular.json.tmp && mv app/angular.json.tmp app/angular.json

   echo '> Rewriting the file app/package.json'
   jq --arg new_name "$PKG_NAME" '.name = $new_name' app/package.json > temp.json && mv temp.json app/package.json || exit 1

   echo '> Remove the tmp file package.json'
   rm package.json || exit 1

   echo '> Add install entrypoint scripts/install.sh'
   mkdir scripts || exit 1
   touch scripts/install.sh || exit 1
   echo '#!/usr/bin/env bash' > scripts/install.sh

   displayMessage 'Add dev libs'
   echo "> Add prettier"
   echo "> Add @types/node"
   echo "> Add @angular-eslint/schematics"
   dockerRunNpm "i --save-dev prettier @types/node @angular-eslint/schematics@$ANGULAR_CLI_VERSION" || exit 1
   echo "> Add prettier commands in app/package.json"
   jq '.scripts += { "format:check": "prettier --list-different 'projects/**/*.ts'", "format:write": "prettier --write 'projects/**/*.ts'" }' app/package.json > app/package.json.tmp && mv app/package.json.tmp app/package.json || exit 1

   displayMessage "Run it\r\n    >>> cd $2/$PKG_NAME && bin/app init"
}
