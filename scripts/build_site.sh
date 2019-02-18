#!/usr/bin/env sh
set -e

mkdir -p static/css static/js static/img

npx sass src/sass/light_theme_archive.scss light_theme_archive.css -s compressed
npx sass src/sass/light_theme_normal.scss light_theme_normal.css -s compressed
npx sass src/sass/light_theme_preliminary.scss light_theme_preliminary.css -s compressed
npx sass src/sass/dark_theme_archive.scss dark_theme_archive.css -s compressed
npx sass src/sass/dark_theme_normal.scss dark_theme_normal.css -s compressed
npx sass src/sass/dark_theme_preliminary.scss dark_theme_preliminary.css -s compressed
mv light_theme* generated/css
mv dark_theme* generated/css
npx babel src/js/misc.js src/js/prism.js src/js/utils.js src/js/codeBlocks.js src/js/links.js src/js/scroll.js src/js/overlays.js src/js/clipboard.js --out-file generated/js/all.min.js --source-maps --minified --no-comments --presets minify
npx babel src/js/styleSwitcher.js --out-file generated/js/styleSwitcher.min.js --source-maps --minified --no-comments --presets minify
npx svgstore -o generated/img/icons.svg src/icons/**/*.svg
