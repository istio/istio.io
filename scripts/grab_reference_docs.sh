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

# The components to build and extract usage docs from.
COMPONENTS=(
    https://github.com/istio/istio.git@master@mixer/cmd/mixc@mixc
    https://github.com/istio/istio.git@master@mixer/cmd/mixs@mixs
    https://github.com/istio/istio.git@master@istioctl/cmd/istioctl@istioctl
    https://github.com/istio/istio.git@master@pilot/cmd/pilot-agent@pilot-agent
    https://github.com/istio/istio.git@master@pilot/cmd/pilot-discovery@pilot-discovery
    https://github.com/istio/istio.git@master@pilot/cmd/sidecar-injector@sidecar-injector
    https://github.com/istio/istio.git@master@security/cmd/istio_ca@istio_ca
    https://github.com/istio/istio.git@master@security/cmd/node_agent@node_agent
    https://github.com/istio/istio.git@master@galley/cmd/galley@galley
    https://github.com/istio/operator.git@master@cmd/manager@operator
)

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR=$(dirname "${SCRIPTPATH}")
cd "${ROOTDIR}"

export GOPATH=$(mktemp -d)
WORK_DIR=${GOPATH}/src/istio.io
COMP_OUTPUT_DIR=${ROOTDIR}/content/docs/reference/commands

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
        echo "    No 'location:' tag in $FILENAME, skipping"
        return
    fi

    FNP=${LOCATION:31}
    FN=$(echo ${FNP} | rev | cut -d'/' -f1 | rev)
    FN=${FN%.html}
    PP=$(echo ${FNP} | rev | cut -d'/' -f2- | rev)
    mkdir -p ${ROOTDIR}/content/docs${PP}/${FN}
    sed -e 's/href="https:\/\/istio.io/href="/g' ${FILENAME} >${ROOTDIR}/content/docs${PP}/${FN}/index.html

    LEN=${#WORK_DIR}
    REL_PATH=${FILENAME:LEN}

    if [[ "${REPO_URL}" != "https://github.com/istio/istio.git" && "${REPO_URL}" != "https://github.com/istio/api.git" ]]
    then
        sed -e 's/layout: protoc-gen-docs/layout: partner-component/g' -i "" ${ROOTDIR}/content/docs${PP}/${FN}/index.html
    fi

    REPOX=${REPO_URL/.git/}
    REPOX=${REPOX//\//\\\/}

    sed -e 's/title: /WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL SOURCE IN THE '${REPOX}' REPO\'$'\n''title: /g' -i "" ${ROOTDIR}/content/docs${PP}/${FN}/index.html
    sed -e 's/title: /source_repo: '${REPOX}'\'$'\n''title: /g' -i "" ${ROOTDIR}/content/docs${PP}/${FN}/index.html
}

handle_doc_scraping() {
    for repo in "${REPOS[@]}"
    do
        REPO_URL=$(echo $repo | cut -d @ -f 1)
        REPO_BRANCH=$(echo $repo | cut -d @ -f 2)
        DEST_DIR=${REPO_URL//\//_}

        echo "  INPUT REPO: ${REPO_URL}"

        git clone -q -b ${REPO_BRANCH} ${REPO_URL} ${DEST_DIR}

        # delete the vendor directory so we don't get .pb.html out of there
        rm -fr ${DEST_DIR}/vendor

        for f in `find ${DEST_DIR} -type f -name '*.pb.html'`
        do
            locate_file ${f}
        done

        rm -fr ${DEST_DIR}
    done
}

handle_components() {
    for comp in "${COMPONENTS[@]}"
    do
        REPO_URL=$(echo ${comp} | cut -d @ -f 1)
        REPO_BRANCH=$(echo ${comp} | cut -d @ -f 2)
        REPO_NAME=$(echo ${REPO_URL} | cut -d / -f 5 | cut -d . -f 1)
        COMP_PATH=$(echo ${comp} | cut -d @ -f 3)
        COMP_NAME=$(echo ${comp} | cut -d @ -f 4)

        echo "  COMPONENT: ${COMP_NAME}"

        git clone -q -b ${REPO_BRANCH} ${REPO_URL}

        pushd ${REPO_NAME}
        pushd ${COMP_PATH}
        # until we're on the go module plan in istio/istio and istio/operator
        GO111MODULE=off
        go build -o ${COMP_NAME}
        mkdir -p ${COMP_OUTPUT_DIR}/${COMP_NAME}
        ./${COMP_NAME} collateral -o ${COMP_OUTPUT_DIR}/${COMP_NAME} --html_fragment_with_front_matter > /dev/null
        mv ${COMP_OUTPUT_DIR}/${COMP_NAME}/${COMP_NAME}.html ${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html
        rm ${COMP_NAME} 2>/dev/null
        sed -e 's/title: /WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL SOURCE IN THE https:\/\/github.com\/istio\/istio REPO\'$'\n''title: /g' -i "" ${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html
        sed -e 's/title: /source_repo: https:\/\/github.com\/istio\/istio\'$'\n''title: /g' -i "" ${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html
        popd
        popd

        rm -fr ${REPO_NAME}
    done
}

# delete all the existing generated files so that any stale files are removed
find ${ROOTDIR}/content/docs/reference -name '*.html' -type f|xargs rm 2>/dev/null

# Prepare the work directory
mkdir -p ${WORK_DIR}
pushd ${WORK_DIR}

echo "Handling doc scraping"
handle_doc_scraping

echo "Handling component docs"
handle_components

popd
rm -fr ${WORK_DIR}
