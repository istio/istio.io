#!/usr/bin/env bash
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

# This allows us to only push if we're not dry running
_gitpush() {
    if [[ "${DRY_RUN:-}" != '1' ]]; then
        git push "$@"
    else
        echo "DRY_RUN: _gitpush $*"
    fi
}

validate_env() {
    if [[ -z "${ISTIOIO_GIT_SOURCE}" ]]; then
        echo "ISTIOIO_GIT_SOURCE is not set, please set it to the istio.io git source"
        exit 1
    fi

    if [[ -z "${FORKED_GIT_SOURCE}" ]]; then
        echo "FORKED_GIT_SOURCE is not set, please set it to the forked git source"
        exit 1
    fi

    if [[ -z "${DRY_RUN}" ]]; then
        DRY_RUN=0
    fi

    if [[ ! "${DRY_RUN}" =~ ^[01]$ ]]; then
        echo "DRY_RUN must be 0 or 1"
        exit 1
    fi

    if ! command -v gh &> /dev/null; then
        echo "gh could not be found, please install it first"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        echo "gh is not authenticated, please run 'gh auth login' first"
        exit 1
    fi

    [[ $1 =~ ^([0-9])\.([0-9]+)$ ]] ||
        { echo "New minor version format error: should be 'x.x', got '$1'. Are you running the script with the minor version x.yy?"; exit 1; }
}

# prepare a local environment for this work
prepare_env() {
    if [[ -z "${TMP_DIR}" ]]; then
        TMP_DIR=$(mktemp -d)
        trap cleanup_env EXIT
    fi
    pushd "${TMP_DIR}" || exit 1

    echo "Current working directory: $(pwd)"
    echo "Cloning istio.io and the forked repo..."
    git clone "${ISTIOIO_GIT_SOURCE}" istio.io --branch=master
    git clone "${FORKED_GIT_SOURCE}" istio.io-fork

    echo "Checking out the master branch and prepping fork..."
    pushd "${TMP_DIR}"/istio.io-fork || exit 1
    git remote add upstream "${ISTIOIO_GIT_SOURCE}"
    git fetch upstream
    git checkout master
    git pull --ff-only upstream master
    _gitpush origin master
    # For PRs later...
    gh repo set-default "${ORG_REPO_FORK}"
    popd || exit 1
}

cleanup_env() {
    popd || exit 1
    rm -rf "${TMP_DIR}"
}

build_archive() {
    echo "Building archive for v${PREV_MINOR}..."
    # Use the non-forked repo to build the archive so we don't have to worry about
    # the multiple origins and without breaking the script
    pushd "${TMP_DIR}/istio.io" || exit 1
    # Always tell it to DRY_RUN, we don't want it pushing, we'll take care of it in
    # our fork.
    DRY_RUN=1 ISTIOIO_GIT_SOURCE=https://github.com/istio/istio.io.git "${SCRIPT_DIR}"/build_old_archive.sh "build-old-archive-${PREV_MINOR}.0"
    mv archive/v"${PREV_MINOR}" "${TMP_DIR}/istio.io-fork/archive"
    popd || exit 1

    echo "Updating archive index page and versions..."
    sed -i "
        s/^preliminary: .*$/preliminary: \"${NEXT_MINOR}\"/;
        s/^main: .*$/main: \"${CURR_MINOR}\"/
    " data/versions.yml

    # add list item to index page only once
    INDEX_PAGE="archive/archive/index.html"
    grep -q "<a href=/v${PREV_MINOR}>v${PREV_MINOR}</a>" ${INDEX_PAGE} ||
        sed -i "0,/<li>/s//\<li>\n\
        <a href=\/v${PREV_MINOR}>v${PREV_MINOR}<\/a>\n\
    <\/li>\n\
    <li>/" ${INDEX_PAGE}
}

# parse_input function parses the name of the new release, determines
# the type of the release, and runs scripts accordingly
parse_input() {
    [[ $1 =~ ^([0-9])\.([0-9]+)$ ]] ||
        { echo "Target format error: should be 'x.x', got '$1'"; exit 1; }

    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"

    ORG_REPO_FORK=$(echo "${FORKED_GIT_SOURCE}" | sed -E 's/.*github.com[:\/]//')
    ORG_FORK=$(echo "${ORG_REPO_FORK}" | cut -d '/' -f 1)
}

parse_versions() {
    # major/minor release
    CURR_MINOR="${MAJOR}.${MINOR}"     # current version
    PREV_MINOR="${MAJOR}.$((MINOR-1))" # previous version
    NEXT_MINOR="${MAJOR}.$((MINOR+1))" # next version

    # for a major release x.0, find the latest minor release
    if [ "${MINOR}" == '0' ]; then
        LAST_MINOR_OF_PREV_MAJOR=$(
            git branch -a |
            grep "release-$((MAJOR-1))." |
            sed -r "s/^.*release-$((MAJOR-1))\.([0-9]+)$/\1/" |
            sort -n |
            tail -1
        )
        PREV_MINOR="$((MAJOR-1)).${LAST_MINOR_OF_PREV_MAJOR}"
    fi

    echo "Previous minor release: ${PREV_MINOR}"
    echo "Upcoming minor release: ${NEXT_MINOR}"
}

