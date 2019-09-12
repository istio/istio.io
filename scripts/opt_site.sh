#!/usr/bin/env sh
set -e

svgo --version

npx svgo -r -f content
npx svgo -r -f content_zh
npx svgo -r -f src/icons
