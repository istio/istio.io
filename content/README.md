# Testing istio.io Content (New Framework)

This is the new test framework for istio.io documentation. 

The tests should be run at least when:
- changes are made or new tests are added to the doc
- changes are made to the istio source code

## How to Test

Run
```bash
make doc.test
```
to start testing all docs in the content folder within a `kube` environment. This command takes two optional environment variables. One is `ENV` that specifies the test environment (either `native` or `kube`), and is `kube` by default. The other is `TEST` that specifies the tests to be run using the name of the directory. For example, the command
```bash
make doc.test TEST=traffic-management
```
will run all the tests under `traffic-management` folder. The `TEST` variable also accepts multiple test names separated by commas, for example,
```bash
make doc.test TEST=request-routing,fault-injection
```
This information can be obtained by running `make doc.test.help`.

## Migrate from Old Framework

Take `traffic-management/request-routing` as an example. To migrate to the new framework, the test author should:

1. Create a `test.sh` file beside its corresponding `index.md` and `snips.sh`, i.e., `content/en/docs/tasks/traffic-management/request-routing/test.sh`.

2. Copy the test script `request-routing.sh` (under `tests/trafficmanagement/scripts/`) and the cleanup script in `request_routing_test.go` (under `tests/trafficmanagement/`) into `test.sh`, and separate the two parts with a line of `#! cleanup`.

3. It is okay to remove any `source *.sh` commands from `test.sh` as these will be automatically done.

Every future `test.sh` will thus have a structure of:
```
run_a_bunch_of_test_snippets
no_need_to_source_snips_and_utils_ever_again

#! cleanup
run_a_bunch_of_cleanup_snippets
and_we_are_done
```