export ENV ?= kube
export TIMEOUT ?= 30m

# gocache disabled by -count=1
# tests in different packages forced to be sequential by -p=1
doc.test: init
	@${GO} test ${REPO_ROOT}/tests/setup/... -v -timeout=${TIMEOUT} -count=1 -p=1 \
		-istio.test.env=${ENV} -istio.test.hub=$(HUB) -istio.test.tag=$(TAG)

doc.test.help:
	@echo "The command \"make doc.test\" accepts three optional environment variables."
	@echo -e "TEST: \n\tSpecify the test(s) to run using the directory name. Default is all."
	@echo -e "\tMultiple test names can be specified by separating them by commas."
	@echo -e "TIMEOUT: \n\tSet the time limit exceeding which all tests will halt. Default is 30m."
	@echo -e "ENV: \n\tTest environment. This should be either native or kube. Default is kube."
	@echo -e "Example: \n\tmake doc.test TEST=request-routing,fault-injection TIMEOUT=1h"
