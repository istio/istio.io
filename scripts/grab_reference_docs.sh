#!/bin/bash

# This script copies generated .pb.html files, which contain reference docs for protos, and installs
# them in their targeted location within the content/docs/reference tree of this repo. Each .pb.html file contains a
# line that indicates the target directory location. The line is of the form:
#
#  location: https://istio.io/docs/reference/...
#
# Additionally, this script also builds Istio components and runs them to extract their command-line docs which it
# copies to content/docs/reference/commands.

ISTIO_BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
export GOPATH=$(mktemp -d)
WORK_DIR=${GOPATH}/src/istio.io
COMP_OUTPUT_DIR=$ISTIO_BASE/content/docs/reference/commands
echo "WORK_DIR =" $WORK_DIR

# The repos to mine for docs, just add new entries here to pull in more repos.
REPOS=(
    https://github.com/istio/istio.git@release-1.1
    https://github.com/istio/api.git@release-1.1
    https://github.com/apigee/istio-mixer-adapter.git@master
    https://github.com/osswangxining/alicloud-istio-grpcadapter.git@master
    https://github.com/vmware/wavefront-adapter-for-istio.git@master
)

# The components to build and extract usage docs from.
COMPONENTS=(
    ${WORK_DIR}/istio/mixer/cmd/mixc:mixc
    ${WORK_DIR}/istio/mixer/cmd/mixs:mixs
    ${WORK_DIR}/istio/istioctl/cmd/istioctl:istioctl
    ${WORK_DIR}/istio/pilot/cmd/pilot-agent:pilot-agent
    ${WORK_DIR}/istio/pilot/cmd/pilot-discovery:pilot-discovery
    ${WORK_DIR}/istio/pilot/cmd/sidecar-injector:sidecar-injector
    ${WORK_DIR}/istio/security/cmd/istio_ca:istio_ca
    ${WORK_DIR}/istio/security/cmd/node_agent:node_agent
    ${WORK_DIR}/istio/galley/cmd/galley:galley
)

#####################

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

    LEN=${#WORK_DIR}
    REL_PATH=${FILENAME:LEN}
    REPO=$(echo ${REL_PATH} | cut -d'/' -f2)

    if [ "${REPO}" != "istio" -a "${REPO}" != "api" ]
    then
        sed -e 's/layout: protoc-gen-docs/layout: partner-component/g' -i "" content/docs${PP}/${FN}/index.html
    fi
}

# Given the path and name to an Istio component, builds the component and then
# runs it to extract its command-line docs
get_component_doc() {
    COMP_PATH=$1
    COMP_NAME=$2

    pushd ${COMP_PATH}
    go build
    mkdir -p ${COMP_OUTPUT_DIR}/${COMP_NAME}
    ./${COMP_NAME} collateral -o ${COMP_OUTPUT_DIR}/${COMP_NAME} --html_fragment_with_front_matter
    mv ${COMP_OUTPUT_DIR}/${COMP_NAME}/${COMP_NAME}.html ${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html
    rm ${COMP_NAME} 2>/dev/null
    popd
}

# Prepare the work directory by cloning all the repos into it
mkdir -p ${WORK_DIR}
pushd $WORK_DIR
for repo in "${REPOS[@]}"
do
    REPO_URL=$(echo $repo | cut -d @ -f 1)
    REPO_BRANCH=$(echo $repo | cut -d @ -f 2)

    git clone -b $REPO_BRANCH $REPO_URL
done
popd

# delete all the existing generated files so that any stale files are removed
find content/docs/reference -name '*.html' -type f|xargs rm 2>/dev/null

for comp in "${COMPONENTS[@]}"
do
    COMP_PATH=$(echo $comp | cut -d : -f 1)
    COMP_NAME=$(echo $comp | cut -d : -f 2)

    get_component_doc $COMP_PATH $COMP_NAME
done

# delete the vendor directories so we don't get .pb.html out of there
rm -fr $WORK_DIR/*/vendor

for f in `find $WORK_DIR -type f -name '*.pb.html'`
do
    echo "processing $f"
    locate_file ${f}
done

# Copy all the example files over into the examples directory
# cp $WORK_DIR/istio/Makefile examples/Makefile

rm -fr ${WORK_DIR}
