---
title: 라이트스텝
description: 라이트스텝으로 추적 요청을 보내도록 프록시를 구성하는 방법.
weight: 11
keywords: [telemetry,tracing,lightstep]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

This task shows you how to configure Istio to collect trace spans and send them to [Lightstep](https://lightstep.com).
Lightstep lets you analyze 100% of unsampled transaction data from large-scale production software to produce meaningful
distributed traces and metrics that help explain performance behaviors and accelerate root cause analysis.
At the end of this task, Istio sends trace spans from the proxies to a Lightstep Satellite pool making them
available to the web UI.

This task uses the [Bookinfo](/ko/docs/examples/bookinfo/) sample application as an example.

## Before you begin

1.  Ensure you have a Lightstep account. [Sign up](https://go.lightstep.com/trial) for a free trial of Lightstep.

1.  If you're using [on-premise Satellites](https://docs.lightstep.com/ko/docs/learn-about-satellites#on-premise-satellites), ensure you have a satellite pool configured with TLS certs and a secure GRPC port exposed. See
    [Install and Configure Satellites](https://docs.lightstep.com/ko/docs/install-and-configure-satellites) for details about setting up satellites.

    For [Lightstep Public Satellites](https://docs.lightstep.com/ko/docs/learn-about-satellites#public-satellites) or [Developer Satellites](https://docs.lightstep.com/ko/docs/learn-about-satellites#developer-satellites), your satellites are already configured.

1.  Ensure sure you have a Lightstep [access token](https://docs.lightstep.com/ko/docs/create-and-manage-access-tokens). Access tokens allow your app to communicate with your Lightstep project.

1.  You'll need to deploy Istio with your satellite address.
    For on-premise Satellites, ensure you can reach the satellite pool at an address in the format `<Host>:<Port>`, for example `lightstep-satellite.lightstep:9292`.

    For for Public or Developer Satellites, use the address `collector-grpc.lightstep.com:443`.

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
    $ istioctl install \
        --set values.pilot.traceSampling=100 \
        --set values.global.proxy.tracer="lightstep" \
        --set values.global.tracer.lightstep.address="<satellite-address>" \
        --set values.global.tracer.lightstep.accessToken="<access-token>" \
        --set values.global.tracer.lightstep.secure=true \
        --set values.global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"
    {{< /text >}}

1.  Store your satellite pool's certificate authority certificate as a secret in the default namespace.
    For Lightstep Public and Developer Satellites, download and use [this certificate](https://docs.lightstep.com/ko/docs/instrument-with-istio-as-your-service-mesh#cacertpem-file).
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

1.   Follow the [instructions to deploy the Bookinfo sample application](/ko/docs/examples/bookinfo/#deploying-the-application).

## Visualize trace data

1.  Follow the [instructions to create an ingress gateway for the Bookinfo application](/ko/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

1.  To verify the previous step's success, confirm that you set `GATEWAY_URL` environment variable in your shell.

1.  Send traffic to the sample application.

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Load the Lightstep [web UI](https://app.lightstep.com/). You'll see the three Bookinfo services listed in the Service Directory.

    {{< image link="./istio-services.png" caption="Bookfinder services in the Service Directory" >}}

1.  Navigate to the Explorer view.

    {{< image link="./istio-explorer.png" caption="Explorer view" >}}

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
The Lightstep integration does not currently capture spans generated by Istio's internal operation components such as Mixer.
{{< /warning >}}

## Trace sampling

Istio captures traces at a configurable trace sampling percentage. To learn how to modify the trace sampling percentage,
visit the [Distributed Tracing trace sampling section](../configurability/#trace-sampling).

When using Lightstep, we do not recommend reducing the trace sampling percentage below 100%. To handle a high traffic mesh,
consider scaling up the size of your satellite pool.

## Cleanup

If you are not planning any follow-up tasks, remove the Bookinfo sample application and any Lightstep secrets
from your cluster.

1. To remove the Bookinfo application, refer to the [Bookinfo cleanup](/ko/docs/examples/bookinfo/#cleanup) instructions.

1. Remove the secret generated for Lightstep:

{{< text bash >}}
$ kubectl delete secret lightstep.cacert
{{< /text >}}
