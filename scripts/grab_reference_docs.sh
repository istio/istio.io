#!/bin/bash

# This script copies generated .pb.html files, which contain reference docs for protos, and installs
# them in their targeted location within the content/docs/reference tree of this repo. Each .pb.html file contains a
# line that indicates the target directory location. The line is of the form:
#
#  location: https://istio.io/docs/reference/...
#
# Additionally, this script also builds Istio components and runs them to extract their command-line docs which it
# copies to content/docs/reference/commands.

#set -e

ISTIO_BRANCH=master

#####################

ISTIO_BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
export GOPATH=$(mktemp -d)
WORK_DIR=${GOPATH}/src/istio.io
COMMAND_DIR=$ISTIO_BASE/content/docs/reference/commands

# Get the source code
mkdir -p ${WORK_DIR}
pushd $WORK_DIR
git clone https://github.com/istio/api.git
cd api
git checkout $ISTIO_BRANCH
cd ..
git clone https://github.com/istio/istio.git
cd istio
git checkout $ISTIO_BRANCH
cd ..
popd

# Given the name of a .pb.html file, extracts the $location marker and then proceeds to
# copy the file to the corresponding content/docs/ hierarchy.
locate_file() {
    FILENAME=$1

    LOCATION=$(grep '^location: https://istio.io/docs' $FILENAME)
    LEN=${#LOCATION}
    if [ $LEN -eq 0 ]
    then
        echo "No 'location:' tag in $FILENAME, skipping"
        return
    fi
    FNP=${LOCATION:31}
    FN=$(echo $FNP | rev | cut -d'/' -f1 | rev)
    FN=${FN%.html}
    PP=$(echo ${FNP} | rev | cut -d'/' -f2- | rev)
    mkdir -p content/docs${PP}/${FN}
    sed -e 's/href="https:\/\/istio.io/href="/g' ${FILENAME} >content/docs${PP}/${FN}/index.html
}

# Given the path and name to an Istio command, builds the command and then
# runs it to extract its command-line docs
#
# TODO: Even though this CDs into the source tree we've extracted, it's not actually
# using that as input sources since imports are resolved through $GOPATH and such.
# I'm not clear what voodoo is needed so I'm leaving this as-is for the time being
get_command_doc() {
    COMMAND_PATH=$1
    COMMAND=$2

    pushd ${COMMAND_PATH}
    go build
    mkdir -p ${COMMAND_DIR}/${COMMAND}
    ./${COMMAND} collateral -o ${COMMAND_DIR}/${COMMAND} --html_fragment_with_front_matter
    mv ${COMMAND_DIR}/${COMMAND}/${COMMAND}.html ${COMMAND_DIR}/${COMMAND}/index.html
    rm ${COMMAND} 2>/dev/null
    popd
}

# # First delete all the current generated files so that any stale files are removed
find content/docs/reference -name '*.html' -type f|xargs rm 2>/dev/null

for f in `find $WORK_DIR/istio -type f -name '*.pb.html'`
do
    echo "processing $f"
    locate_file ${f}
done

for f in `find $WORK_DIR/api -type f -name '*.pb.html'`
do
    echo "processing $f"
    locate_file ${f}
done

get_command_doc ${WORK_DIR}/istio/mixer/cmd/mixc mixc
get_command_doc ${WORK_DIR}/istio/mixer/cmd/mixs mixs
get_command_doc ${WORK_DIR}/istio/istioctl/cmd/istioctl istioctl
get_command_doc ${WORK_DIR}/istio/pilot/cmd/pilot-agent pilot-agent
get_command_doc ${WORK_DIR}/istio/pilot/cmd/pilot-discovery pilot-discovery
get_command_doc ${WORK_DIR}/istio/pilot/cmd/sidecar-injector sidecar-injector
get_command_doc ${WORK_DIR}/istio/security/cmd/istio_ca istio_ca
get_command_doc ${WORK_DIR}/istio/security/cmd/node_agent node_agent
get_command_doc ${WORK_DIR}/istio/galley/cmd/galley galley

# Copy all the example files over into the examples directory
# cp $WORK_DIR/istio/Makefile examples/Makefile

rm -fr ${WORK_DIR}
