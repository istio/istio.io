---
title: Configurability (Beta/Development)
description: How to configure tracing options (beta/development).
weight: 60
keywords: [telemetry,tracing]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

Istio provides the ability to configure advanced tracing options,
including sampling rates and span tags. Sampling is a beta feature, but
custom tags and tracing tag length are considered in-development for this release.

## Create a `MeshConfig` with trace settings

All tracing options are configured by using `MeshConfig` during Istio *installation*.
To simplify configuration, create a single YAML file to pass to `istioctl`.

{{< text yaml >}}
cat <<'EOF' > tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      tracing:
EOF
{{< /text >}}

Then, you can append any configuration options to the `tracing.yaml` file.

## Add `proxy.istio.io/config` annotation to your Pod metadata specification

There are occasions where you may wish to override the mesh-wide configuration for a Pod-specific
setting. By adding the `proxy.istio.io/config` annotation to your Pod metadata
specification you can override any mesh-wide tracing settings.

For instance, to modify the `sleep` deployment shipped with Istio you would add the following
to `samples/sleep/sleep.yaml`:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  ...
  template:
    metadata:
      ...
      proxy.istio.io/config: |
        tracing:
          ...                            # custom tracing definition
    spec:
      ...
{{< /text >}}

You can then append any of the settings specified below, to change the tracing configuration
for this Pod specification.

## Trace sampling

Istio captures a trace for all requests by default when installing with the demo profile.
For example, when using the Bookinfo sample application, every time you access
`/productpage` you see a corresponding trace in the
[dashboard](../jaeger/). This sampling rate is suitable for a test or low traffic
mesh. For a high traffic mesh you can lower the trace sampling
percentage in one of two ways:

{{< warning >}}
Previously, the recommended method was to change the `values.pilot.traceSampling` setting during the mesh setup
or to change the `PILOT_TRACE_SAMPLE` environment variable in the pilot or istiod deployment.
While this method to alter sampling continues to work, the following method
is strongly recommended instead.

In the event that both are specified, the value specified in the `MeshConfig` will override any other setting.
{{< /warning >}}

To modify the default random sampling, which is defaulted to a value of 100 in the demo profile
and 1 for the default profile, add the following to your `tracing.yaml` file.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      tracing:
        sampling: <VALUE>
{{< /text >}}

Where the `<VALUE>` should be in the range of 0.0 to 100.0 with a precision of 0.01.
For example, to trace 5 requests out of every 10000, use 0.05 as the value here.

## Customizing tracing tags

The ability to add custom tracing tags to spans has also been implemented.

Tags can be added to spans based on literals, environmental variables and
client request headers.

{{< warning >}}
There is no limit on the number of custom tags that you can add, but tag names must be unique.
{{< /warning >}}

To add custom tags to your spans, add the following to your `tracing.yaml` file.

Literals:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      tracing:
        custom_tags:
          tag_literal:                   # user-defined name
            literal:
              value: <VALUE>
{{< /text >}}

Environmental variables:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      tracing:
        custom_tags:
          tag_env:                       # user-defined name
            environment:
              name: <ENV_VARIABLE_NAME>
              defaultValue: <VALUE>      # optional
{{< /text >}}

{{< warning >}}
In order to add custom tags based on environmental variables, you must
modify the `istio-sidecar-injector` ConfigMap in your root Istio system namespace.
{{< /warning >}}

Client request headers:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      tracing:
        custom_tags:
          tag_header:                    # user-defined name
            header:
              name: <CLIENT-HEADER>
              defaultValue: <VALUE>      # optional
{{< /text >}}

## Customizing tracing tag length

By default, the maximum length for the request path included as part of the `HttpUrl` span tag is 256.

To modify this maximum length, add the following to your `tracing.yaml` file.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      tracing:
        max_path_tag_length: <VALUE>
{{< /text >}}
