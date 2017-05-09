#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

# TODO(REVIEWER): how do we want to handle finding the two binaries? set a default and try, or abort?
ISTIOCTL=${ISTIOCTL:-istioctl}
if [[ -z "${MIXCOL_CLI}" ]]; then
    echo "No mixcol command defined via the environment variable MIXCOL_CLI"
    exit 1
fi

ISTIO_BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
OUTPUT_DIR=$(readlink -f ${ISTIO_BASE}/_docs/reference/commands/)
WORKING_DIR=$(mktemp -d)

function pageHeader() {
    title=${1}
    overview=${2}
    order=${3}
    cat <<EOF
---
title: ${title}
overview: ${overview}
layout: docs
order: ${order}
type: markdown
---

EOF
}

function generateIndex() {
    cat <<EOF
---
title: CLI
overview: Describes usage and options of the Istio CLI and other utilities.
order: 30
layout: docs
type: markdown
---
{% include section-index.html %}

EOF
}

# combines the collateral files of a single binary, updating links
function processPerBinaryFiles() {
    # mixcol produces a top level markdown file named ${commandName}.md which
    # serves as our base file. We'll cat the other files into it after
    # processing.
    commandName=${1}
    order=${2}
    primaryFile=${WORKING_DIR}/${commandName}.md
    if [[ -z ${primaryFile} ]]; then
        echo "could not find ${primaryFile}, skipping processing ${commandName}"
        return
    fi

    out=$(mktemp)
    overview=$(sed -n '/^[^#]/ {p;q;}' ${primaryFile})
    pageHeader "${commandName}" "${overview}" "${order}" > ${out}

    # insert an anchor and remove the last line of the file, which is a note
    # that its auto generated
    echo "<a name=\"${commandName}\"></a>" >> ${out}
    sed '/SEE ALSO/,$d' ${primaryFile} >> ${out}
    # this pattern matches only subcommands of ${commandName}, and not
    # ${commandName}'s output file itself
    for file in ${WORKING_DIR}/${commandName}_*.md; do
        fullFileName=$(basename ${file})
        noext=${fullFileName%%.*}
        # synthesize an anchor to replace the generated links to separate pages
        echo "<a name=\"${noext}\"></a>" >> ${out}
        # delete everything in the file from SEE ALSO till the end
        sed '/SEE ALSO/,$d' ${file} >> ${out}
    done
    # We can't rely on ordering, so we need to iterate over the files twice to be sure
    # we update all links.
    for file in ${WORKING_DIR}/${commandName}_*.md; do
        fullFileName=$(basename ${file})
        noext=${fullFileName%%.*}
        # change links to refer to anchors
        sed -i "s,${fullFileName},#${noext},g" ${out};
    done

    # Command line help text output must use full path but
    # pre-processed istio.io pages should use relative paths.
    sed -i ${out} \
        -e "s,https://istio.io/\(.*/\)\(.*\).html,[\2]({{home}}/\1\2.html),g" \
        -e "s,http://istio.io/\(.*/\)\(.*\).html,[\2]({{home}}/\1\2.html),g"

    # final pass updating the subcommand's "SEE ALSO" links to the command itself
    sed "s,${commandName}.md,#${commandName},g" ${out};
}

# Generate our output
${MIXCOL_CLI} -o ${WORKING_DIR}
${ISTIOCTL} markdown --dir ${WORKING_DIR}

# Clean up the target directory
mkdir -p ${OUTPUT_DIR}
rm -f ${OUTPUT_DIR}/*

generateIndex > ${OUTPUT_DIR}/index.md
processPerBinaryFiles "istioctl" 1 > ${OUTPUT_DIR}/istioctl.md
processPerBinaryFiles "mixc" 101 >  ${OUTPUT_DIR}/mixc.md
processPerBinaryFiles "mixs" 201 >  ${OUTPUT_DIR}/mixs.md

rm -rfd ${WORKING_DIR}
