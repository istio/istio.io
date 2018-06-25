#!/usr/bin/env sh

FAILED=0

mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report content/*.md content/*/*.md content/*/*/*.md content/*/*/*/*.md content/*/*/*/*/*.md content/*/*/*/*/*/*.md content/*/*/*/*/*/*/*.md
if [ "$?" != "0" ]
then
    echo "To learn how to address spelling errors, please see https://github.com/istio/istio.github.io#linting"
    FAILED=1
fi

mdspell --zh-cn --ignore-acronyms --ignore-numbers --no-suggestions --report content_zh/*.md content_zh/*/*.md content_zh/*/*/*.md content_zh/*/*/*/*.md content_zh/*/*/*/*/*.md content_zh/*/*/*/*/*/*.md content_zh/*/*/*/*/*/*/*.md
if [ "$?" != "0" ]
then
    echo "To learn how to address spelling errors, please see https://github.com/istio/istio.github.io#linting"
    FAILED=1
fi

mdl --ignore-front-matter --style mdl_style.rb .
if [ "$?" != "0" ]
then
    echo "To learn about markdown linting rules, please see https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md"
    FAILED=1
fi

#htmlproofer ./public --check-html --assume-extension --timeframe 2d --storage-dir .htmlproofer --url-ignore "/localhost/,/github.com/istio/istio.github.io/edit/master/,/github.com/istio/istio/issues/new/choose/"
if [ "$?" != "0" ]
then
    FAILED=1
fi

if [ $FAILED -eq 1 ]
then
    echo "LINTING FAILED"
    exit 1
fi
