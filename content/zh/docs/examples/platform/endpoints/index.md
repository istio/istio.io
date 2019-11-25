---
title: Install Istio for Google Cloud Endpoints Services
description: Explains how to manually integrate Google Cloud Endpoints services with Istio.
weight: 10
aliases:
    - /zh/docs/guides/endpoints/index.html
    - /zh/docs/examples/endpoints/
---

This document shows how to manually integrate Istio with existing
Google Cloud Endpoints services.

## Before you begin

If you don't have an Endpoints service and want to try it out, you can follow
the [instructions](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine)
to setup an Endpoints service on GKE.
After setup, you should be able to get an API key and store it in `ENDPOINTS_KEY` environment variable and the external IP address `EXTERNAL_IP`.
You may test the service using the following command:

{{< text bash >}}
$ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}"
{{< /text >}}

To install Istio for GKE, follow our [Quick Start with Google Kubernetes Engine](/zh/docs/setup/platform-setup/gke).

## HTTP endpoints service

1.  Inject the service and the deployment into the mesh using `--includeIPRanges` by following the
[instructions](/zh/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services)
so that Egress is allowed to call external services directly.
Otherwise, ESP will not be able to access Google cloud service control.

1.  After injection, issue the same test command as above to ensure that calling ESP continues to work.

1.  If you want to access the service through Istio ingress, create the following networking definitions:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: echo-gateway
    spec:
      selector:
        istio: ingressgateway # use Istio default gateway implementation
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - "*"
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: echo
    spec:
      hosts:
      - "*"
      gateways:
      - echo-gateway
      http:
      - match:
        - uri:
            prefix: /echo
        route:
        - destination:
            port:
              number: 80
            host: esp-echo
    ---
    EOF
    {{< /text >}}

1.  Get the ingress gateway IP and port by following the [instructions](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports).
You can verify accessing the Endpoints service through Istio ingress:

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${INGRESS_HOST}:${INGRESS_PORT}/echo?key=${ENDPOINTS_KEY}"
    {{< /text >}}

## HTTPS endpoints service using secured Ingress

The recommended way to securely access a mesh Endpoints service is through an ingress configured with TLS.

1.  Install Istio with strict mutual TLS enabled. Confirm that the following command outputs either `STRICT` or empty:

    {{< text bash >}}
    $ kubectl get meshpolicy default -n istio-system -o=jsonpath='{.spec.peers[0].mtls.mode}'
    {{< /text >}}

1.  Re-inject the service and the deployment into the mesh using `--includeIPRanges` by following the
[instructions](/zh/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services)
so that Egress is allowed to call external services directly.
Otherwise, ESP will not be able to access Google cloud service control.

1.  After this, you will find access to `ENDPOINTS_IP` no longer works because the Istio proxy only accepts secure mesh connections.
Accessing through Istio ingress should continue to work since the ingress proxy initiates mutual TLS connections within the mesh.

1.  To secure the access at the ingress, follow the [instructions](/zh/docs/tasks/traffic-management/ingress/secure-ingress-mount/).
