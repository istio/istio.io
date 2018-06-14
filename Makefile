
all: prep build generate lint

prep: prep_build prep_lint prep_generate

##########

prep_generate:
	npm install --prefix .tools/node html-minifier

generate:
	hugo --baseURL $(URL)
	.tools/node/node_modules/html-minifier/cli.js --input-dir public --output-dir public --file-ext html --collapse-whitespace --minify-js --minify-css --sort-attributes --sort-class-name --remove-attribute-quotes --remove-comments

##########

prep_build:
	npm install --prefix .tools/node sass
	npm install --prefix .tools/node uglify-js

build:
	.tools/node/node_modules/sass/sass.js src/sass/light_theme_archive.scss light_theme_archive.css -s compressed
	.tools/node/node_modules/sass/sass.js src/sass/light_theme_normal.scss light_theme_normal.css -s compressed
	.tools/node/node_modules/sass/sass.js src/sass/light_theme_preliminary.scss light_theme_preliminary.css -s compressed
	.tools/node/node_modules/sass/sass.js src/sass/dark_theme_archive.scss dark_theme_archive.css -s compressed
	.tools/node/node_modules/sass/sass.js src/sass/dark_theme_normal.scss dark_theme_normal.css -s compressed
	.tools/node/node_modules/sass/sass.js src/sass/dark_theme_preliminary.scss dark_theme_preliminary.css -s compressed
	mv light_theme* static/css
	mv dark_theme* static/css
	.tools/node/node_modules/uglify-js/bin/uglifyjs src/js/misc.js src/js/prism.js --mangle --compress -o static/js/all.min.js --source-map
	.tools/node/node_modules/uglify-js/bin/uglifyjs src/js/styleSwitcher.js --mangle --compress -o static/js/styleSwitcher.min.js --source-map

##########

prep_lint:
	npm install --prefix .tools/node markdown-spellcheck
	gem install mdl
	gem install html-proofer

lint:
	.tools/node/node_modules/markdown-spellcheck/bin/mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report content/*.md content/*/*.md content/*/*/*.md content/*/*/*/*.md content/*/*/*/*/*.md content/*/*/*/*/*/*.md content/*/*/*/*/*/*/*.md
	mdl --ignore-front-matter --style mdl_style.rb .
	htmlproofer ./public --check-html --assume-extension --timeframe 2d --storage-dir .htmlproofer --url-ignore "/localhost/,/github.com/istio/istio.github.io/edit/master/,/github.com/istio/istio/issues/new/choose/"

prep_lint_local:
	npm install --prefix .tools/node markdown-spellcheck
	gem install mdl --install-dir .tools
	gem install html-proofer --install-dir .tools

lint_local:
	.tools/node/node_modules/markdown-spellcheck/bin/mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report content/*.md content/*/*.md content/*/*/*.md content/*/*/*/*.md content/*/*/*/*/*.md content/*/*/*/*/*/*.md content/*/*/*/*/*/*/*.md
	.tools/bin/mdl --ignore-front-matter --style mdl_style.rb .
	.tools/bin/htmlproofer ./public --check-html --assume-extension --timeframe 2d --storage-dir .htmlproofer --url-ignore "/localhost/,/github.com/istio/istio.github.io/edit/master/,/github.com/istio/istio/issues/new/choose/"
