#!/usr/bin/env sh
set -e

svgo --version

npx svgo -r -f content/en
npx svgo -r -f content/zh
npx svgo -r -f src/icons
