---
title: Configurability (Experimental)
description: How to configure tracing options (experimental).
weight: 60
keywords: [telemetry,tracing]
---

Istio provides advanced capability to configure tracing options as of Istio 1.6.
The following tracing configurations are considered experimental.

## Create a MeshConfig with trace settings

Configuration options discussed in this document need to be configured at installation.
We recommend you create a single yaml file to pass to `istioctl` to simplify installation.

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

## Trace sampling

Istio captures a trace for all requests by default when installing with the demo profile.
For example, when using the Bookinfo sample application, every time you access
`/productpage` you see a corresponding trace in the
dashboard. This sampling rate is suitable for a test or low traffic
mesh. For a high traffic mesh you can lower the trace sampling
percentage in one of two ways:

{{ warning }}
Previously, the recommended method was to change the `values.pilot.traceSampling` setting during the mesh setup
 or to change the `PILOT_TRACE_SAMPLE` environment variable in the pilot or istiod deployment.
While this method to alter sampling continues to work, the following method
is strongly recommended instead.

In the event that both are specified, the value specified in the `MeshConfig` will override any other setting.
{{ /warning }}

To modify the default random sampling, which is defaulted to a value of 1, add the following to your
`tracing.yaml file`.

{{< text yaml >}}
        sampling: <VALUE>
{{< /text >}}

Where the `<VALUE>` should be in the range of 0.0 to 100.0 with a precision of 0.01.

## Customizing tracing tags

{{ warning }}
The ability to add tracing tags to spans works for sidecar proxies and gateways.
If you are concerned about rogue external client requests we do not recommend you
utilize this feature.
{{ /warning }}

The ability to add tracing tags to spans has been implemented.

Tags can be added to spans based on literals, environmental variables and
client request headers.

{{ warning }}
There is no limit to the amount of custom tags that you can add. However, the only caveat their names be unique.
{{ /warning }}

To add custom tags to your spans you must add the following yaml to your `tracing.yaml file`.

Literals:

{{< text yaml >}}
        custom_tags:
          tag_literal:                   # user-defined name
            literal:
              value: <VALUE>
{{< /text >}}

Environmental variables:

{{< text yaml >}}
        custom_tags:
          tag_env:
            environment:                 # user-defined name
              name: <ENV_VARIABLE_NAME>
              defaultValue: <VALUE>      # optional
{{< /text >}}

{{ warning }}
In order to add custom tags based on environmental variables, you must
to modify the `istio-sidecar-injector` ConfigMap in your root Istio system namespace.
{{ /warning }}

Client request headers:

{{< text yaml >}}
        custom_tags:
          tag_header:                    # user-defined name
            header:
              name: <CLIENT-HEADER>
              defaultValue: <VALUE>      # optional
{{< /text >}}

## Customizing tracing tag length

By default, the maximum length the request path included as part of the `HttpUrl` span tag is 256.

To modify this maximum length, add the following to your `tracing.yaml` file.

{{< text yaml >}}
        max_path_tag_length: <VALUE>
{{< /text >}}
