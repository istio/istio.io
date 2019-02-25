#!/usr/bin/env sh
set -e

mkdir -p generated/css generated/js generated/img

npx sass src/sass/_all.scss all.css -s compressed
mv all.css* generated/css
npx babel src/js/menu.js src/js/header.js src/js/sidebar.js src/js/tabs.js src/js/prism.js src/js/codeBlocks.js src/js/links.js src/js/scroll.js src/js/overlays.js src/js/clipboard.js --out-file generated/js/all.min.js --source-maps --minified --no-comments --presets minify
npx babel src/js/constants.js src/js/utils.js src/js/styleSwitcher.js --out-file generated/js/styleSwitcher.min.js --source-maps --minified --no-comments --presets minify
npx svgstore -o generated/img/icons.svg src/icons/**/*.svg
