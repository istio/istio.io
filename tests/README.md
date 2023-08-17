# Testing istio.io Content

This folder contains framework utilies and instructions for testing the content on
[istio.io](https://istio.io). More specifically, these tests confirm that the example, task, and
other documents, which contain instructions in the form of bash commands and expected output,
are working as documented.

Generated bash scripts, containing the set of commands and expected output for corresponding
istio.io markdown files, are used by test programs to invoke the commands and verify the output.
This means that we extract and test the exact same commands that are published in the documents.

These tests use the framework defined in the `istioio` package, which is a thin wrapper
around the [Istio test framework](https://github.com/istio/istio/wiki/Istio-Test-Framework).

Run the following command to see the current test coverage, including the list of tested documents
and those that are in need of a test:

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

   > You can also entirely supress generation of a snip function by setting `snip_id=none`. This is useful for
   > commands that are not intended to be directly executable (e.g., `kubectl get pod <your pod name>`) and are
   > causing lint errors (see next step, below).

   If a bash code block contains both commands and output, the `snips.sh` script will include
   both a bash function and a variable containing the expected output. The name of the variable
   will be the same as the function, only with `_out` appended.

1. Run `make lint-fast` to check for script errors.

   If there are any lint errors in the generated `snips.sh` file,
   it means that a command in the `index.md` file is not following `bash` best practices.
   Because we are extracting the commands from the markdown file into a script file, we get the
   added benefit of lint checking of the commands that appear in the docs.

   Fix the errors, if any, by updating the corresponding command (or set `snip_id=none`) in the `index.md`
   file and then regenerate the snips.

1. Create a test bash script named `test.sh` next to the `snips.sh` you have just generated.

   If your document is very large and you want to break it into multiple tests, create multiple scripts with
   the suffix `test.sh` (e.g., `part1_test.sh`, `part2_test.sh`), instead.

   Other scripts in the directory will be ignored.

## Test Bash Script

Your bash script will consist of a series of test steps that call the commands in your
generated `snips.sh` file.

Your script can invoke the commands by simply calling snip functions:

```sh
snip_config_50_v3 # Step 3: switch 50% traffic to v3
```

For commands that produce output, pass the snip and expected output to an appropriate
`_verify_` function. For example:

```sh
_verify_same snip_set_up_the_cluster_3 "$snip_set_up_the_cluster_3_out"
```

This will run the function `snip_set_up_the_cluster_3` and confirm that the output is exactly
the same as specified in the variable `snip_set_up_the_cluster_3_out`.

Snip functions often update Istio configuration (e.g., virtual services, destination rules, etc.).
Use the `_wait_for_istio` function to allow the change to propogate to the Istio sidecars
before proceeding with the next step of the test:

```sh
snip_config_50_v3 # Step 3: switch 50% traffic to v3
_wait_for_istio virtualservice default reviews # wait for routing change to propagate
```

For snips that deploy Kubernetes services (e.g., `kubectl apply -f samples/httpbin/httpbin.yaml`),
use the `_wait_for_deployment` function to wait for the deployment to roll out:

```sh
_wait_for_deployment default httpbin
```

You can also use this function to wait for installation changes resulting from `istioctl install` commands:

```sh
_wait_for_deployment istio-system istiod
```

### Test Setup and Cleanup

Before the test steps, there must be one line that specifies the istio setup configuration for the test:

```sh
# @setup <setup_config>
```

Currently supported setup configurations include: `profile=default` to install the default profile,
`profile=demo` to install the demo profile, and `profile=none` to not install istio at all.

Choose the setup configuration that best matches the document prerequisites. For example, if the
document being tested includes snips with explicit install commands (e.g., setup docs), use:

```sh
# @setup profile=none
```

This will start the test using a clean Kubernetes cluster without Istio installed.

If, on the other hand, the doc's `Before you begin` section refers the user to the standard
Istio installation instructions, chose the profile specified in the doc or `default` if there is
no specific profile mentioned in the instructions.

After all test steps are complete, add the following line to indicate the start of the cleanup steps:

```sh
# @cleanup
```
All steps after this line will be run by the framework, even if the test fails and prematurely exits.
The cleanup steps must remove all resources and reverse configuration changes made during the test steps.

Many documents have cleanup instuctions in them, so simply calling the cleanup snip functions will usually
reverse all changes made during the test steps. However, extra care should be taken to ensure that the
cleanup steps are complete so that after running them, the cluster will be left in the exact same state
that it started in. This is important because the test framework runs all tests that specify the
same `# @setup` using the same Kubernetes cluster, so any remaining config changes after the cleanup
steps are run, will potentially break a following test.

> The framework compares the before and after cluster state and will fail tests that it
> detects are not properly cleaning up. This comparison, however, is currently not a complete
> verification, so tests that pass this check may still not be cleaning up completely.

### Include Files

The framework automatically includes several bash scripts into your `test.sh` file, so you
don't have to `source` them yourself. This includes your generated `snips.sh` file as well
as some scripts containing framework utility functions:

* [tests/util/verify.sh](./util/verify.sh)
* [tests/util/helpers.sh](./util/helpers.sh)

You can directly call any function defined in them.

Other optional include files need to be explicitly sourced.
For example, tests that use the standard Istio sample services, will typically want to leverage
some of the functions in [tests/util/samples.sh](./util/samples.sh):

```sh
source "tests/util/samples.sh"

startup_bookinfo_sample  # from tests/util/samples.sh
snip_config_50_v3        # from ./snips.sh
```

### Verify Functions

The verify functions first run the snip function and then compare the result to the
expected output. The framework includes the following built-in verify functions:

1. **`_verify_same`** `func` `expected`

   Runs `func` and compares the output with `expected`. If they are not the same,
   wait a second and try again, up to two minutes by default. The retry behavior
   can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
   variables. You can also specify the expected number of consecutive successes
   by setting the `VERIFY_CONSECUTIVE` environment variable.

1. **`_verify_contains`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output does not
   contain the substring `expected`,
   wait a second and try again, up to two minutes by default. The retry behavior
   can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
   variables. You can also specify the expected number of consecutive successes
   by setting the `VERIFY_CONSECUTIVE` environment variable.

1. **`_verify_not_contains`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the command execution fails
   or the output contains the substring `expected`,
   wait a second and try again, up to two minutes by default. The retry behavior
   can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
   variables. You can also specify the expected number of consecutive successes
   by setting the `VERIFY_CONSECUTIVE` environment variable.

1. **`_verify_elided`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output does not
   contain the lines in `expected` where "..." on a line matches one or more lines
   containing any text,
   wait a second and try again, up to two minutes by default. The retry behavior
   can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
   variables. You can also specify the expected number of consecutive successes
   by setting the `VERIFY_CONSECUTIVE` environment variable.

1. **`_verify_regex`** `func` `expected`

   Runs `func` and compares the output with the regex string `expected`. If the output
   does not match with the regex string `expected`,
   wait a second and try again, up to two minutes by default. The retry behavior
   can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
   variables. You can also specify the expected number of consecutive successes
   by setting the `VERIFY_CONSECUTIVE` environment variable.

1. **`_verify_like`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output is not
   "like" `expected`,
   wait a second and try again, up to two minutes by default. The retry behavior
   can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
   variables. You can also specify the expected number of consecutive successes
   by setting the `VERIFY_CONSECUTIVE` environment variable.

   Like implies:

   - Same number of lines
   - Same number of whitespace-seperated tokens per line
   - Tokens can only differ in the following ways:

     1. different elapsed time values (e.g., `30s` is like `5m`)
     1. different ip values (e.g., `172.21.0.1` is like `10.0.0.31`). Disallows
         `<none>` and `<pending>` by default. This can be customized by setting
         the `CMP_MATCH_IP_NONE` and `CMP_MATCH_IP_PENDING` environment variables,
         respectively.
     1. prefix match ending with a dash character (e.g., `reviews-v1-12345...` is like `reviews-v1-67890...`)
     1. expected `...` is a wildcard token, matches anything

   This function is useful for comparing the output of commands that include some run-specific
   values in the output (e.g., `kubectl get pods`), or when whitespace in the output may be different.

1. **`_verify_lines`** `func` `expected`

   Runs `func` and compares the output with `expected`. If the output does not
   "conform to" the specification in `expected`,
   wait a second and try again, up to two minutes by default. The retry behavior
   can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
   variables. You can also specify the expected number of consecutive successes
   by setting the `VERIFY_CONSECUTIVE` environment variable.

   Conformance implies:

   1. For each line in `expected` with the prefix "+ " there must be at least one
      line in the output containing the following string.
   1. For each line in `expected` with the prefix "- " there must be no line in
      the output containing the following string.

1. **`_verify_failure`** `func`

   Runs `func` and confirms that it fails (i.e., non-zero return code). This function is useful
   for testing commands that demonstrate configurations that are expected to fail.

## Running the Tests

The following command will run all the doc tests within a `kube` environment:

```bash
make doc.test
```

The `make doc.test` target can be passed two optional environment variables: `TEST` and `TIMEOUT`.

`TEST` specifies a directory relative to `content/en/docs/` containing the tests to run.
For example, the following command will only run the tests under `content/en/docs/tasks/traffic-management`:

```bash
make doc.test TEST=tasks/traffic-management
```

You can also run one or more individual test by listing the full test names separated by commas. For example:

```bash
make doc.test TEST=tasks/traffic-management/request-routing,tasks/traffic-management/fault-injection
```

`TIMEOUT` specifies a time limit exceeding which all tests will halt, and the default value is 30 minutes (`30m`).

You can also find this information by running `make doc.test.help`.

### Notes

1. The [tests/util/debug.sh](./util/debug.sh) script is automatically included in every `test.sh` script
   to enable bash tracing. The bash tracing output can be found in `out/<test_path>_[test|cleanup]_debug.txt`.

1. When using `kind` clusters, you may notice a `Exiting due to setup failure: failed waiting for istio-eastwestgateway to become ready: timeout while waiting`
error as the Istio control plane is being started. Adding a config when creating your `kind` cluster should fix the issue:

   ```sh
   kind create cluster --name istio-test --config prow/config/default.yaml
   ```

1. When using `kind` clusters on a Mac, an extra env var is needed (ADDITIONAL_CONTAINER_OPTIONS="--network host").
   Use the following command:

   ```sh
   TEST_ENV=kind ADDITIONAL_CONTAINER_OPTIONS="--network host" make doc.test
   ```

   If you encounter `couldn't get current server API group list: Get "...": dial tcp ... connect: connection refused`, the option above also works.

1. Set the HUB and TAG environment variables to use a particular Istio build when running tests.
   If unset, their default values will match those used by the prow tests.

1. For help debugging, you can enable script output to the `stdout` with the command-line flag
   `--log_output_level=script:debug`. This is useful when you're running in an IDE and don't
   want to find and tail the test output files.