step0() {
    echo -e "\nStep 0: Check and prepare the environment\n"
    prepare_env
    echo "Current working directory: $(pwd)"
    parse_input "$1"
    parse_versions
}

step1() {
    echo -e "\nStep 1: Create a new release branch\n"
    pushd "${TMP_DIR}/istio.io" || exit 1
    if [[ $(git ls-remote --heads origin "release-${CURR_MINOR}") ]]; then
        echo "WARNING!!! The release branch release-${CURR_MINOR} already exists in the istio.io repo."
        echo "This means that someone else may have already run this workflow.... we have two options here:"
        echo "  1. Stop running this script and validate that we should continue"
        echo "  2. Continue running this script and use the PRs to validate the changes"
        echo ""
        echo "You can also ask an admin (TOC) to delete the branch if you're 100% sure... but this is not recommended."
        echo "You'll also need to ensure that any PRs merged to master since the branch was created that are needed in"
        echo "the release branch are cherry-picked to the release branch."
        echo "Press CTRL+C to stop running this script, or press ENTER to continue."
        read -r
    fi

    git fetch --all
    git checkout master
    git pull --ff-only origin master
    git checkout -b "release-${CURR_MINOR}"

    build_archive
    mv "${TMP_DIR}/istio.io-fork/archive/v${PREV_MINOR}" archive

    sed -i "
        s/^preliminary: .*$/preliminary: false/;
        s/^doc_branch_name: .*$/doc_branch_name: release-${CURR_MINOR}/;
    " data/versions.yml

    if [[ $(git status --porcelain) ]]; then
        git add -A
        git status
        git commit -m "update data/versions.yml and archive v${PREV_MINOR}"
    fi

    _gitpush origin "release-${CURR_MINOR}"
    popd || exit 1
}

step2() {
    echo -e "\nStep 2: Master branch work\n"
    pushd "${TMP_DIR}/istio.io-fork" || exit 1
    # Create a new branch to work from
    branch="master-$(date +%s)"
    git checkout -b "${branch}"
    _gitpush origin "${branch}"

    # Archive the previous release
    build_archive
    if [[ $(git status --porcelain) ]]; then
        git add -A
        git status
        git commit -m "update data/versions.yml and archive v${PREV_MINOR}"
        _gitpush origin "${branch}"
    fi

    # Advance the master branch to the next release
    sed -i "
        s/^version: .*$/version: \"${NEXT_MINOR}\"/;
        s/^full_version: .*$/full_version: \"${NEXT_MINOR}.0\"/;
        s/^previous_version: .*$/previous_version: \"${CURR_MINOR}\"/;
        s/^source_branch_name:.*$/source_branch_name: master/;
        s/^doc_branch_name: .*$/doc_branch_name: master/
    " data/args.yml

    sed -i "
        s/^export SOURCE_BRANCH_NAME ?=.*$/export SOURCE_BRANCH_NAME ?= master/;
        s/^ISTIO_IMAGE_VERSION ?=.*$/ISTIO_IMAGE_VERSION ?= ${NEXT_MINOR}-alpha/
    " Makefile.core.mk

    go get istio.io/istio@master
    go mod tidy

    make update_all gen

    yq -i '.[0].k8sVersions = .[1].k8sVersions' data/compatibility/supportStatus.yml

    if [[ $(git status --porcelain) ]]; then
        git add -A
        git status
        git commit -m "advance master to release-${NEXT_MINOR}"
        _gitpush origin master
    fi

    if [[ "${DRY_RUN}" != '1' ]]; then
        # Flip this to istio/istio.io so our PR will be created in the correct repo
        gh repo set-default "istio/istio.io"
        cat <<EOF | gh pr create \
            --base "master" \
            --head "${ORG_FORK}:${branch}" \
            --title "[master] release-${CURR_MINOR} work" \
            --body-file -
This PR was created by make release-${CURR_MINOR}.

Adds archive for v${PREV_MINOR} and bumps to next minor version.
EOF
    fi
    popd || exit 1
}

set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISTIOIO_GIT_SOURCE=${ISTIOIO_GIT_SOURCE:-"https://github.com/istio/istio.io.git"}
validate_env "$1"
step0 "$1"
step1
step2

set +x

echo "Done!"
echo "There should now be 2 PRs open in the istio.io repo, one to master and one to the release branch. Both of these need"
echo "to be merged before the release is complete."
echo ""
echo "Next steps:"
echo "1. Ask the docs WG to point istio-staging.netlify.app to the new release branch"
echo "2. Verify that the staging website is correct"
echo "3. Publish the new minor version in release-builder"
echo "4. Ask the docs WG to point istio.io to the new release branch"
echo "5. Merge the master branch PR in istio.io so that it now tracks the next minor version"
