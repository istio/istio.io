export TIMEOUT ?= 30m

# gocache disabled by -count=1
# tests in different packages forced to be sequential by -p=1
doc.test: init | $(JUNIT_REPORT)
	@${GO} test ${REPO_ROOT}/tests/setup/... \
		-v -timeout=${TIMEOUT} -count=1 -p=1 \
		-istio.test.hub=$(HUB) \
		-istio.test.tag=$(TAG) \
		2>&1 | tee >($(JUNIT_REPORT) > $(JUNIT_OUT))

doc.test.default: init | $(JUNIT_REPORT)
	@${GO} test ${REPO_ROOT}/tests/setup/profile_default... \
		-v -timeout=${TIMEOUT} -count=1 -p=1 \
		-istio.test.hub=$(HUB) \
		-istio.test.tag=$(TAG) \
		-istio.test.kube.helm.values=meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE="" \
		2>&1 | tee >($(JUNIT_REPORT) > $(JUNIT_OUT))

doc.test.demo: init | $(JUNIT_REPORT)
	@${GO} test ${REPO_ROOT}/tests/setup/profile_demo... \
		-v -timeout=${TIMEOUT} -count=1 -p=1 \
		-istio.test.hub=$(HUB) \
		-istio.test.tag=$(TAG) \
		-istio.test.kube.helm.values=meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE="" \
		2>&1 | tee >($(JUNIT_REPORT) > $(JUNIT_OUT))

doc.test.none: init | $(JUNIT_REPORT)
	@${GO} test ${REPO_ROOT}/tests/setup/profile_none... \
		-v -timeout=${TIMEOUT} -count=1 -p=1 \
		-istio.test.hub=$(HUB) \
		-istio.test.tag=$(TAG) \
		-istio.test.kube.helm.values=meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE="" \
		2>&1 | tee >($(JUNIT_REPORT) > $(JUNIT_OUT))

doc.test.help:
	@echo "The command \"make doc.test\" accepts three optional environment variables."
	@echo -e "TEST: \n\tSpecify the test(s) to run using the directory path relative to content/en/docs. Default is all."
	@echo -e "\tMultiple test names can be specified by separating them by commas."
	@echo -e "TIMEOUT: \n\tSet the time limit exceeding which all tests will halt. Default is 30m."
	@echo -e "Example: \n\tmake doc.test TEST=tasks/traffic-management TIMEOUT=1h"
