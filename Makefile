
img := gcr.io/istio-testing/website-builder:2018-08-17
docker := docker run -t -i --sig-proxy=true --rm -v $(shell pwd):/site -w /site $(img)

ifeq ($(CONTEXT),production)
baseurl := $(URL)
endif

build:
	$(docker) scripts/build_site.sh

gen:
	$(docker) scripts/gen_site.sh ""

lint:
	$(docker) scripts/lint_site.sh

serve:
	docker run -t -i --sig-proxy=true --rm -v $(shell pwd):/site -w /site -p 1313:1313 $(img) hugo serve --bind 0.0.0.0 --disableFastRender

netlify:
	scripts/gen_site.sh "$(baseurl)"
