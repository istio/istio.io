# Get the source directory for this project
ISTIOIO_GO := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
export ISTIOIO_GO
SHELL := /bin/bash -o pipefail

VERSION ?= latest

export GO111MODULE ?= on
export GOPROXY ?= https://proxy.golang.org
export GOSUMDB ?= sum.golang.org

# If GOPATH is not set by the env, set it to a sane value
GOPATH ?= $(shell cd ${ISTIOIO_GO}/../../..; pwd)
export GOPATH

# Set the directory for Istio source.
ISTIO_GO ?= "${GOPATH}/src/istio.io/istio"
export ISTIO_GO

# If GOPATH is made up of several paths, use the first one for our targets in this Makefile
GO_TOP := $(shell echo ${GOPATH} | cut -d ':' -f1)
export GO_TOP

GO ?= go

GOARCH_LOCAL := $(TARGET_ARCH)
GOOS_LOCAL := $(TARGET_OS)

HUB ?= gcr.io/istio-testing
ifeq ($(HUB),)
  $(error "HUB cannot be empty")
endif

TAG ?= latest
ifeq ($(TAG),)
  $(error "TAG cannot be empty")
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
SOURCE_BRANCH_NAME ?= master

gen:
	@scripts/gen_site.sh

build: gen
	@scripts/build_site.sh ""

build_nominify: gen
	@scripts/build_site.sh "" -no_minify

opt:
	@scripts/opt_site.sh

clean:
	@rm -fr resources .htmlproofer tmp generated public

lint: clean_public build_nominify lint-copyright-banner lint-python lint-yaml lint-dockerfiles lint-scripts lint-sass lint-typescript lint-go
	@scripts/lint_site.sh

serve: gen
	@hugo serve --baseURL "http://${ISTIO_SERVE_DOMAIN}:1313/" --bind 0.0.0.0 --disableFastRender

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
	@scripts/build_site.sh "$(baseurl)"

netlify_archive: netlify_install archive

archive:
	@scripts/build_archive_site.sh "$(baseurl)"

update_ref_docs:
	@scripts/grab_reference_docs.sh $(SOURCE_BRANCH_NAME)

update_operator_yamls:
	@scripts/grab_operator_yamls.sh $(SOURCE_BRANCH_NAME)

update_all: update_ref_docs update_operator_yamls update_examples

foo2:
	hugo version

.PHONY: init
init:
	bin/init.sh

include tests/tests.mk

# make lint-yaml seems to fail with pipefail, so remove now.
SHELL = /bin/bash

include common/Makefile.common.mk

.PHONY: gen build build_nominify opt clean_public clean lint serve netlify_install netlify netlify_archive archive update_ref_docs update_operator_yamls update_examples update_all
