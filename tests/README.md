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

To verify the output, you currently have two choices:

1. Surround the call with `# $snippet` and `# $endsnippet` comments,
    including `# $verify` followed by the expected output:

    ```sh
    # $snippet
    snip_config_50_v3
    # $verify
    virtualservice.networking.istio.io/reviews configured
    # $endsnippet
    ```

    **Note**: There should be no other fields on the line following the `# $snippet` directive.
    The `# $snippet`, without a following name, will simply run and verify the commands
    in the snippet section, i.e., no output snippet will be generated.

    Refer to [verifier.go](../pkg/test/istioio/verifier.go) for supported verifiers.

1. Capture the command output and compare it to a variable containing the expected output:

    ```sh
    out=$(snip_set_up_the_cluster_3 2>&1)
    if [ "$out" != "$snip_set_up_the_cluster_3_out" ]; then
        echo "FAILED snip_set_up_the_cluster_3: $out"; exit 1
    fi
    ```

    TODO: Add built-in verifier functions that can be used instead of simple string compare.
    Once this is available, we can deprecate the `# $verify` approach.

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

## Running Tests: go test

You can execute individual tests using Go test as shown below.

```bash
make init
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
