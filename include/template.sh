#!/usr/bin/env bash

installtpl() {

   local BRANCH=master

   if [[ -n $1 ]]; then 
      BRANCH=$1
   fi 

   displayMessage 'Clean if exist'
	if [[ -d bintpl ]]; then 
		rm -Rf bintpl
	fi

   git submodule deinit -f -- bintpl
   git rm -f bintpl
   
   if [[ -d .git/modules/bintpl ]]; then 
      rm -rf .git/modules/bintpl
   fi

   echo ' '
   displayMessage 'Install'
	git submodule add ssh://git@${APP__BITBUCKET_PATH}/bin.template.git bintpl

   (
      cd bintpl && 
      git checkout $BRANCH &&
      git pull 
   )

   echo ' '
   displayMessage 'bintpl/app usage'
   printf "%s\n" "$(bintpl/app)"
}