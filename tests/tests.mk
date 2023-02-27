DEFAULT_TIMEOUT=60m
export TIMEOUT ?= ${DEFAULT_TIMEOUT}

_DOCTEST_FLAGS ?= ${DOCTEST_FLAGS}

# $(CI) specifies that the test is running in a CI system. This enables CI specific logging.
ifneq ($(CI),)
	_DOCTEST_FLAGS += --istio.test.ci
	_DOCTEST_FLAGS += --istio.test.pullpolicy=IfNotPresent
endif

ifneq ($(ARTIFACTS),)
    _DOCTEST_FLAGS += --istio.test.work_dir=$(ARTIFACTS)
endif

_DOCTEST_KUBECONFIG ?= $(DOCTEST_KUBECONFIG)
ifneq ($(_DOCTEST_KUBECONFIG),)
	_DOCTEST_FLAGS += --istio.test.kube.config=$(_DOCTEST_KUBECONFIG)
endif

_DOCTEST_NETWORK_TOPOLOGY ?= $(DOCTEST_NETWORK_TOPOLOGY)
ifneq ($(_DOCTEST_NETWORK_TOPOLOGY),)
	_DOCTEST_FLAGS += --istio.test.kube.networkTopology=$(_DOCTEST_NETWORK_TOPOLOGY)
endif

# gocache disabled by -count=1
# tests in different packages forced to be sequential by -p=1
doc.test.%: init | $(JUNIT_REPORT)
	${GO} test ${REPO_ROOT}/tests/setup/$*/... \
		-v -timeout=${TIMEOUT} -count=1 -p=1 \
		-istio.test.hub=$(HUB) \
		-istio.test.tag=$(TAG) \
		${_DOCTEST_FLAGS} \
		2>&1 | tee >($(JUNIT_REPORT) > $(JUNIT_OUT))

# gocache disabled by -count=1
# tests in different packages forced to be sequential by -p=1
doc.test: init | $(JUNIT_REPORT)
	${GO} test ${REPO_ROOT}/tests/setup/... \
		-v -timeout=${TIMEOUT} -count=1 -p=1 \
		-istio.test.hub=$(HUB) \
		-istio.test.tag=$(TAG) \
		${_DOCTEST_FLAGS} \
		2>&1 | tee >($(JUNIT_REPORT) > $(JUNIT_OUT))

doc.test.help:
	@echo "The command \"make doc.test\" accepts two optional environment variables."
	@echo -e "TEST: \n\tSpecify the test(s) to run using the directory path relative to content/en/docs. Default is all."
	@echo -e "\tMultiple test names can be specified by separating them by commas."
	@echo -e "TIMEOUT: \n\tSet the time limit exceeding which all tests will halt. Default is ${DEFAULT_TIMEOUT}."
	@echo -e "Example: \n\tmake doc.test TEST=tasks/traffic-management TIMEOUT=1h"
