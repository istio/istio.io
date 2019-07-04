#! /bin/bash
#
# Build the archive site
#

BASEURL="$1"

# List of name:tagOrBranch
TOBUILD=(
  v1.1:release-1.1
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

# Prereqs
npm install sass sass-lint typescript tslint @babel/cli @babel/core svgstore-cli html-minifier --save-dev
npm install babel-preset-minify --save-dev

# Prepare
TMP=$(mktemp -d)
mkdir ${TMP}/archive

GITDIR=istio.io
rm -fr ${GITDIR}
git clone https://github.com/istio/istio.io.git
cd ${GITDIR}

for rel in "${TOBUILD[@]}"
do
  NAME=$(echo $rel | cut -d : -f 1)
  TAG=$(echo $rel | cut -d : -f 2)
  URL=$(echo ${BASEURL}/${NAME})

  echo "### Building '${NAME}' from ${TAG} for ${URL}"
  git checkout ${TAG}

  scripts/gen_site.sh ${URL}

  mv public ${TMP}/archive/${NAME}
  echo "- name:  \"${NAME}\"" >> ${TMP}/archives.yml

  git clean -f
done

for rel in "${TOBUILD_JEKYLL[@]}"
do
  NAME=$(echo $rel | cut -d : -f 1)
  TAG=$(echo $rel | cut -d : -f 2)
  URL=$(echo ${BASEURL}/${NAME})

  echo "### Building '${NAME}' from ${TAG} for ${URL}"
  git checkout ${TAG}
  echo "baseurl: ${URL}" > config_override.yml

  bundle install
  bundle exec jekyll build --config _config.yml,config_override.yml

  mv _site ${TMP}/archive/${NAME}
  echo "- name:  \"${NAME}\"" >> ${TMP}/archives.yml

  git clean -f
done

echo "### Building landing page"
cd ..

# Adjust a few things for archive_landing
rm -fr content/about content/docs content/faq content/blog content_zh
rm -fr static/talks
sed -i 's/preliminary: true/preliminary: false/g' data/args.yml
sed -i 's/archive_landing: false/archive_landing: true/g' data/args.yml

# Grab the state
cp ${TMP}/archives.yml data

scripts/build_site.sh
scripts/gen_site.sh "$1"

mv public/* ${TMP}/archive
rm -fr ${GITDIR} public
mv ${TMP}/archive public
rm -fr ${TMP}

echo "All done!"
