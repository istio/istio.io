export ENV ?= kube

doc.test: init # gocache disabled by -count=1
	@${GO} test ${REPO_ROOT}/content/ -v -timeout=30m -count=1 \
		-istio.test.env=${ENV} -istio.test.hub=$(HUB) -istio.test.tag=$(TAG)

doc.test.help:
	@echo "The command \"make doc.test\" accepts two optional environment variables."
	@echo -e "ENV: \n\tTest environment. This should be either native or kube. Default is kube."
	@echo -e "TEST: \n\tSpecify the test(s) to run using the directory name. Default is all."
	@echo -e "\tMultiple test names can be specified by separating them by commas."
	@echo -e "Example: \n\tmake doc.test ENV=native TEST=request-routing"
