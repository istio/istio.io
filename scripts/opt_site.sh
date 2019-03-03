#!/usr/bin/env sh
set -e

svgo --version

npx svgo -f content
npx svgo -f content_zh
