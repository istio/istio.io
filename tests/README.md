# Testing istio.io Content

This folder contains tests for the content on [istio.io](http://istio.io).
More specifically, these tests confirm that the example, task, and other documents, which contain
instructions in the form of bash commands and expected output, are working as documented.

Generated bash scripts, containing the set of commands and expected output for corresponding
istio.io markdown files, are used by test programs to invoke the commands and verify the output.
This means that we extract and test the exact same commands that are published in the documents.

These tests use the framework defined in the `istioio` package, which is a thin wrapper
around the [Istio test framework](https://github.com/istio/istio/wiki/Istio-Test-Framework).

Run the following command to see the current test coverage, including the list of documents
that are in need of a test:

```sh
make test_status
```

## Test Authoring Overview

To write an `istio.io` test, follow these steps:

1. In the metadata at the top of the `index.md` file to be tested, change the field `test: no` to
   `test: yes`. This field is used to indicate that the markdown file will be tested and therefore
   requires a generated bash script containing the commands described in the document.

1. Run `make snips` to generate the bash script. After the command completes, you should see
   a new file, `snips.sh`, next to the `index.md` file that you modified in the previous step.

   Each bash command in `index.md` (i.e., `{{< text bash >}}` code block) will produce a bash
   function in `snips.sh` containing the same command(s) as in the document. Other types of code blocks,
   e.g., `{{< text yaml >}}`, will produce a bash variable containing the block content.

   By default, the bash function or variable will be named `snip_<section>_<code block number>`.
   For example, the first `{{< text bash >}}` code block in a section titled
   `## Apply weight-based routing` will generate a bash function named `snip_apply_weightbased_routing_1()`.

   You can override the default name by adding `snip_id=<some name>` to the corresponding text block attributes.
   For example `{{< text syntax=bash snip_id=config_all_v1 >}}` will generate `snip_config_all_v1()`.

   If a bash code block contains both commands and output, the `snips.sh` script will include
   both a bash function and a variable containing the expected output. The name of the variable
   will be the same as the function, only with `_out` appended.

1. Run `make lint-fast` to check for script errors.

   If there are any lint errors in the generated `snip.sh` file,
   it means that a command in the `index.md` file is not following `bash` best practices.
   Because we are extracting the commands from the markdown file into a script file, we get the
   added benefit of lint checking of the commands that appear in the docs.

   Fix the errors, if any, by updating the corresponding command in the `index.md` file and
   then regenerate the snips.

1. Create a test bash script named `test.sh` next to the `snips.sh` you have just generated.
   
   If your document is very large and you want to break it into multiple tests, create multiple scripts with the suffix `test.sh`, instead.
   
   Other scripts in the directory will be ignored.

## Test Bash Script

Your bash script will consist of a series of test steps that call the commands in your generated `snips.sh` file, as well as a series of cleanup steps that should be run after everything is done.

Before the test steps, there should be one line that specifies the istio setup configuration for the test. The setup line should take the form of
```sh
# @setup <setup_config>
```
Currently supported setup configurations include: `profile=default` to install the default profile, `profile=demo` to install the demo profile, and `profile=none` to not installing istio at all.

After setup, you will use snippets generated from the docs to write tests. The framework automatically sources several bash scripts for you, including the generated `snips.sh` and `tests/util/[verify|debug|helpers].sh`. You can directly call any function defined in them. For other test utilities, e.g., `util/samples.sh`, you need to source them yourself:

```sh
source "tests/util/samples.sh"

startup_bookinfo_sample  # from util/samples.sh
snip_config_50_v3        # from snips.sh
```

For commands that produce output, pass the snip and expected output to an appropriate
`_verify_` function. For example:

```sh
_verify_same snip_set_up_the_cluster_3 "$snip_set_up_the_cluster_3_out"
```

The verify functions first run the snip function and then compare the result to the
expected output. The framework includes the following built-in verify functions:

1. **`_verify_same`** `func` `expected`

   Runs `func` and compares the output with `expected`. If they are not the same,
   exponentially back off and try again, 5 times by default. The number of retries
   can be changed by setting the `VERIFY_RETRIES` environment variable.

1. **`_verify_contains`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output does not
   contain the substring `expected`, exponentially back off and try again, 5 times
   by default. The number of retries can be changed by setting the `VERIFY_RETRIES`
   environment variable.

1. **`_verify_not_contains`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the command execution fails
   or the output contains the substring `expected`,
   exponentially back off and try again, 5 times by default. The number of retries
   can be changed by setting the `VERIFY_RETRIES` environment variable.

1. **`_verify_elided`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output does not
   contain the lines in `expected` where "..." on a line matches one or more lines
   containing any text, exponentially back off and try again, 5 times by default.
   The number of retries can be changed by setting the `VERIFY_RETRIES` environment
   variable.

1. **`_verify_like`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output is not
   "like" `expected`, exponentially back off and try again, 5 times by default. The number
   of retries can be changed by setting the `VERIFY_RETRIES` environment variable.
   Like implies:

   - Same number of lines
   - Same number of whitespace-seperated tokens per line
   - Tokens can only differ in the following ways:

     1. different elapsed time values (e.g., `30s` is like `5m`)
     1. different ip values (e.g., `172.21.0.1` is like `10.0.0.31`)
     1. prefix match ending with a dash character (e.g., `reviews-v1-12345...` is like `reviews-v1-67890...`)
     1. expected `...` is a wildcard token, matches anything

   This function is useful for comparing the output of commands that include some run-specific
   values in the output (e.g., `kubectl get pods`), or when whitespace in the output may be different.

1. **`_verify_lines`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output does not
   "conform to" the specification in `expected`,
   exponentially back off and try again, 5 times by default. The number of retries
   can be changed by setting the `VERIFY_RETRIES` environment variable.
   Conformance implies:

   1. For each line in `expected` with the prefix "+ " there must be at least one
      line in the output containing the following string.
   1. For each line in `expected` with the prefix "- " there must be no line in
      the output containing the following string.

1. **`_verify_failure`** `func`

   Runs `func` and confirms that it fails (i.e., non-zero return code). This function is useful
   for testing commands that demonstrate configurations that are expected to fail.

After all test steps are complete, add the following line to indicate the start of the cleanup steps.
These steps will be run by the framework, even if the test fails and prematurely exits.
```sh
# @cleanup
```
The following cleanup steps must remove all resources and reverse configuration changes made during the test steps. These steps can also directly call functions defined in the auto-sourced scripts described before, as well as any script you have sourced by yourself for the test steps.

## Running The Tests

Run
```bash
make doc.test
```
to start testing all docs in the content folder within a `kube` environment. This command takes three optional environment variables: `TEST`, `TIMEOUT` and `ENV`.

`TEST` specifies the tests to be run using the path of the directory relative to `content/en/docs/`. For example, the command
```bash
make doc.test TEST=tasks/traffic-management
```
will run all the tests under `content/en/docs/tasks/traffic-management`. The `TEST` variable also accepts multiple test names separated by commas, for example,
```bash
make doc.test TEST=tasks/traffic-management/request-routing,tasks/traffic-management/fault-injection
```

`TIMEOUT` specifies a time limit exceeding which all tests will halt, and the default value is 30 minutes (`30m`). `ENV` specifies the test environment (either `native` or `kube`), and is `kube` by default.

You can also find this information by running `make doc.test.help`. The bash tracing output for debugging will be kept in `out/*_[test|cleanup]_debug.txt`.

### Notes

1. In the case of using `kind` clusters on a Mac,
   an extra env var is needed (ADDITIONAL_CONTAINER_OPTIONS="--network host").
   Use the following command:

   ```bash
   TEST_ENV=kind ADDITIONAL_CONTAINER_OPTIONS="--network host" make doc.test
   ```

1. If HUB and TAG aren't set, then their default values will match what is used by the prow tests.
