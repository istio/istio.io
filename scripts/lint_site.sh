#!/usr/bin/env sh
set -e

mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report content/*.md content/*/*.md content/*/*/*.md content/*/*/*/*.md content/*/*/*/*/*.md content/*/*/*/*/*/*.md content/*/*/*/*/*/*/*.md
#mdspell --zh-cn --ignore-acronyms --ignore-numbers --no-suggestions --report content_zh/*.md content_zh/*/*.md content_zh/*/*/*.md content_zh/*/*/*/*.md content_zh/*/*/*/*/*.md content_zh/*/*/*/*/*/*.md content_zh/*/*/*/*/*/*/*.md
mdl --ignore-front-matter --style mdl_style.rb .
htmlproofer ./public --check-html --assume-extension --timeframe 2d --storage-dir .htmlproofer --url-ignore "/localhost/,/github.com/istio/istio.github.io/edit/master/,/github.com/istio/istio/issues/new/choose/"
