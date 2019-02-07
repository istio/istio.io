#!/bin/bash

FAILED=0

echo -ne "mdspell "
mdspell --version
echo -ne "mdl "
mdl --version
htmlproofer --version
DISABLE_EXTERNAL=${INTERNAL_ONLY:-false}


# This performs spell checking and style checking over markdown files in a content
# directory. It transforms the shortcode sequences we use to annotate code blocks
# blocks into classic markdown ``` code blocks, so that the linters aren't confused
# by the code blocks
check_content() {
    DIR=$1
    LANG=$2
    TMP=$(mktemp -d)

    # make the tmp dir
    mkdir -p ${TMP}

    # create a throwaway copy of the content
    cp -R ${DIR} ${TMP}
    cp .spelling ${TMP}
    cp mdl_style.rb ${TMP}

    # replace the {{< text >}} shortcodes with ```plain
    find ${TMP} -type f -name \*.md -exec sed -E -i "s/\\{\\{< text .*>\}\}/\`\`\`plain/g" {} ";"

    # replace the {{< /text >}} shortcodes with ```
    find ${TMP} -type f -name \*.md -exec sed -E -i "s/\\{\\{< \/text .*>\}\}/\`\`\`/g" {} ";"

    # elide url="*"
    find ${TMP} -type f -name \*.md -exec sed -E -i "s/url=\".*\"/URL/g" {} ";"

    # elide link="*"
    find ${TMP} -type f -name \*.md -exec sed -E -i "s/link=\".*\"/LINK/g" {} ";"

    # switch to the temp dir
    pushd ${TMP} >/dev/null

    mdspell ${LANG} --ignore-acronyms --ignore-numbers --no-suggestions --report *.md */*.md */*/*.md */*/*/*.md */*/*/*/*.md */*/*/*/*/*.md */*/*/*/*/*/*.md
    if [[ "$?" != "0" ]]
    then
        echo "To learn how to address spelling errors, please see https://github.com/istio/istio.io#linting"
        FAILED=1
    fi

    mdl --ignore-front-matter --style mdl_style.rb .
    if [[ "$?" != "0" ]]
    then
        FAILED=1
    fi

    grep -nr -e "(https://istio.io" .
    if [[ "$?" == "0" ]]
    then
        echo "Ensure markdown content uses relative references to istio.io"
        FAILED=1
    fi

    # go back whence we came
    popd  >/dev/null

    # cleanup
    rm -fr ${TMP}
}

check_content content --en-us
check_content content_zh --zh-cn

grep -nr -e "“" ./content
if [[ "$?" == "0" ]]
then
    echo "Ensure markdown content only uses standard quotation marks and not “"
    FAILED=1
fi

htmlproofer ./public --assume-extension --check-html --disable_external ${DISABLE_EXTERNAL} --check-external-hash --check-opengraph --timeframe 2d --storage-dir .htmlproofer --url-ignore "/localhost/,/github.com/istio/istio.io/edit/master/,/github.com/istio/istio/issues/new/choose/,/groups.google.com/forum/,/www.trulia.com/"
if [[ "$?" != "0" ]]
then
    FAILED=1
fi

if [[ ${FAILED} -eq 1 ]]
then
    echo "LINTING FAILED"
    exit 1
fi
