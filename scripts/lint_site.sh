#!/usr/bin/env sh

mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report content/*.md content/*/*.md content/*/*/*.md content/*/*/*/*.md content/*/*/*/*/*.md content/*/*/*/*/*/*.md content/*/*/*/*/*/*/*.md
mdl --ignore-front-matter --style mdl_style.rb .
htmlproofer ./public --check-html --assume-extension --timeframe 2d --storage-dir .htmlproofer --url-ignore "/localhost/,/github.com/istio/istio.github.io/edit/master/,/github.com/istio/istio/issues/new/choose/"
