---
title: Install Istio for Google Cloud Endpoints Services
description: Explains how to manually integrate Google Cloud Endpoints services with Istio.
weight: 42
aliases:
    - /docs/guides/endpoints/index.html
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
$ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${EXTERNAL_IP}:80/echo?key=${ENDPOINTS_KEY}"
{{< /text >}}

To install Istio for GKE, follow our [Quick Start with Google Kubernetes Engine](/docs/setup/kubernetes/gke).

## HTTP Endpoints service

1. Inject the service into the mesh using `--includeIPRanges` by following the
[instructions](/docs/tasks/traffic-management/egress/#calling-external-services-directly)
so that Egress is allowed to call external services directly.
Otherwise, ESP won't be able to access Google cloud service control.

1. After injection, issue the same test command as above to ensure that calling ESP continues to work.

1.  If you want to access the service through Ingress, create the following Ingress definition:

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: simple-ingress
      annotations:
        kubernetes.io/ingress.class: istio
    spec:
      rules:
      - http:
          paths:
          - path: /echo
            backend:
              serviceName: esp-echo
              servicePort: 80
    EOF
    {{< /text >}}

1.  Get the Ingress IP and port by following the [instructions](/docs/tasks/traffic-management/ingress#determining-the-ingress-ip-and-ports).
You can verify accessing the Endpoints service through Ingress:

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${INGRESS_HOST}:${INGRESS_PORT}/echo?key=${ENDPOINTS_KEY}"i
    {{< /text >}}

## HTTPS Endpoints service using secured Ingress

The recommended way to securely access a mesh Endpoints service is through an ingress configured with mutual TLS.

1.  Expose the HTTP port in your mesh service.
Adding `"--http_port=8081"` in the ESP deployment arguments and expose the HTTP port:

    {{< text yaml >}}
    - port: 80
      targetPort: 8081
      protocol: TCP
      name: http
    {{< /text >}}

1.  Turn on mTLS in Istio by using the following command:

    {{< text bash >}}
    $ kubectl edit cm istio -n istio-system
    {{< /text >}}

    And uncomment the line:

    {{< text yaml >}}
    authPolicy: MUTUAL_TLS
    {{< /text >}}

1. After this, you will find access to `EXTERNAL_IP` no longer works because istio proxy only accept secure mesh connections.
Accessing through Ingress works because Ingress does HTTP terminations.

1. To secure the access at Ingress, follow the [instructions](/docs/tasks/traffic-management/secure-ingress/).

1.  You can verify accessing the Endpoints service through secure Ingress:

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${INGRESS_HOST}/echo?key=${ENDPOINTS_KEY}" -k
    {{< /text >}}

## HTTPS Endpoints service using `LoadBalancer EXTERNAL_IP`

This solution uses Istio proxy for TCP bypassing. The traffic is secured through ESP. This is not a recommended way.

1.  Modify the name of the HTTP port to be `tcp`

    {{< text yaml >}}
    - port: 80
      targetPort: 8081
      protocol: TCP
      name: tcp
    {{< /text >}}

1.  Update the mesh service deployment. See further readings on port naming rules
[here](/docs/setup/kubernetes/sidecar-injection/#pod-spec-requirements).

1.  You can verify access to the Endpoints service through secure Ingress:

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}" -k
    {{< /text >}}
