#! /bin/bash

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

# Build the archive site

set -e

BASEURL="$1"

# List of name:tagOrBranch
TOBUILD=(
  v1.2:release-1.2
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

# Prepare
TMP=$(mktemp -d)
mkdir "${TMP}/archive"

pushd "${TMP}" || exit
git clone -q https://github.com/istio/istio.io.git
pushd "istio.io" || exit

for rel in "${TOBUILD[@]}"; do
  NAME=$(echo "$rel" | cut -d : -f 1)
  TAG=$(echo "$rel" | cut -d : -f 2)
  URL=${BASEURL}/${NAME}

  echo "### Building '${NAME}' from ${TAG} for ${URL}"
  git checkout "${TAG}"

  scripts/gen_site.sh "${URL}"

  mv public "${TMP}/archive/${NAME}"
  echo "- name:  \"${NAME}\"" >> "${TMP}/archives.yml"

  git clean -f
done

for rel in "${TOBUILD_JEKYLL[@]}"; do
  NAME=$(echo "$rel" | cut -d : -f 1)
  TAG=$(echo "$rel" | cut -d : -f 2)
  URL=${BASEURL}/${NAME}

  echo "### Building '${NAME}' from ${TAG} for ${URL}"
  git checkout "${TAG}"
  echo "baseurl: ${URL}" > config_override.yml

  echo BEFORE
  sass --version
  which sass

  bundle install
  bundle exec jekyll build --config _config.yml,config_override.yml

  echo AFTER
  sass --version
  which sass

  mv _site "${TMP}/archive/${NAME}"
  echo "- name:  \"${NAME}\"" >> "${TMP}/archives.yml"

  git clean -f
done

echo "### Building landing page"
popd || exit
popd || exit

# Adjust a few things for archive_landing
rm -fr content/en/about content/en/docs content/en/faq content/en/blog content/zh
rm -fr static/talks
sed -i 's/preliminary: true/preliminary: false/g' data/args.yml
sed -i 's/archive_landing: false/archive_landing: true/g' data/args.yml

# Grab the state
cp "${TMP}/archives.yml" data

scripts/build_site.sh
scripts/gen_site.sh "$1"

mv public/* "${TMP}/archive"
rm -fr public
mv "${TMP}/archive" public
rm -fr "${TMP}"

echo "All done!"
