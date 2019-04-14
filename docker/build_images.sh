#!/bin/bash
#

#
# Author:      Crypto Currency Exchange s.r.o. /  Martin Holy
# Created:     Prague, Apr 14, 2019
# Description: Build docker images for the flux deployment operator
#

##CBR
# CHECKS BEFORE RUN
##
function usage() {
  local err_sev="${1}"
  local err_msg="${2}"
  
  echo -e "\n${err_sev}: ${err_msg}."
  echo -e "\nPrerequisite:"
  echo -e "\tDockerfiles in the same folder with the specification of the application name,"
  echo -e "\te.g. Dockerfile-flux"
  echo -e "\nUsage:"
  echo -e "\t$(dirname ${0})/$(basename ${0}) \"<IMAGE_MAINTAINER>\" \"<IMAGE_VENDOR>\" \"ENVIRONMENT\","
  echo -e "\te.g. $(dirname ${0})/$(basename ${0}) \"Crypto Currency Exchange s.r.o.\" \"Crypto Currency Exchange s.r.o. / Martin Holy\" \"cceshop\"\n"
}

if [ "${1}" == "help" ] || [ "${1}" == "--help" ] || [ "${1}" == "-h" ]
then
  usage "Info" "Help output"
  exit 0
fi

if [[ $# -ne 3 ]]
then
  usage "Error" "Missing argument/s"
  exit 1
fi

##C&V
# CONSTANTS & VARIABLES
##
readonly GIT_REPO=`git remote get-url origin`
readonly GIT_COMMIT=`git rev-parse --short HEAD | tr -d '\n'`
readonly IMAGE_MAINTAINER="${1}"
readonly IMAGE_VENDOR="${2}"
readonly ENV="`echo ${3} | tr 'A-Z' 'a-z'`"
declare -a l_dockerregs=("quay.io")
declare -a l_dockerfiles=(`ls "$(dirname ${0})/"| grep 'Dockerfile'`)

##M
# MAIN
##
if [[ ${#l_dockerfiles[*]} -lt 1 ]]
then
   usage "Error" "No Dockerfile/s found"
   exit 2
fi  
  
for f in ${l_dockerfiles[@]}
do
  IMAGE_NAME=${f#Dockerfile-}
  IMAGE_VERSION=$(grep 'FROM' ${f} | head -n 1 | awk '{ print $2 }' | rev | cut -f 1 -d ':' | rev)
  IMAGE_FROM=$(grep 'FROM' ${f} | head -n 1 | awk '{ print $2 }')

  docker build --build-arg CCE_GIT_REPOSITORY="${GIT_REPO}" \
               --build-arg CCE_GIT_COMMIT="${GIT_COMMIT}" \
               --build-arg CCE_IMAGE_MAINTAINER="${IMAGE_MAINTAINER}" \
               --build-arg CCE_IMAGE_VENDOR="${IMAGE_VENDOR}" \
               --build-arg CCE_IMAGE_ORIGIN="${IMAGE_FROM}" \
               -t "${l_dockerregs[0]}/${ENV}/${IMAGE_NAME}:${IMAGE_VERSION}" \
               -f "$(dirname ${0})/Dockerfile-${IMAGE_NAME}" "$(dirname ${0})"
 
  for reg in ${l_dockerregs[@]}
  do             
    docker tag "${l_dockerregs[0]}/${ENV}/${IMAGE_NAME}:${IMAGE_VERSION}" "${reg}/${ENV}/${IMAGE_NAME}:${IMAGE_VERSION}"
    docker tag "${reg}/${ENV}/${IMAGE_NAME}:${IMAGE_VERSION}" "${reg}/${ENV}/${IMAGE_NAME}:latest"
    docker push "${reg}/${ENV}/${IMAGE_NAME}:${IMAGE_VERSION}"
    docker push "${reg}/${ENV}/${IMAGE_NAME}:latest"
  done          
done

exit 0
