# Get the source directory for this project
ISTIOIO_GO := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
export ISTIOIO_GO
SHELL := /bin/bash -o pipefail

export GO111MODULE ?= on
export GOPROXY ?= https://proxy.golang.org
export GOSUMDB ?= sum.golang.org

# If GOPATH is not set by the env, set it to a sane value
GOPATH ?= $(shell cd ${ISTIOIO_GO}/../../..; pwd)
export GOPATH

# Set the directory for Istio source.
ISTIO_GO ?= $(GOPATH)/src/istio.io/istio
export ISTIO_GO

# If GOPATH is made up of several paths, use the first one for our targets in this Makefile
GO_TOP := $(shell echo ${GOPATH} | cut -d ':' -f1)
export GO_TOP

GO ?= go

export GOARCH_LOCAL := $(TARGET_ARCH)
export GOOS_LOCAL := $(TARGET_OS)
export IN_BUILD_CONTAINER := $(IN_BUILD_CONTAINER)

# ISTIO_IMAGE_VERSION stores the prefix used by default for the Docker images for Istio.
# For example, a value of 1.6-alpha will assume a default TAG value of 1.6-dev.<SHA>
ISTIO_IMAGE_VERSION ?= 1.19-alpha
export ISTIO_IMAGE_VERSION

# Determine the SHA for the Istio dependency by parsing the go.mod file.
ISTIO_SHA ?= $(shell < ${ISTIOIO_GO}/go.mod grep 'istio.io/istio v' | cut -d'-' -f3)
export ISTIO_SHA

# export ISTIO_LONG_SHA here. We will set the value in the `init` target
export ISTIO_LONG_SHA

# In the case that the images are build as part of a the normal public istio/istio pipeline,
# we only need to export the pipeline HUB value.
# If the images were built as part of the private pipeline (as for security releases),
# we export the HUB and TAG for the images once they are published.
HUB ?= gcr.io/istio-testing
# export HUB := docker.io/istio
# export TAG ?= 1.7.3

ifeq ($(HUB),)
  $(error "HUB cannot be empty")
endif

# Environment for tests, the directory containing istio and deps binaries.
# Typically same as GOPATH/bin, so tests work seemlessly with IDEs.

export ISTIO_BIN=$(GOBIN)
# Using same package structure as pkg/

export ISTIO_BIN=$(GOBIN)
export ISTIO_OUT:=$(TARGET_OUT)
export ISTIO_OUT_LINUX:=$(TARGET_OUT_LINUX)

export ARTIFACTS ?= $(ISTIO_OUT)
export JUNIT_OUT ?= $(ARTIFACTS)/junit.xml
export REPO_ROOT := $(shell git rev-parse --show-toplevel)

# Make directories needed by the build system
$(shell mkdir -p $(ISTIO_OUT))
$(shell mkdir -p $(dir $(JUNIT_OUT)))

JUNIT_REPORT := $(shell which go-junit-report 2> /dev/null || echo "${ISTIO_BIN}/go-junit-report")

ISTIO_SERVE_DOMAIN ?= localhost
export ISTIO_SERVE_DOMAIN

ifeq ($(CONTEXT),production)
baseurl := "$(URL)"
endif

# Which branch of the Istio source code do we fetch stuff from
export SOURCE_BRANCH_NAME ?= master

site:
	@scripts/gen_site.sh

snips:
	@scripts/gen_snips.sh

gen: tidy-go format-go snips

gen-check: gen check-clean-repo check-localization

check-localization:
	@scripts/check_localization.sh

build: site
	@scripts/build_site.sh ""

build_nominify: site
	@scripts/build_site.sh "" -no_minify

build_with_archive: site
	@scripts/gen_site.sh
	@scripts/build_site.sh "/latest"
	@scripts/include_archive_site.sh

opt:
	@scripts/opt_site.sh

clean:
	@rm -fr resources .htmlproofer tmp generated public out samples install go tests/integration/ manifests

lint: clean_public build_nominify lint-copyright-banner lint-python lint-yaml lint-dockerfiles lint-scripts lint-sass lint-typescript lint-go
	@scripts/lint_site.sh

lint-en: clean_public build_nominify lint-copyright-banner lint-python lint-yaml lint-dockerfiles lint-scripts lint-sass lint-typescript lint-go
	@scripts/lint_site.sh en

lint-fast: clean_public build_nominify lint-copyright-banner lint-python lint-yaml lint-dockerfiles lint-scripts lint-sass lint-typescript lint-go
	@SKIP_LINK_CHECK=true scripts/lint_site.sh en

lint-md: clean_public build_nominify
	@SKIP_LINK_CHECK=true scripts/lint_site.sh en

