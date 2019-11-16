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
        echo "Ensure markdown content uses {{< text >}} for code blocks rather than \`\`\`. Please see https://istio.io/about/contribute/creating-and-editing-pages/#embedding-preformatted-blocks"
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

    # replace the {{< /text >}} shortcodes with ```
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/\\{\\{< \/text .*>\}\}/\`\`\`/g" {} ";"

    # elide url="*"
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/url=\".*\"/URL/g" {} ";"

    # elide link="*"
    find "${TMP}" -type f -name \*.md -exec sed -E -i "s/link=\".*\"/LINK/g" {} ";"

    # switch to the temp dir
    pushd "${TMP}" >/dev/null

    if ! find . -type f -name '*.md' -print0 | xargs -0 -r mdspell "${LANG}" --ignore-acronyms --ignore-numbers --no-suggestions --report; then
        echo "To learn how to address spelling errors, please see https://istio.io/about/contribute/creating-and-editing-pages/#linting"
        FAILED=1
    fi

    if ! mdl --ignore-front-matter --style mdl.rb .; then
        FAILED=1
    fi

    if grep -nr -e "(https://istio.io" .; then
        echo "Ensure markdown content uses relative references to istio.io"
        FAILED=1
    fi

    if grep -nr -e "(https://preliminary.istio.io" .; then
        echo "Ensure markdown content doesn't contain references to preliminary.istio.io"
        FAILED=1
    fi

    if grep -nr -e https://github.com/istio/istio/blob/ .; then
        echo "Ensure markdown content uses {{< github_blob >}}"
        FAILED=1
    fi

    if grep -nr -e https://github.com/istio/istio/tree/ .; then
        echo "Ensure markdown content uses {{< github_tree >}}"
        FAILED=1
    fi

    if grep -nr -e https://raw.githubusercontent.com/istio/istio/ .; then
        echo "Ensure markdown content uses {{< github_file >}}"
        FAILED=1
    fi

    # go back whence we came
    popd >/dev/null

    # cleanup
    rm -fr "${TMP}"
}

# check_content content/en --en-us
# only check English words in Chinese docs
# check_content content/zh --en-us

find ./content/en -type f \( -name '*.html' -o -name '*.md' \) -print0 | while IFS= read -r -d '' f; do
    if grep -H -n -e '“' "${f}"; then
        # shellcheck disable=SC1111
        echo "Ensure content only uses standard quotation marks and not “"
        FAILED=1
    fi
done

find ./public -type f -name '*.html' -print0 | while IFS= read -r -d '' f; do
    if grep -H -n -i -e blockquote "${f}"; then
        echo "Ensure content only uses {{< tip >}}, {{< warning >}}, {{< idea >}}, and {{< quote >}} instead of block quotes"
        FAILED=1
    fi

    if grep -H -n -e "\"https://github.*#L[0-9]*\"" "${f}"; then
        echo "Ensure content doesn't use links to specific lines in GitHub files as those are too brittle"
        FAILED=1
    fi
done

find ./content/zh -type f \( -name '*.html' -o -name '*.md' \) -print0 | while IFS= read -r -d '' f; do
    if grep -H -n -E -e "- (/docs|/about|/blog|/faq|/news)" "${f}"; then
        echo "Ensure translated content doesn't include aliases for English content"
        FAILED=1
    fi
done

if ! htmlproofer ./public --assume-extension --http-status-ignore "0" --check-html --check-external-hash --check-opengraph --timeframe 2d --storage-dir .htmlproofer --url-ignore "/localhost/,/github.com/istio/istio.io/edit/,/github.com/istio/istio/issues/new/choose/,/groups.google.com/forum/,/www.trulia.com/,/apporbit.com/,/www.mysql.com/,/www.oreilly.com/"; then
    FAILED=1
fi

if [[ ${FAILED} -eq 1 ]]; then
    echo "LINTING FAILED"
    exit 1
fi
