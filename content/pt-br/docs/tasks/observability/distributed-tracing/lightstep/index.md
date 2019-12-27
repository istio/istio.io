---
title: LightStep
description: How to configure the proxies to send tracing requests to LightStep.
weight: 11
keywords: [telemetry,tracing,lightstep]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/lightstep/
---

This task shows you how to configure Istio to collect trace spans and send them to [LightStep Tracing](https://lightstep.com/products/) or [LightStep [𝑥]PM](https://lightstep.com/products/).
LightStep lets you analyze 100% of unsampled transaction data from large-scale production software to produce meaningful
distributed traces and metrics that help explain performance behaviors and accelerate root cause analysis.
At the end of this task, Istio sends trace spans from the proxies to a LightStep Satellite pool making them
available to the web UI.

This task uses the [Bookinfo](/pt-br/docs/examples/bookinfo/) sample application as an example.

## Before you begin

1.  Ensure you have a LightStep account. [Sign up](https://lightstep.com/products/tracing/) for a free trial of LightStep Tracing, or [Contact LightStep](https://lightstep.com/contact/) to create an enterprise-level LightStep [𝑥]PM account.

1.  For [𝑥]PM users, ensure you have a satellite pool configured with TLS certs and a secure GRPC port exposed. See
    [LightStep Satellite Setup](https://docs.lightstep.com/docs/satellite-setup) for details about setting up satellites.

    For LightStep Tracing users, your satellites are already configured.

1.  Ensure sure you have a LightStep [access token](https://docs.lightstep.com/docs/project-access-tokens).

1.  You'll need to deploy Istio with your satellite address.
    For [𝑥]PM users, ensure you can reach the satellite pool at an address in the format `<Host>:<Port>`, for example `lightstep-satellite.lightstep:9292`.

    For LightStep Tracing users, use the address `collector-grpc.lightstep.com:443`.

1.  Deploy Istio with the following configuration parameters specified:
    - `pilot.traceSampling=100`
    - `global.proxy.tracer="lightstep"`
    - `global.tracer.lightstep.address="<satellite-address>"`
    - `global.tracer.lightstep.accessToken="<access-token>"`
    - `global.tracer.lightstep.secure=true`
    - `global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"`

    You can set these parameters using the `--set key=value` syntax
    when you run the install command. For example:

    {{< text bash >}}
    $ istioctl manifest apply \
        --set values.pilot.traceSampling=100 \
        --set values.global.proxy.tracer="lightstep" \
        --set values.global.tracer.lightstep.address="<satellite-address>" \
        --set values.global.tracer.lightstep.accessToken="<access-token>" \
        --set values.global.tracer.lightstep.secure=true \
        --set values.global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"
    {{< /text >}}

1.  Store your satellite pool's certificate authority certificate as a secret in the default namespace.
    For LightStep Tracing users, download and use [this certificate](https://docs.lightstep.com/docs/use-istio-as-your-service-mesh-with-lightstep).
    If you deploy the Bookinfo application in a different namespace, create the secret in that namespace instead.

    {{< text bash >}}
    $ CACERT=$(cat Cert_Auth.crt | base64) # Cert_Auth.crt contains the necessary CACert
    $ NAMESPACE=default
    {{< /text >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Secret
      metadata:
        name: lightstep.cacert
        namespace: $NAMESPACE
        labels:
          app: lightstep
      type: Opaque
      data:
        cacert.pem: $CACERT
    EOF
    {{< /text >}}

1.   Follow the [instructions to deploy the Bookinfo sample application](/pt-br/docs/examples/bookinfo/#deploying-the-application).

## Visualize trace data

1.  Follow the [instructions to create an ingress gateway for the Bookinfo application](/pt-br/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

1.  To verify the previous step's success, confirm that you set `GATEWAY_URL` environment variable in your shell.

1.  Send traffic to the sample application.

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Load the LightStep [web UI](https://app.lightstep.com/).

1.  Navigate to Explorer.

1.  Find the query bar at the top. The query bar allows you to interactively filter results by a **Service**, **Operation**, and **Tag** values.

1.  Select `productpage.default` from the **Service** drop-down list.

1.  Click **Run**. You see something similar to the following:

    {{< image link="./istio-tracing-list-lightstep.png" caption="Explorer" >}}

1.  Click on the first row in the table of example traces below the latency histogram to see the details
    corresponding to your refresh of the `/productpage`. The page then looks similar to:

    {{< image link="./istio-tracing-details-lightstep.png" caption="Detailed Trace View" >}}

The screenshot shows that the trace is comprised of a set of spans. Each span corresponds to a Bookinfo service invoked
during the execution of a `/productpage` request.

Two spans in the trace represent every RPC. For example, the call from `productpage` to `reviews` starts
with the span labeled with the `reviews.default.svc.cluster.local:9080/*` operation and the
`productpage.default: proxy client` service. This service represents the client-side span of the call. The screenshot shows
that the call took 15.30 ms. The second span is labeled with the `reviews.default.svc.cluster.local:9080/*` operation
and the `reviews.default: proxy server` service. The second span is a child of the first span and represents the
server-side span of the call. The screenshot shows that the call took 14.60 ms.

{{< warning >}}
The LightStep integration does not currently capture spans generated by Istio's internal operation components such as Mixer.
{{< /warning >}}

## Trace sampling

Istio captures traces at a configurable trace sampling percentage. To learn how to modify the trace sampling percentage,
visit the [Distributed Tracing trace sampling section](../overview/#trace-sampling).
When using LightStep, we do not recommend reducing the trace sampling percentage below 100%. To handle a high traffic mesh,
consider scaling up the size of your satellite pool.

## Cleanup

If you are not planning any follow-up tasks, remove the Bookinfo sample application and any LightStep secrets
from your cluster.

1. To remove the Bookinfo application, refer to the [Bookinfo cleanup](/pt-br/docs/examples/bookinfo/#cleanup) instructions.

1. Remove the secret generated for LightStep:

{{< text bash >}}
$ kubectl delete secret lightstep.cacert
{{< /text >}}
