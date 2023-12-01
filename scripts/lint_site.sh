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

set -e

FAILED=0

if [[ "$#" -ne 0 ]]; then
    LANGS="$*"
else
    LANGS="en zh"
fi

red='\e[0;31m'
clr='\e[0m'

error() {
  echo -e "${red}$*${clr}"
}

# This performs spell checking and style checking over markdown files in a content
# directory. It transforms the shortcode sequences we use to annotate code blocks
# into classic markdown ``` code blocks, so that the linters aren't confused
# by the code blocks
check_content() {
    DIR=$1
    LANG=$2
    TMP=$(mktemp -d)

    # check for use of ```
    if grep -nr -e "\`\`\`" --include "*.md" "${DIR}"; then
        error "Ensure markdown content uses {{< text >}} for code blocks rather than \`\`\`. Please see https://istio.io/about/contribute/code-blocks/"
        FAILED=1
    fi

    # make the tmp dir
    mkdir -p "${TMP}"

    # create a throwaway copy of the content
    cp -R "${DIR}" "${TMP}"
    cp .spelling "${TMP}"
    cp mdl.rb "${TMP}"

    # replace the {{< text >}} shortcodes with ```plain
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/\\{\\{< text .*>\}\}/\`\`\`plain/g" {} ";"

    # replace the {{< mermaid >}} shortcodes with ```mermaid
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/\\{\\{< mermaid .*>\}\}/\`\`\`mermaid/g" {} ";"

    # replace the {{< /text >}} shortcodes with ```
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/\\{\\{< \/text .*>\}\}/\`\`\`/g" {} ";"

    # replace the {{< /mermaid >}} shortcodes with ```
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/\\{\\{< \/mermaid .*>\}\}/\`\`\`/g" {} ";"

    # elide url="*"
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/url=\".*\"/URL/g" {} ";"

    # elide link="*"
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/link=\".*\"/LINK/g" {} ";"

    # remove any heading anchors
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/(^#.*\S) *\{#.*\} */\1/g" {} ";"

    # switch to the temp dir
    pushd "${TMP}" >/dev/null

    if ! find . -type f -name '*.md' -print0 | xargs -0 -r mdspell "${LANG}" --ignore-acronyms --ignore-numbers --no-suggestions --report; then
        error "To learn how to address spelling errors, please see https://istio.io/about/contribute/build/#test-your-changes"
        FAILED=1
    fi

    if ! mdl --ignore-front-matter --style mdl.rb .; then
        FAILED=1
    fi

    if grep -nrP --include "*.md" -e "\(https://istio.io/(?!v[0-9]\.[0-9]/|archive/)" .; then
        error "Ensure markdown content uses relative references to istio.io"
        FAILED=1
    fi

    if grep -nr --include "*.md" -e "(https://preliminary.istio.io" .; then
        error "Ensure markdown content doesn't contain references to preliminary.istio.io"
        FAILED=1
    fi

    if grep -nr --include "*.md" -e https://github.com/istio/istio/blob/ .; then
        error "Ensure markdown content uses {{< github_blob >}}"
        FAILED=1
    fi

    if grep -nr --include "*.md" -e https://github.com/istio/istio/tree/ .; then
        error "Ensure markdown content uses {{< github_tree >}}"
        FAILED=1
    fi

    if grep -nr --include "*.md" -e https://raw.githubusercontent.com/istio/istio/ .; then
        error "Ensure markdown content uses {{< github_file >}}"
        FAILED=1
    fi

    # go back whence we came
    popd >/dev/null

    # cleanup
    rm -fr "${TMP}"
}

SKIP_LANGS=( en zh pt-br )
for lang in $LANGS; do
    for i in "${!SKIP_LANGS[@]}"; do
       if [[ "${SKIP_LANGS[$i]}" = "${lang}" ]]; then
           unset 'SKIP_LANGS[${i}]'
       fi
    done
    SKIP_LANGS=( "${SKIP_LANGS[@]}" )

    if [[ "$lang" == "en" ]]; then
        list=$(find ./content/en/docs -name '*.md' -not -exec grep -q '^test: ' {} \; -print)
        if [[ -n $list ]]; then
            echo "$list"
            error "Ensure every document *.md file includes a test: attribute in its metadata"
            FAILED=1
        fi

        list=$(find ./content/en/docs -name 'index.md' -not -exec grep -q '^owner: ' {} \; -print)
        if [[ -n $list ]]; then
            echo "$list"
            error "Ensure every document index.md file includes an owner: attribute in its metadata"
            FAILED=1
        fi

        check_content "content/$lang" --en-us

        while IFS= read -r -d '' f; do
            if grep -H -n -e '“' "${f}"; then
                # shellcheck disable=SC1111
                error "Ensure content only uses standard quotation marks and not “"
                FAILED=1
            fi
        done < <(find ./content/en -type f \( -name '*.html' -o -name '*.md' \) -print0)
    elif [[ "$lang" == "zh" ]]; then
        # only check English words in Chinese docs
        check_content "content/$lang" --en-us

        while IFS= read -r -d '' f; do
            if grep -H -n -E -e "- (/docs|/about|/blog|/faq|/news)" "${f}"; then
                error "Ensure translated content doesn't include aliases for English content"
                FAILED=1
            fi

            if grep -H -n -E -e '"(/docs|/about|/blog|/faq|/news)' "${f}"; then
                error "Ensure translated content doesn't include references to English content"
                FAILED=1
            fi

            if grep -H -n -E -e '\((/docs|/about|/blog|/faq|/news)' "${f}"; then
                error "Ensure translated content doesn't include references to English content"
                FAILED=1
            fi
        done < <(find ./content/zh -type f \( -name '*.html' -o -name '*.md' \) -print0)
    elif [[ "$lang" == "pt-br" ]]; then
        # only check English words in Portuguese Brazil docs
        check_content "content/$lang" --en-us
    fi
done

if [ -d ./public ]; then
    if [[ ${#SKIP_LANGS[@]} -ne 0 ]]; then
        printf -v find_exclude " -name %s -prune -o" "${SKIP_LANGS[@]}"; read -r -a find_exclude <<< "$find_exclude"
    fi

    while IFS= read -r -d '' f; do
        if grep -H -n -i -e blockquote "${f}"; then
            error "Ensure content only uses {{< tip >}}, {{< warning >}}, {{< idea >}}, and {{< quote >}} instead of block quotes"
            FAILED=1
        fi

        #if grep -H -n -e "\"https://github.*#L[0-9]*\"" "${f}"; then
        #    error "Ensure content doesn't use links to specific lines in GitHub files as those are too brittle"
        #    FAILED=1
        #fi
    done < <(find ./public "${find_exclude[@]}" -type f -name '*.html' -print0)

    if ! htmlproofer ./public --file-ignore "${ignore_files}" --assume-extension --http-status-ignore "0,429" --check-html --check-external-hash --check-opengraph --checks-to-ignore "LinkCheck"; then
        FAILED=1
    fi

    if [[ ${SKIP_LINK_CHECK:-} != "true" ]]; then
        if [[ ${#SKIP_LANGS[@]} -ne 0 ]]; then
            printf -v ignore_files "/^.\/public\/%s/," "${SKIP_LANGS[@]}"; ignore_files="${ignore_files%,}"
        fi
        echo "Running linkinator..."
        if [[ ${CHECK_EXTERNAL_LINKS:-} == "true" ]]; then
            if ! linkinator public/ -r -s 'github.com localhost:3000 localhost:5601 localhost:8001 localhost:9080 localhost:9081 en.wikipedia.org my-istio-logs-database.io' --silent --concurrency 25; then
                FAILED=1
            fi
        else
            #TODO: Remove .../workload-selector/ from ignored links. PRs take a long time to get through istio/api, and a link is broken from there. Once this PR is complete, remove it: https://github.com/istio/api/pull/1405
            if ! linkinator public/ -r -s 'github.com localhost:3000 localhost:5601 localhost:8001 localhost:9080 localhost:9081 en.wikipedia.org my-istio-logs-database.io ^((?!localhost).)*$ /docs/reference/config/type/v1beta1/workload-selector/' --silent --concurrency 25; then
                FAILED=1
            fi
        fi
    fi
fi

if [[ ${FAILED} -eq 1 ]]; then
    error "LINTING FAILED"
    exit 1
fi
