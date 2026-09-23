---
title: Configure tracing with Telemetry API
description: How to configure tracing options using Telemetry API.
weight: 2
keywords: [telemetry,tracing]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio provides the ability to configure tracing options, such as sampling rate and adding custom tags to reported spans.
This task shows you how to customize the tracing options with Telemetry API.

## Before you begin

1.  Ensure that your applications propagate tracing headers as described [here](/docs/tasks/observability/distributed-tracing/overview/).

1.  Follow the tracing installation guide located under [Integrations](/docs/ops/integrations/)
    based on your preferred tracing backend to install the appropriate software and
    configure an extension provider.

## Installation

In this example, we will send traces to [Zipkin](/docs/ops/integrations/zipkin/). Install Zipkin before you continue.

### Configure an extension provider

Install Istio with an [extension provider](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) referring to the Zipkin service:

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # disable legacy MeshConfig tracing options
    extensionProviders:
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF
$ istioctl install -f ./tracing.yaml --skip-confirmation
{{< /text >}}

### Enable tracing

Enable tracing by applying the following configuration:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: "zipkin"
EOF
{{< /text >}}

### Verify the results

You can verify the results by [accessing the Zipkin UI](/docs/tasks/observability/distributed-tracing/zipkin/).

## Customization

### Customizing trace sampling

The sampling rate option can be used to control what percentage of requests get
reported to your tracing system. This should be configured based upon your
traffic in the mesh and the amount of tracing data you want to collect.
The default rate is 1%.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: "zipkin"
    randomSamplingPercentage: 100.00
EOF
{{< /text >}}

### Customizing tracing tags

Custom tags can be added to spans based on literals, environmental variables and
client request headers in order to provide additional information in spans
specific to your environment.

{{< warning >}}
There is no limit on the number of custom tags that you can add, but tag names must be unique.
{{< /warning >}}

You can customize the tags using any of the three supported options below.

1.  Literal represents a static value that gets added to each span.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
    name: mesh-default
    namespace: istio-system
    spec:
      tracing:
      - providers:
        - name: "zipkin"
        randomSamplingPercentage: 100.00
        customTags:
          "provider":
            literal:
              value: "zipkin"
    {{< /text >}}

1.  Environmental variables can be used where the value of the custom tag is
    populated from a workload proxy environment variable.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
          - name: "zipkin"
          randomSamplingPercentage: 100.00
          customTags:
            "cluster_id":
              environment:
                name: ISTIO_META_CLUSTER_ID
                defaultValue: Kubernetes # optional
    {{< /text >}}

    {{< warning >}}
    In order to add custom tags based on environmental variables, you must
    modify the `istio-sidecar-injector` ConfigMap in your root Istio system namespace.
    {{< /warning >}}

1.  Client request header option can be used to populate tag value from an
    incoming client request header.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
          - name: "zipkin"
          randomSamplingPercentage: 100.00
          customTags:
            my_tag_header:
              header:
                name: <CLIENT-HEADER>
                defaultValue: <VALUE>      # optional
    {{< /text >}}

### Customizing tracing tag length

By default, the maximum length for the request path included as part of the `HttpUrl` span tag is 256.
To modify this maximum length, add the following to your `tracing.yaml` file.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # disable legacy tracing options via `MeshConfig`
    extensionProviders:
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
        maxTagLength: <VALUE>
{{< /text >}}
