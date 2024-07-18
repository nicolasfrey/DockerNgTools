#!/usr/bin/env bash

checkVars() {
   if [[ -z ${APP__JENKINS_TYPE} ]]; then
      echo "Args JENKINS_TYPE missing in .env"
   fi

   if [[ -z ${APP__HELM_JOB} ]]; then
      echo "Args HELM_JOB missing in .env"
   fi

   if [[ -z ${APP__BITBUCKET_PATH} ]]; then
      echo "Args BITBUCKET_PATH missing in .env"
   fi
}

gitClone() {
   tmp_dir=$(mktemp -d -t repo-XXXXXXXXXX)

   git clone ssh://git@bitbucket.groupe.pharmagest.com:7999/welsiops/welcoop-jenkins-lib.git "$tmp_dir"
}

jenkins-check() {
   checkVars

   gitClone

   local localVersion=$(grep -oP "def JENKINS_VERSION='\K[^']+" "Jenkinsfile")
   local remoteVersion=$(grep -oP "def JENKINS_VERSION='\K[^']+" "$tmp_dir"/resources/config/"${APP__JENKINS_TYPE}"/Jenkinsfile)

   echo ">> Version Jenkinsfile local : $localVersion"
   echo ">> Version Jenkinsfile remote : $remoteVersion"
   if [[ $localVersion == $remoteVersion ]]; then
     echo " [OK] - Jenkinsfile is up to date"
   else
     echo " [KO] - Jenkinsfile isn't up to date - plz run bin/app jenkins update"
   fi
}

jenkins-update() {
   checkVars

   gitClone

   cp -rf "$tmp_dir"/resources/config/"${APP__JENKINS_TYPE}"/Jenkinsfile ./Jenkinsfile
   rm -Rf "$tmp_dir"

   local version=$(grep -oP "def JENKINS_VERSION='\K[^']+" "Jenkinsfile")
   echo " [OK] - Jenkinsfile is up to date ($version)"
}