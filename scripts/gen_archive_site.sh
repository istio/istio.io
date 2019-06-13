#! /bin/bash
#
# Build the archive site
#

# List of name:tagOrBranch
TOBUILD=(
  v1.0:release-1.0
  v0.8:release-0.8
)

TOBUILD_JEKYLL=(
  v0.7:release-0.7
  v0.6:release-0.6
  v0.5:release-0.5
  v0.4:release-0.4
  v0.3:release-0.3
  v0.2:release-0.2
  v0.1:release-0.1
)

# Prepare
TMP=$(mktemp -d)
mkdir ${TMP}/archive

GITDIR=istio.io
rm -fr ${GITDIR}
git clone https://github.com/istio/istio.io.git
cd ${GITDIR}

# Grab the latest version info
cp data/versions.yml ${TMP}

for rel in "${TOBUILD[@]}"
do
  NAME=$(echo $rel | cut -d : -f 1)
  TAG=$(echo $rel | cut -d : -f 2)
  BASEURL=$(echo /$NAME)
  echo "### Building '$NAME' from $TAG for $BASEURL"
  git clean -f
  git checkout ${TAG}
  cp ${TMP}/versions.yml data

  scripts/gen_site.sh ${BASEURL}

  mv public ${TMP}/archive/${NAME}
  echo "- name:  \"${NAME}\"" >> ${TMP}/archives.yml
done

for rel in "${TOBUILD_JEKYLL[@]}"
do
  NAME=$(echo $rel | cut -d : -f 1)
  TAG=$(echo $rel | cut -d : -f 2)
  echo "### Building '$NAME' from $TAG"
  git clean -f
  git checkout ${TAG}
  echo "baseurl: /$NAME" > config_override.yml
  cp ${TMP}/versions.yml _data

  bundle install
  bundle exec jekyll build --config _config.yml,config_override.yml

  mv _site ${TMP}/archive/${NAME}
  echo "- name:  \"${NAME}\"" >> ${TMP}/archives.yml
done

echo "### Building landing page"
git clean -f
git checkout archive

# Grab the state
cp ${TMP}/archives.yml data

# Adjust a few things for archive_landing
rm -fr static/talks

scripts/gen_site.sh "https://archive.istio.io"

mv public/* ${TMP}/archive
cd ..
rm -fr ${GITDIR} public
mv ${TMP}/archive public
rm -fr ${TMP}

npx svgo -r -f public

echo "All done!"
