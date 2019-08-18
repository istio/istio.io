ISTIO_SERVE_DOMAIN ?= localhost
export ISTIO_SERVE_DOMAIN

ifeq ($(CONTEXT),production)
baseurl := "$(URL)"
endif

build:
	@scripts/build_site.sh

gen: build
	@scripts/gen_site.sh ""

gen_nominify: build
	@scripts/gen_site.sh "" -no_minify

opt:
	@scripts/opt_site.sh

clean_public:
	@rm -fr public

clean: clean_public
	@rm -fr resources .htmlproofer tmp

lint: clean_public gen_nominify
	@scripts/lint_site.sh

serve: build
	@hugo serve --baseURL "http://${ISTIO_SERVE_DOMAIN}:1313/" --bind 0.0.0.0 --disableFastRender

install:
	@npm init -y
	@npm install -g \
	    sass \
	    sass-lint \
	    typescript \
	    tslint \
	    markdown-spellcheck \
	    svgstore-cli \
	    svgo
	@npm install --save-dev @babel/core @babel/cli @babel/preset-env
	@npm install --save-dev babel-preset-minify
	@npm install --save @babel/polyfill

netlify: install
	@scripts/build_site.sh
	@scripts/gen_site.sh "$(baseurl)"

netlify_archive:
	@scripts/gen_archive_site.sh "$(baseurl)"

archive:
	@scripts/gen_archive_site.sh "$(baseurl)"

prow: lint

include Makefile.common.mk
