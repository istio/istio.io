#! /bin/sh
# This script will spell check all markdown files in the repo,
# while style check those files, and finally will proof the
# final HTML looking for broken links and other common errors.
set -x
set -e

mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report *.md */*.md */*/*.md */*/*/*.md */*/*/*/*.md
mdl --ignore-front-matter --style mdl_style.rb .
bundle exec rake test
