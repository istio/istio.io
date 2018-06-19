#!/usr/bin/env sh
set -e

sass src/sass/light_theme_archive.scss light_theme_archive.css -s compressed
sass src/sass/light_theme_normal.scss light_theme_normal.css -s compressed
sass src/sass/light_theme_preliminary.scss light_theme_preliminary.css -s compressed
sass src/sass/dark_theme_archive.scss dark_theme_archive.css -s compressed
sass src/sass/dark_theme_normal.scss dark_theme_normal.css -s compressed
sass src/sass/dark_theme_preliminary.scss dark_theme_preliminary.css -s compressed
mv light_theme* static/css
mv dark_theme* static/css
uglifyjs src/js/misc.js src/js/prism.js --mangle --compress -o static/js/all.min.js --source-map
uglifyjs src/js/styleSwitcher.js --mangle --compress -o static/js/styleSwitcher.min.js --source-map
