#!/bin/bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script copies generated .pb.html files, which contain reference docs for protos, and installs
# them in their targeted location within the content/en/docs/reference tree of this repo. Each .pb.html file contains a
# line that indicates the target directory location. The line is of the form:
#
#  location: https://istio.io/docs/reference/...
#
# Additionally, this script also builds Istio components and runs them to extract their command-line docs which it
# copies to content/en/docs/reference/commands.

if [[ "$1" != "" ]]; then
  SOURCE_BRANCH_NAME="$1"
else
  SOURCE_BRANCH_NAME="master"
fi

# The repos to mine for docs, just add new entries here to pull in more repos.
REPOS=(
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"
    https://github.com/istio/api.git@"${SOURCE_BRANCH_NAME}"
    https://github.com/apigee/istio-mixer-adapter.git@master
    https://github.com/osswangxining/alicloud-istio-grpcadapter.git@master
    https://github.com/vmware/wavefront-adapter-for-istio.git@master
    https://github.com/layer5io/layer5-istio-adapter.git@master
    https://github.com/apache/skywalking-data-collect-protocol.git@master
    https://github.com/ibm-cloud-security/app-identity-and-access-adapter.git@master
    https://github.com/newrelic/newrelic-istio-adapter.git@master
)

# The components to build and extract usage docs from.
COMPONENTS=(
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"@mixer/cmd/mixs@mixs
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"@istioctl/cmd/istioctl@istioctl
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"@pilot/cmd/pilot-agent@pilot-agent
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"@pilot/cmd/pilot-discovery@pilot-discovery
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"@security/cmd/node_agent@node_agent
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"@galley/cmd/galley@galley
    https://github.com/istio/istio.git@"${SOURCE_BRANCH_NAME}"@operator/cmd/operator@operator
)

# The repo to fetch config analysis message data from
CONFIG_ANALYSIS_MESSAGE_REPO="https://github.com/istio/istio.git@${SOURCE_BRANCH_NAME}@galley/pkg/config/analysis/msg/messages.yaml"

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR=$(dirname "${SCRIPTPATH}")

WORK_DIR="$(mktemp -d)"
COMP_OUTPUT_DIR="${ROOTDIR}/content/en/docs/reference/commands"

export GOOS=linux
export GOARCH=amd64

echo "WORK_DIR =" "${WORK_DIR}"

#####################

