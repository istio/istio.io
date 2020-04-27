# Testing istio.io Content

This folder contains tests for the content on [istio.io](http://istio.io).
More specifically, these tests confirm that the example and task documents, which contain
instructions in the form of bash commands and expected output, are working as documented.

Generated bash scripts, containing the set of commands and expected output for corresponding
istio.io markdown files, are used by test programs to invoke the commands and verify the output.
This means that we extract and test the exact same commands that are published in the documents.

These tests use the framework defined in the `istioio` package, which is a thin wrapper
around the [Istio test framework](https://github.com/istio/istio/wiki/Istio-Test-Framework).

## Test Authoring Overview

To write an `istio.io` test, follow these steps:

1. Add a field `test: true` to the metadata at the top of the `index.md` file to be tested.
   This field is used to indicate that the markdown file will be tested and therefore requires
   a generated bash script containing the commands described in the document.

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

1. Pick an appropriate location under the `tests/` directory and create a directory for your new
   test.

1. Add the following imports to your GoLang file:

    ```golang
    "istio.io/istio/pkg/test/framework"
    "istio.io/istio/pkg/test/framework/components/environment"
    "istio.io/istio/pkg/test/framework/components/istio"

    "istio.io/istio.io/pkg/test/istioio"
    ```

1. Create a function called `TestMain`, following the example below. This
   function sets up the Istio environment that the test uses. The `Setup`
   function accepts an optional function to customize the Istio environment
   deployed.

    ```golang
    func TestMain(m *testing.M) {
    framework.NewSuite("my-istioio-test", m).
        SetupOnEnv(environment.Kube, istio.Setup(&ist, nil)).
        RequireEnvironment(environment.Kube).
        Run()
    }
    ```

1. To create a test, you use `istioio.NewBuilder` to build a series of steps that will
   be run as part of the resulting test function:

    ```golang
    func TestCombinedMethods(t *testing.T) {
        framework.
            NewTest(t).
            Run(istioio.NewBuilder("tasks__security__my_task").
                Add(istioio.Script{
                    Input:         istioio.Path("myscript.sh"),
                },
                istioio.MultiPodWait("foo"),
                istioio.Script{
                    Input:         istioio.Path("myotherscript.sh"),
                }).Build())
    }
    ```

## Running Shell Commands

Your test will include one or more test steps that run shell scripts that call
the commands in the generated `snips.sh` file.

```golang
istioio.Script{
    Input:   istioio.Path("myscript.sh"),
}
```

Your script must include the `snip.sh` file for the document being tested. For example,
a test for the traffic-shifting task will have the following line in the script:

```sh
source ${REPO_ROOT}/content/en/docs/tasks/traffic-management/traffic-shifting/snips.sh
```

Your test script can then invoke the commands by simply calling snip functions:

```sh
snip_config_50_v3 # Step 3: switch 50% traffic to v3
```

For commands that produce output that needs to be verified, capture the command output
in a variable and compare it to the expected output. For example:

```sh
out=$(snip_set_up_the_cluster_3 2>&1)
_verify_same "$out" "$snip_set_up_the_cluster_3_out" "snip_set_up_the_cluster_3"
```

The framework includes the following built-in verify functions:

1. **`_verify_same`** `out` `expected` `msg`

   Verify that `out` is exactly the same as `expected`. Failure messages will include
   the specified `msg`.

1. **`_verify_contains`** `out` `expected` `msg`

   Verify that `out` contains the substring `expected`. Failure messages will include
   the specified `msg`.

1. **`_verify_like`** `out` `expected` `msg`

   Verify that `out` is "like" `expected`. Like implies:

   - Same number of lines
   - Same number of whitespace-seperated tokens per line
   - Tokens can only differ in the following ways:

     1. different elapsed time values (e.g., `30s` is like `5m`)
     1. different ip values (e.g., `172.21.0.1` is like `10.0.0.31`)
     1. prefix match ending with a dash character (e.g., `reviews-v1-12345...` is like `reviews-v1-67890...`)

   This function is useful for comparing the output of commands that include some run-specific
   values in the output (e.g., `kubectl get pods`), or when whitespace in the output may be different.

## Builder

The `istioio.NewBuilder` returns a `istioio.Builder` that is used to build an Istio
test run function and has the following methods:

- `Add`: adds a step to the test.
- `Defer`: provides a step to be run after the test completes.
- `Build`: builds an Istio test run function.

## Selecting Input

Many test steps require an `Input` which they obtain from an
`istioio.InputSelector`:

```golang
type Input interface {
    InputSelector
    Name() string
    ReadAll() (string, error)
}

type InputSelector interface {
    SelectInput(Context) Input
}
```

Some common `InputSelector` implementations include:

- `istioio.Inline`: allows you to inline the content for the `Input` directly in the code.
- `istioio.Path`: reads in a file from the specified path.
- `istioio.BookInfo`: is like `istioio.Path` except that the value is assumed to be
relative to the BookInfo source directory (`$GOPATH/src/istio.io/istio/samples/bookinfo/platform/kube/`).

An `InputSelector` provides an `istioio.Context` at runtime, which it can use to
dynamically choose an `Input`. For example, we could choose a different file depending on
whether or not the test is running on Minikube:

```golang
istioio.InputSelectorFunc(func(ctx istioio.Context) Input {
    if ctx.Env.Settings().Minikube {
        return istioio.Path("scripts/curl-httpbin-tls-gateway-minikube.sh")
    }
    return istioio.Path("scripts/curl-httpbin-tls-gateway-gke.sh")
})
```

The library also provides a utility that helps simplify this particular use case:

```golang
istioio.IfMinikube{
    Then: istioio.Path("scripts/curl-httpbin-tls-gateway-minikube.sh")
    Else: istioio.Path("scripts/curl-httpbin-tls-gateway-gke.sh")
}
```

## Waiting for Pods to Start

You can create a test step that waits for one or more pods to start before continuing.
For example, to wait for all pods in the "foo"  namespace, you can do the following:

```golang
istioio.MultiPodWait("foo"),
```

## Running the Tests: Make

You can execute all istio.io tests using make.

```bash
export KUBECONFIG=~/.kube/config
make test.kube.presubmit
```

### Notes:

There is an issue with the TAG (#7081) so one needs to set TAG to `latest` to mimic the
pipeline.

In the case of using `kind` clusters on the Mac, an extra env var is needed,
ADDITIONAL_CONTAINER_OPTIONS="--network host". If one makes sure HUB is not set, then the
command `TEST_ENV=kind ADDITIONAL_CONTAINER_OPTIONS="--network host" make test.kube.presubmit`
has been successful.

## Running Tests: go test

You can execute individual tests using Go test as shown below.

```bash
make init
export REPO_ROOT=$(git rev-parse --show-toplevel)
go test ./tests/... -p 1  --istio.test.env kube \
    --istio.test.ci --istio.test.work_dir <my_dir>
```

The value of `my_dir` will be the parent directory for your test output. Within
`my_dir`, each test `Main` will create a directory containing a subdirectory for
each test method. Each test method directory will contain a `snippet.txt` that
was generated for that particular test.

Make sure to have the `HUB` and `TAG` [environment variables set](https://github.com/istio/istio/wiki/Preparing-for-Development#setting-up-environment-variables) to the location of
your Istio Docker images.

You can find the complete list of arguments on [the test framework wiki page](https://github.com/istio/istio/wiki/Istio-Test-Framework).
