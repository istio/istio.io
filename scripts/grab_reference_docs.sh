#!/bin/bash

# This script copies generated .pb.html files, which contain reference docs for protos, and installs
# them in their targeted location within the content/docs/reference tree of this repo. Each .pb.html file contains a
# line that indicates the target directory location. The line is of the form:
#
#  location: https://istio.io/docs/reference/...
#
# Additionally, this script also builds Istio components and runs them to extract their command-line docs which it
# copies to content/docs/reference/commands.

# The repos to mine for docs, just add new entries here to pull in more repos.
REPOS=(
    https://github.com/istio/istio.git@master
    https://github.com/istio/api.git@master
    https://github.com/apigee/istio-mixer-adapter.git@master
    https://github.com/osswangxining/alicloud-istio-grpcadapter.git@master
    https://github.com/vmware/wavefront-adapter-for-istio.git@master
    https://github.com/apache/incubator-skywalking-data-collect-protocol.git@master
)

# The components from istio/istio to build and extract usage docs from.
COMPONENT_REPO=https://github.com/istio/istio.git@master
COMPONENTS=(
    mixer/cmd/mixc:mixc
    mixer/cmd/mixs:mixs
    istioctl/cmd/istioctl:istioctl
    pilot/cmd/pilot-agent:pilot-agent
    pilot/cmd/pilot-discovery:pilot-discovery
    pilot/cmd/sidecar-injector:sidecar-injector
    security/cmd/istio_ca:istio_ca
    security/cmd/node_agent:node_agent
    galley/cmd/galley:galley
)

ISTIO_BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
export GOPATH=$(mktemp -d)
WORK_DIR=${GOPATH}/src/istio.io
COMP_OUTPUT_DIR=${ISTIO_BASE}/content/docs/reference/commands
echo "WORK_DIR =" ${WORK_DIR}


#####################

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

# Given the name of a .pb.html file, extracts the $location marker and then proceeds to
# copy the file to the corresponding content/docs/ hierarchy.
locate_file() {
    FILENAME=$1

    LOCATION=$(grep '^location: https://istio.io/docs' ${FILENAME})
    LEN=${#LOCATION}
    if [[ ${LEN} -eq 0 ]]
    then
        echo "No 'location:' tag in $FILENAME, skipping"
        return
    fi

    FNP=${LOCATION:31}
    FN=$(echo ${FNP} | rev | cut -d'/' -f1 | rev)
    FN=${FN%.html}
    PP=$(echo ${FNP} | rev | cut -d'/' -f2- | rev)
    mkdir -p content/docs${PP}/${FN}
    sed -e 's/href="https:\/\/istio.io/href="/g' ${FILENAME} >content/docs${PP}/${FN}/index.html

    LEN=${#WORK_DIR}
    REL_PATH=${FILENAME:LEN}
    REPO=$(echo ${REL_PATH} | cut -d'/' -f2)

    if [[ "${REPO}" != "https:__github.com_istio_istio.git" && "${REPO}" != "https:__github.com_istio_api.git" ]]
    then
        sed -e 's/layout: protoc-gen-docs/layout: partner-component/g' -i "" content/docs${PP}/${FN}/index.html
    fi

    REPOX=${REPO//_/\\\/}
    REPOX=${REPOX/.git/}

    sed -e 's/title: /WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL SOURCE IN THE '${REPOX}' REPO\'$'\n''title: /g' -i "" content/docs${PP}/${FN}/index.html
    sed -e 's/title: /source_repo: '${REPOX}'\'$'\n''title: /g' -i "" content/docs${PP}/${FN}/index.html
}

# Given the path and name to an Istio component, builds the component and then
# runs it to extract its command-line docs
get_component_doc() {
    COMP_PATH=$1
    COMP_NAME=$2

    pushd ${COMP_PATH}
    go build
    mkdir -p ${COMP_OUTPUT_DIR}/${COMP_NAME}
    ./${COMP_NAME} collateral -o ${COMP_OUTPUT_DIR}/${COMP_NAME} --html_fragment_with_front_matter > /dev/null
    mv ${COMP_OUTPUT_DIR}/${COMP_NAME}/${COMP_NAME}.html ${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html
    rm ${COMP_NAME} 2>/dev/null
    sed -e 's/title: /WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL SOURCE IN THE https:\/\/github.com\/istio\/istio REPO\'$'\n''title: /g' -i "" ${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html
    sed -e 's/title: /source_repo: https:\/\/github.com\/istio\/istio\'$'\n''title: /g' -i "" ${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html
    popd
}

handle_components() {
    REPO_URL=$(echo ${COMPONENT_REPO} | cut -d @ -f 1)
    REPO_BRANCH=$(echo ${COMPONENT_REPO} | cut -d @ -f 2)

    git clone -q -b ${REPO_BRANCH} ${REPO_URL}
    pushd istio

    for comp in "${COMPONENTS[@]}"
    do
        COMP_PATH=$(echo $comp | cut -d : -f 1)
        COMP_NAME=$(echo $comp | cut -d : -f 2)

        get_component_doc ${COMP_PATH} ${COMP_NAME}
    done

    popd
    rm -fr istio
}

# delete all the existing generated files so that any stale files are removed
find content/docs/reference -name '*.html' -type f|xargs rm 2>/dev/null

# Prepare the work directory by cloning all the repos into it
mkdir -p ${WORK_DIR}
pushd ${WORK_DIR}

echo "Cloning input repos"
for repo in "${REPOS[@]}"
do
    REPO_URL=$(echo $repo | cut -d @ -f 1)
    REPO_BRANCH=$(echo $repo | cut -d @ -f 2)
    DEST_DIR=${REPO_URL//\//_}

    git clone -q -b ${REPO_BRANCH} ${REPO_URL} ${DEST_DIR}

    # delete the vendor directory so we don't get .pb.html out of there
    rm -fr ${DEST_DIR}/vendor
done

echo "Handling components"
handle_components

popd

echo "Processing HTML files"
for f in `find ${WORK_DIR} -type f -name '*.pb.html'`
do
    locate_file ${f}
done

rm -fr ${WORK_DIR}
