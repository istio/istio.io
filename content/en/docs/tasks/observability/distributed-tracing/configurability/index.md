---
title: Configurability (Experimental)
description: How to configure tracing options (experimental).
weight: 60
keywords: [telemetry,tracing]
---

Istio provides advanced capability to configure tracing options as of Istio 1.6.
Previously, the only customization for sampling. All of these are considered experimental.

## Create a MeshConfig with tracing settings

All the settings talked in this document are configured with MeshConfig at installation time.
To simplify configuration, we recommend you create a single yaml file to pass to `istioctl`.

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

For any configuration option you wish to add you will append this to the `tracing.yaml` file.

## Trace sampling

Istio captures a trace for all requests by default when installing with the demo profile.
For example, when using the Bookinfo sample application above, every time you access
`/productpage` you see a corresponding trace in the
dashboard. This sampling rate is suitable for a test or low traffic
mesh. For a high traffic mesh you can lower the trace sampling
percentage in one of two ways:

{{ warning }}
Previously, we recommended that during the mesh setup the user should change the `values.pilot.traceSampling`
setting, or the user should modify the `PILOT_TRACE_SAMPLE` environment variable in their pilot or istiod deployment.
While that method of altering the sampling continues to work, we strongly recommend that you do the method
suggested in this document.

In the event that both are specified, the value specified in the MeshConfig will override any other setting.
{{ /warning }}

To modify the default random sampling, which is defaulted to a value of 1, you must add the following to your
`tracing.yaml file`.

{{< text yaml >}}
        sampling: <VALUE>
EOF
{{< /text >}}

Where the `<VALUE>` should be in the range of 0.0 to 100.0 with a precision of 0.01.

## Customizing tracing tags

{{ warning }}
The ability to add tracing tags to spans only works for sidecar proxies and does not work
for gateways.
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
          tag_env:
            environment:                 # user-defined name
              name: <ENV_VARIABLE_NAME>
              defaultValue: <VALUE>      # optional
{{< /text >}}

{{ warning }}
In order to add custom tags based on environmental variables you will have
to modify the `istio-sidecar-injector` ConfigMap in your root istio system namespace.
{{ /warning }}

Client request headers:
{{< text yaml >}}
          tag_header:                    # user-defined name
            header:
              name: <CLIENT-HEADER>
              defaultValue: <VALUE>      # optional
{{< /text >}}

## Customizing tracing tag length

By default, the maximum length the request path included as part of the HttpUrl span tag is 256.

To modify this, add the following to your `tracing.yaml file`.
{{< text yaml >}}
        max_path_tag_length: <VALUE>
{{< /text >}}
