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

1. Pick an appropriate location under the `tests/` directory for your new test.

1. Create Go boilderplate that will invoke your test bash script using the following pattern:

    ```golang
    package <your-test-package>

    import (
        "testing"

        "istio.io/istio/pkg/test/framework"

        "istio.io/istio.io/pkg/test/istioio"
    )

    func Test<your-test>(t *testing.T) {
        framework.
            NewTest(t).
            Run(istioio.NewBuilder("<your-test-name>").
                Add(istioio.Script{
                    Input: istioio.Path("scripts/<your-bash-script>.sh"),
                }).
                Defer(istioio.Script{
                    Input: istioio.Inline{
                        FileName: "cleanup.sh",
                        Value: `
    set +e # ignore cleanup errors
    source ${REPO_ROOT}/content/en/docs/<your-snips-dir>/snips.sh
    <your cleanup steps>`,
                    },
                }).
                Build())
    }
    ```

    NOTE: This Go boilerplate is a temporary requirement. It will not be needed in the future.
    See https://docs.google.com/document/d/1r_NoxatNjzPsw0eXr6_9W0rqlkfelt7QfN2y5TF0yTo/edit#.

1. Create your test bash script in the `scripts/` subdirectory.

## Test Bash Script

With the exception of the cleanup steps, your test will consist of a single
shell scripts that calls the commands in your generated `snips.sh` file.

Your script must include the `snip.sh` file for the document being tested. For example,
a test for the traffic-shifting task will have the following line in the script:

```sh
source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/traffic-shifting/snips.sh"
```

Your test script can then invoke the commands by simply calling snip functions:

```sh
snip_config_50_v3 # Step 3: switch 50% traffic to v3
```

For commands that produce output, pass the snip and expected output to an appropriate
`_run_and_verify_` function. For example:

```sh
_run_and_verify_same snip_set_up_the_cluster_3 "$snip_set_up_the_cluster_3_out"
```

For situations where you need to perform more than one verify check, you can
run the snip and capture the command output in a variable, and then compare
it to the expected output:

```sh
out=$(snip_tripping_the_circuit_breaker_1 2>&1)
_verify_contains "$out" "Code 200 :" "snip_tripping_the_circuit_breaker_1"
_verify_contains "$out" "Code 503 :" "snip_tripping_the_circuit_breaker_1"
```

The framework includes the following built-in verify functions:

1. **`_verify_same`** `out` `expected` `msg`

   Verify that `out` is exactly the same as `expected`. Failure messages will include
   the specified `msg`.

1. **`_verify_contains`** `out` `expected` `msg`

   Verify that `out` contains the substring `expected`. Failure messages will include
   the specified `msg`.

1. **`_verify_not_contains`** `out` `expected` `msg`

   Verify that `out` does not contains the substring `expected`. Failure messages will include
   the specified `msg`.

1. **`_verify_first_line`** `out` `expected` `msg`

   Verify that the first line of `out` matches the first line in `expected`.

1. **`_verify_elided`** `out` `expected` `msg`

   Verify that `out` contains the lines in `expected` where `...` on a line matches one or
   more lines with any text.

1. **`_verify_like`** `out` `expected` `msg`

   Verify that `out` is "like" `expected`. Like implies:

   - Same number of lines
   - Same number of whitespace-seperated tokens per line
   - Tokens can only differ in the following ways:

     1. different elapsed time values (e.g., `30s` is like `5m`)
     1. different ip values (e.g., `172.21.0.1` is like `10.0.0.31`)
     1. prefix match ending with a dash character (e.g., `reviews-v1-12345...` is like `reviews-v1-67890...`)
     1. expected `...` is a wildcard token, matches anything

   This function is useful for comparing the output of commands that include some run-specific
   values in the output (e.g., `kubectl get pods`), or when whitespace in the output may be different.

Every `verify_` function has a corresponding `_run_and_verify_` function that
first runs a function and then compares the result to the expected output.
The specified function will be retried 5 times, with exponential backoff, before failing:

1. **`_run_and_verify_same`** `func` `expected`
1. **`_run_and_verify_contains`** `func` `expected`
1. **`_run_and_verify_not_contains`** `func` `expected`
1. **`_run_and_verify_first_line`** `func` `expected`
1. **`_run_and_verify_elided`** `func` `expected`
1. **`_run_and_verify_like`** `func` `expected`

## Running the Tests: Make

You can execute all istio.io tests using make.

```bash
make test.kube.presubmit
```

Alternatively, you can run the tests in a particular package under `tests/`.
For example, the following command will only run the traffic management tests:

```bash
make test.kube.trafficmanagement
```

### Notes:

1. In the case of using `kind` clusters on a Mac,
   an extra env var is needed (ADDITIONAL_CONTAINER_OPTIONS="--network host").
   Use the following command:

   ```bash
   TEST_ENV=kind ADDITIONAL_CONTAINER_OPTIONS="--network host" make test.kube.presubmit
   ```

1. If HUB and TAG aren't set, then their default values will match what is used by the prow tests.

## Running Tests: go test

You can execute individual tests using Go test as shown below.

```bash
make init
export REPO_ROOT=$(git rev-parse --show-toplevel)
go test ./tests/... -p 1  --istio.test.env kube \
    --istio.test.ci --istio.test.work_dir <my_dir>
```

Make sure to have the `HUB` and `TAG` [environment variables set](https://github.com/istio/istio/wiki/Preparing-for-Development#setting-up-environment-variables) to the location of
your Istio Docker images.