serve: site
	@hugo serve --baseURL "http://${ISTIO_SERVE_DOMAIN}:1313/latest/" --bind 0.0.0.0 --disableFastRender

archive-version:
	@scripts/archive_version.sh

# used by netlify.com when building the site. The tool versions should correspond
# to what is included in the tools repo in docker/build-tools/Dockerfile.
netlify_install:
	@npm init -y
	@npm install --production --global \
	    sass@v1.23.7 \
	    typescript@v3.7.2 \
	    svgstore-cli@v1.3.1 \
		@babel/core@v7.7.4 \
		@babel/cli@v7.7.4 \
		@babel/preset-env@v7.7.4
	@npm install --production --save-dev \
		babel-preset-minify@v0.5.1
	@npm install --save-dev \
		@babel/polyfill@v7.7.0

netlify: netlify_install
	@scripts/gen_site.sh
	@scripts/build_site.sh "/latest"
	@scripts/include_archive_site.sh

# ISTIO_API_GIT_SOURCE allows to override the default Istio API repository, https://github.com/istio/api@$(SOURCE_BRANCH_NAME)
# with, for example, a mapped local directory: file:///work/istio/api@branch-name when running `update_ref_docs`.
#
# The format for ISTIO_API_GIT_SOURCE value is {GIT_URL}@{TARGET_BRANCH_NAME}.
#
# Note that when running with BUILD_WITH_CONTAINER=1, we can map the local directory by setting
# the ADDITIONAL_CONTAINER_OPTIONS environment variable as shown in the below example:
#
# $ BUILD_WITH_CONTAINER=1 \
#   ISTIO_API_GIT_SOURCE="file:///work/istio/api@branchname" \
#   ADDITIONAL_CONTAINER_OPTIONS="-v /path/to/local/istio/api:/work/istio/api" \
#   	make update_ref_docs
export ISTIO_API_GIT_SOURCE ?=
update_ref_docs:
	@scripts/grab_reference_docs.sh $(SOURCE_BRANCH_NAME) $(ISTIO_API_GIT_SOURCE)

update_test_reference: get_istio_sha gen

get_istio_sha:
	@go get istio.io/istio@$(SOURCE_BRANCH_NAME) && go mod tidy

update_all: update_ref_docs update_test_reference

foo2:
	hugo version

# Release related targets
export ISTIOIO_GIT_SOURCE := https://github.com/istio/istio.io.git
export MASTER := master

prepare-%:
	@scripts/prepare_release.sh $@

release-%-dry-run:
	@DRY_RUN=1 scripts/create_version.sh $(subst -dry-run,,$@)

release-%:
	@scripts/create_version.sh $@

build-old-archive-%:
	@scripts/build_old_archive.sh $@

# The init recipe was split into two recipes to solve an issue seen in prow
# where paralyzation is happening and some tasks in a recipe were occuring out
# of order. The desired behavior is for `preinit` to do the clone and set up the
# istio/istio directory. Then the eval task in `init` will have the directory in
# which to run the `git command.
.PHONY: preinit init
preinit:
	@echo "ISTIO_SHA = ${ISTIO_SHA}"
	@echo "HUB = ${HUB}"
	@bin/init.sh

init: preinit
	$(eval ISTIO_LONG_SHA := $(shell cd ${ISTIO_GO} && git rev-parse ${ISTIO_SHA}))
	@echo "ISTIO_LONG_SHA=${ISTIO_LONG_SHA}"
ifndef TAG
	$(eval TAG := ${ISTIO_IMAGE_VERSION}.${ISTIO_LONG_SHA})
endif
# If a variant is defined, update the tag accordingly
ifdef VARIANT
	$(eval TAG=${TAG}-${VARIANT})
endif
	@export TAG
	@echo "TAG=${TAG}"
	$(eval BASE_VERSION := $(shell cd ${ISTIO_GO} && grep BASE_VERSION Makefile.core.mk | awk '{ print $$3}'))
	@echo "BASE_VERSION=${BASE_VERSION}"
	@export BASE_VERSION

# doc test framework
include tests/tests.mk

# remains of old framework to pass istio-testing
test.kube.presubmit: doc.test

# remains of old framework to pass istio-testing
test.kube.postsubmit: test.kube.presubmit

test_status:
	@scripts/test_status.sh

update-gateway-version: tidy-go
	@$(eval GATEWAY_VERSION := ${shell grep gateway-api go.mod | awk '{ print $$2 }'})
	@${shell sed -Ei 's|k8s_gateway_api_version: ".*"|k8s_gateway_api_version: "${GATEWAY_VERSION}"|' 'data/args.yml'}


include common/Makefile.common.mk

.PHONY: site gen build build_nominify opt clean_public clean lint serve netlify_install netlify netlify_archive archive update_ref_docs update_operator_yamls update_all update_gateway_version