# Given the name of a .pb.html file, extracts the $location marker and then proceeds to
# copy the file to the corresponding content/en/docs/ hierarchy.
locate_file() {
    FILENAME=$1

    LOCATION=$(grep '^location: https://istio.io/docs' "${FILENAME}")
    LEN=${#LOCATION}
    if [[ ${LEN} -eq 0 ]]; then
        echo "    No 'location:' tag in $FILENAME, skipping"
        return
    fi

    FNP=${LOCATION:31}
    FN=$(echo "${FNP}" | rev | cut -d'/' -f1 | rev)
    FN=${FN%.html}
    PP=$(echo "${FNP}" | rev | cut -d'/' -f2- | rev)
    mkdir -p "${ROOTDIR}/content/en/docs${PP}/${FN}"
    sed -e 's/href="https:\/\/istio.io/href="/g' "${FILENAME}" >"${ROOTDIR}/content/en/docs${PP}/${FN}/index.html"

    LEN=${#WORK_DIR}

    if [[ "${REPO_URL}" != "https://github.com/istio/istio.git" && "${REPO_URL}" != "https://github.com/istio/api.git" && "${REPO_URL}" != "https://github.com/istio/operator.git" ]]; then
        sed -i -e 's/layout: protoc-gen-docs/layout: partner-component/g' "${ROOTDIR}/content/en/docs${PP}/${FN}/index.html"
    fi

    REPOX=${REPO_URL/.git/}
    REPOX=${REPOX//\//\\\/}

    sed -i -e "s/title: /WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL SOURCE IN THE '${REPOX}' REPO\ntitle: /g" "${ROOTDIR}/content/en/docs${PP}/${FN}/index.html"
    sed -i -e "s/title: /source_repo: ${REPOX}\ntitle: /g" "${ROOTDIR}/content/en/docs${PP}/${FN}/index.html"
}

handle_doc_scraping() {
    for repo in "${REPOS[@]}"; do
        REPO_URL=$(echo "$repo" | cut -d @ -f 1)
        REPO_BRANCH=$(echo "$repo" | cut -d @ -f 2)
        DEST_DIR=${REPO_URL//\//_}

        echo "  INPUT REPO: ${REPO_URL}@${REPO_BRANCH}"

        git clone --depth=1 -q -b "${REPO_BRANCH}" "${REPO_URL}" "${DEST_DIR}"

        # delete the vendor directory so we don't get .pb.html out of there
        rm -fr "${DEST_DIR}/vendor"

        find "${DEST_DIR}" -type f -name '*.pb.html' -print0 | while IFS= read -r -d '' f; do
            locate_file "${f}"
        done

        rm -fr "${DEST_DIR}"
    done
}

handle_components() {
    for comp in "${COMPONENTS[@]}"; do
        REPO_URL=$(echo "${comp}" | cut -d @ -f 1)
        REPO_BRANCH=$(echo "${comp}" | cut -d @ -f 2)
        REPO_NAME=$(echo "${REPO_URL}" | cut -d / -f 5 | cut -d . -f 1)
        COMP_PATH=$(echo "${comp}" | cut -d @ -f 3)
        COMP_NAME=$(echo "${comp}" | cut -d @ -f 4)

        echo "  COMPONENT: ${COMP_NAME} from ${REPO_URL}@${REPO_BRANCH}"

        git clone --depth=1 -q -b "${REPO_BRANCH}" "${REPO_URL}"

        pushd "${REPO_NAME}" >/dev/null || exit
        pushd "${COMP_PATH}" >/dev/null || exit

        go build -o "${COMP_NAME}"
        mkdir -p "${COMP_OUTPUT_DIR}/${COMP_NAME}"
        "./${COMP_NAME}" collateral -o "${COMP_OUTPUT_DIR}/${COMP_NAME}" --html_fragment_with_front_matter
        mv "${COMP_OUTPUT_DIR}/${COMP_NAME}/${COMP_NAME}.html" "${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html"
        rm -fr "${COMP_NAME}"

        sed -i -e "s/title: /WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL SOURCE IN THE 'https:\/\/github.com\/istio\/istio' REPO\ntitle: /g" "${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html"
        sed -i -e "s/title: /source_repo: https:\/\/github.com\/istio\/istio\ntitle: /g" "${COMP_OUTPUT_DIR}/${COMP_NAME}/index.html"

        popd >/dev/null || exit
        popd >/dev/null || exit

        rm -fr "${REPO_NAME}"
    done
}

handle_config_analysis_messages() {
    REPO_URL=$(echo "${CONFIG_ANALYSIS_MESSAGE_REPO}" | cut -d @ -f 1)
    REPO_BRANCH=$(echo "${CONFIG_ANALYSIS_MESSAGE_REPO}" | cut -d @ -f 2)
    REPO_NAME=$(echo "${REPO_URL}" | cut -d / -f 5 | cut -d . -f 1)
    FILE_PATH=$(echo "${CONFIG_ANALYSIS_MESSAGE_REPO}" | cut -d @ -f 3)

    git clone --depth=1 -q -b "${REPO_BRANCH}" "${REPO_URL}"

    pushd "${REPO_NAME}" >/dev/null || exit
    cp "${FILE_PATH}" "${ROOTDIR}/data/analysis.yaml"
    popd >/dev/null || exit

    rm -fr "${REPO_NAME}"
}

# delete all the existing generated files so that any stale files are removed
find "${ROOTDIR}/content/en/docs/reference" -name '*.html' -type f -print0 | xargs -0 rm 2>/dev/null

# Prepare the work directory
mkdir -p "${WORK_DIR}"
pushd "${WORK_DIR}" >/dev/null || exit

echo "Handling doc scraping"
handle_doc_scraping

echo "Handling component docs"
handle_components

echo "Fetching config analysis data"
handle_config_analysis_messages
