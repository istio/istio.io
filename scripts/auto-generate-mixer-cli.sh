#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

if [[ -z "${MIXCOL_CLI}" ]]; then
    echo "No mixcol command defined via the environment variable MIXCOL_CLI"
    exit 1
fi

ISTIO_BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
MIXER_CLI_DIR=$(readlink -f ${ISTIO_BASE}/_docs/reference/mixercli/)
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
title: The Mixer CLI
overview: Options showing how to use the Mixer's CLIs.
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
    head -n -1 ${primaryFile} >> ${out}
    # this pattern matches only subcommands of ${commandName}, and not
    # ${commandName}'s output file itself
    for file in ${WORKING_DIR}/${commandName}_*.md; do
        fullFileName=$(basename ${file})
        noext=${fullFileName%%.*}
        # synthesize an anchor to replace the generated links to separate pages
        echo "<a name=\"${noext}\"></a>" >> ${out}
        head -n -1 ${file} >> ${out}
    done
    # We can't rely on ordering, so we need to iterate over the files twice to be sure
    # we update all links.
    for file in ${WORKING_DIR}/${commandName}_*.md; do
        fullFileName=$(basename ${file})
        noext=${fullFileName%%.*}
        # change links to refer to anchors
        sed -i "s,${fullFileName},#${noext},g" ${out};
    done
    # final pass updating the subcommand's "SEE ALSO" links to the command itself
    sed "s,${commandName}.md,#${commandName},g;s/SEE ALSO/See Also/g" ${out};
}

# Generate markdown files with mixcol. We create a subdirectory so we can grab
# all *.md files out of it without having to worry about random *.md files
# added to the root of the mixer git repo.
mkdir -p ${WORKING_DIR}
${MIXCOL_CLI} -o ${WORKING_DIR}

# Clean up the target directory
mkdir -p ${MIXER_CLI_DIR}
rm -f ${MIXER_CLI_DIR}/*

generateIndex > ${MIXER_CLI_DIR}/index.md
processPerBinaryFiles "mixc" 1 >  ${MIXER_CLI_DIR}/mixc.md
processPerBinaryFiles "mixs" 2 >  ${MIXER_CLI_DIR}/mixs.md

rm -rfd ${WORKING_DIR}
