ISTIO_SERVE_DOMAIN ?= localhost
export ISTIO_SERVE_DOMAIN

img := gcr.io/istio-testing/website-tools:2019-07-25
uid := $(shell id -u)
docker := docker run -e INTERNAL_ONLY=true -t -i --sig-proxy=true --rm --user $(uid) -v /etc/passwd:/etc/passwd:ro -v $(shell pwd):/site -w /site $(img)

ifeq ($(INTERNAL_ONLY),)
docker := docker run -t -i --sig-proxy=true --rm --user $(uid) -v /etc/passwd:/etc/passwd:ro -v $(shell pwd):/site -w /site $(img)
endif

ifeq ($(CONTEXT),production)
baseurl := "$(URL)"
endif

build:
	@$(docker) scripts/build_site.sh

gen: build
	@$(docker) scripts/gen_site.sh ""

opt:
	@$(docker) scripts/opt_site.sh

clean_public:
	@rm -fr public

clean: clean_public
	@rm -fr resources .htmlproofer tmp

lint: clean_public build gen
	@$(docker) scripts/lint_site.sh

serve: build
	@docker run -t -i --sig-proxy=true --rm --user $(uid) -v /etc/passwd:/etc/passwd:ro -v $(shell pwd):/site -w /site -p 1313:1313 $(img) hugo serve --baseURL "http://${ISTIO_SERVE_DOMAIN}:1313/" --bind 0.0.0.0 --disableFastRender

install:
	@npm install -g sass sass-lint typescript tslint @babel/cli @babel/core svgstore-cli
	@npm install babel-preset-minify --save-dev

netlify: install
	@scripts/build_site.sh
	@scripts/gen_site.sh "$(baseurl)"

netlify_archive:
	@scripts/gen_archive_site.sh "$(baseurl)"

archive:
	@$(docker) scripts/gen_archive_site.sh "$(baseurl)"

include Makefile.common.mk
