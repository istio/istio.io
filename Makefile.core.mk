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

lint: clean_public gen_nominify lint-copyright-banner lint-python lint-yaml lint-dockerfiles lint-scripts lint-sass lint-typescript lint-go
	@scripts/lint_site.sh

serve: build
	@hugo serve --baseURL "http://${ISTIO_SERVE_DOMAIN}:1313/" --bind 0.0.0.0 --disableFastRender

# used by netlify.com when building the site. The tool versions should correspond
# to what is included in the tools repo in docker/build-tools/Dockerfile.
netlify_install:
	@npm init -y
	@npm install --production --global \
	    sass@v1.22.10 \
	    typescript@v3.5.3 \
	    svgstore-cli@v1.3.1 \
		@babel/core@v7.5.5 \
		@babel/cli@v7.5.5 \
		@babel/preset-env@v7.5.5
	@npm install --production --save-dev \
		babel-preset-minify@v0.5.1
	@npm install --save-dev \
		@babel/polyfill@v7.4.4

netlify: netlify_install
	@scripts/build_site.sh
	@scripts/gen_site.sh "$(baseurl)"

netlify_archive: netlify_install archive

archive:
	@scripts/gen_archive_site.sh "$(baseurl)"

update_ref_docs:
	@scripts/grab_reference_docs.sh

include common/Makefile.common.mk
