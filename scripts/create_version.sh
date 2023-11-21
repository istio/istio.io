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

# parse_input function parses the name of the new release, determines
# the type of the release, and runs scripts accordingly
parse_input() {
    [[ $1 =~ ^release-([0-9])\.([0-9]+)\.([0-9]+)$ ]] ||
        { echo "Target format error: should be 'release-x.x.x', got '$1'"; exit 1; }

    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"

    echo "Creating release for ${MAJOR}.${MINOR}.${PATCH}..."

    # patch release
    if [ "${PATCH}" != '0' ]; then
        echo "Patch release automation is currently not supported"
        exit 0
    fi

    # major/minor release
    CURR_MINOR="${MAJOR}.${MINOR}"     # current version
    PREV_MINOR="${MAJOR}.$((MINOR-1))" # previous version
    NEXT_MINOR="${MAJOR}.$((MINOR+1))" # next version

    if [ "${DRY_RUN}" == '1' ]; then
        CURR_MINOR="${CURR_MINOR}-dry-run"
        git checkout "${MASTER}"
        git pull --ff-only "${ISTIOIO_GIT_SOURCE}" "${MASTER}"
    fi

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

# archive_old_release function checks out to the old release branch,
# creates an archive, and stores the archive in the master branch
archive_old_release() {
    echo -e "\nStep 1: archive the old release branch"

    build_archive() {
        scripts/build_old_archive.sh "build-old-archive-${PREV_MINOR}.0"

        sed -i "
            s/^preliminary: .*$/preliminary: \"${NEXT_MINOR}\"/;
            s/^main: .*$/main: \"${CURR_MINOR}\"/
        " data/versions.yml

        # add list item to index page only once
        INDEX_PAGE="archive/archive/index.html"
        grep -q "<a\ href=/v${PREV_MINOR}>v${PREV_MINOR}</a>" ${INDEX_PAGE} ||
            sed -i "0,/<li>/s//\<li>\n\
            <a href=\/v${PREV_MINOR}>v${PREV_MINOR}<\/a>\n\
        <\/li>\n\
        <li>/" ${INDEX_PAGE}
    }

    if [ "${DRY_RUN}" == '1' ]; then
        echo "Archive will be added in Step 2 for dry run"
        return
    fi

    git checkout "release-${PREV_MINOR}"
    git pull --ff-only "${ISTIOIO_GIT_SOURCE}" "release-${PREV_MINOR}"

    sed -i "
        s/^archive: false$/archive: true/;
        s/^archive_date: .*$/archive_date: $(date +'%Y-%m-%d')/;
        s/^archive_search_refinement: .*$/archive_search_refinement: \"V${PREV_MINOR}\"/
    " data/args.yml

    sed -i "s/^disableAliases = true$/disableAliases = false/" hugo.toml

    if [[ $(git status --porcelain) ]]; then # for idempotence
        git add -u
        git commit -m "mark v${PREV_MINOR} as archived"
        git push origin "release-${PREV_MINOR}"
    fi

    # complete the archive process in master
    git checkout "${MASTER}"
    git pull --ff-only "${ISTIOIO_GIT_SOURCE}" "${MASTER}"

    build_archive

    if [[ $(git status --porcelain) ]]; then
        git add -u
        git commit -m "update data/versions.yml and archive index page"
        git push origin "${MASTER}"
    fi
}

# create_branch_for_new_release function creates a branch for the
# new release off the master branch and pushes it to origin
create_branch_for_new_release() {
    NEW_RELEASE_BRANCH="release-${CURR_MINOR}"
    echo -e "\nStep 2: create a new branch for ${NEW_RELEASE_BRANCH}"

    # delete branch if it already exists
    if [[ $(git ls-remote --heads origin "${NEW_RELEASE_BRANCH}") ]]; then
        git push --delete origin "${NEW_RELEASE_BRANCH}"
    fi
    git checkout -B "${NEW_RELEASE_BRANCH}"

    # make archive in the dry run release branch
    if [ "${DRY_RUN}" == '1' ]; then
        build_archive
    fi

    sed -i "
        s/^preliminary: true$/preliminary: false/;
        s/^doc_branch_name: .*$/doc_branch_name: ${NEW_RELEASE_BRANCH}/;
    " data/args.yml

    # Can only do an update-common against a non dry-run branch
    if [ "${DRY_RUN}" != '1' ]; then
        UPDATE_BRANCH=${NEW_RELEASE_BRANCH} make update-common
    fi

    if [[ $(git status --porcelain) ]]; then
        git add -A
        git commit -m "create a new release branch for ${CURR_MINOR}"
        git push origin "${NEW_RELEASE_BRANCH}"
    fi
}

# advance_master_to_next_release function advances the master branch
# to the next release from which preliminary.istio.io is built
advance_master_to_next_release() {
    echo -e "\nStep 3: advance master to release-${NEXT_MINOR}..."
    if [ "${DRY_RUN}" == '1' ]; then
        echo "Skipping step 3 in dry run"
        return
    fi

    git checkout "${MASTER}"
    sed -i "
        s/^version: .*$/version: \"${NEXT_MINOR}\"/;
        s/^full_version: .*$/full_version: \"${NEXT_MINOR}.0\"/;
        s/^previous_version: .*$/previous_version: \"${CURR_MINOR}\"/;
        s/^source_branch_name:.*$/source_branch_name: ${MASTER}/;
        s/^doc_branch_name: .*$/doc_branch_name: ${MASTER}/
    " data/args.yml

    sed -i "
        s/^export SOURCE_BRANCH_NAME ?=.*$/export SOURCE_BRANCH_NAME ?= ${MASTER}/;
        s/^ISTIO_IMAGE_VERSION ?=.*$/ISTIO_IMAGE_VERSION ?= ${NEXT_MINOR}-alpha/
    " Makefile.core.mk

    go get istio.io/istio@"${MASTER}"
    go mod tidy

    make update_all gen

    yq -i '.[0].k8sVersions = .[1].k8sVersions' data/compatibility/supportStatus.yml

    if [[ $(git status --porcelain) ]]; then
        git add -A
        git commit -m "advance master to release-${NEXT_MINOR}"
        git push origin "${MASTER}"
    fi
}

set -e
parse_input "$1"
archive_old_release
create_branch_for_new_release
advance_master_to_next_release
echo "[SUCCESS] New release now has been created in the branch 'release-${CURR_MINOR}'"