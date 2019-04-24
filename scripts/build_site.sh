#!/usr/bin/env sh
set -e

mkdir -p generated/css generated/js generated/img tmp/js

npx sass src/sass/_all.scss all.css -s compressed
mv all.css* generated/css
npx tsc
npx babel tmp/js/constants.js tmp/js/utils.js tmp/js/kbdnav.js tmp/js/themes.js tmp/js/menu.js tmp/js/header.js tmp/js/sidebar.js tmp/js/tabset.js tmp/js/prism.js tmp/js/codeBlocks.js tmp/js/links.js tmp/js/scroll.js tmp/js/overlays.js tmp/js/lang.js tmp/js/callToAction.js --out-file generated/js/all.min.js --source-maps --minified --no-comments --presets minify
npx babel tmp/js/themes_init.js --out-file generated/js/themes_init.min.js --source-maps --minified --no-comments --presets minify
npx svgstore -o generated/img/icons.svg src/icons/**/*.svg
