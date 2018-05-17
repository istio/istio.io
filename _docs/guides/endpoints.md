---
title: Install Istio for Google Cloud Endpoints Services
description: Explains how to manually integrate Google Cloud Endpoints services with Istio.

weight: 42
---
{% include home.html %}

This document shows how to manually integrate Istio with existing
Google Cloud Endpoints services.

## Before you begin

If you don't have an Endpoints service and want to try it out, you can follow
the [instructions](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine)
to setup an Endpoints service on GKE.
After setup, you should be able to get an API key and store it in `ENDPOINTS_KEY` environment variable and the external IP address `EXTERNAL_IP`.
You may test the service using the following command:

```command
$ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${EXTERNAL_IP}:80/echo?key=${ENDPOINTS_KEY}"
```

You need to install Istio with [instructions]({{home}}/docs/setup/kubernetes/quick-start.html#google-kubernetes-engine).

## HTTP Endpoints service

1. Inject the service into the mesh using `--includeIPRanges` by following the
[instructions]({{home}}/docs/tasks/traffic-management/egress.html#calling-external-services-directly)
so that Egress is allowed to call external services directly.
Otherwise, ESP won't be able to access Google cloud service control.

1. After injection, issue the same test command as above to ensure that calling ESP continues to work.

1.  If you want to access the service through Ingress, create the following Ingress definition:

    ```bash
    cat <<EOF | istioctl create -f -
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
    ```

1.  Get the Ingress IP through [instructions]({{home}}/docs/tasks/traffic-management/ingress.html#verifying-http-ingress).
You can verify accessing the Endpoints service through Ingress:

    ```command
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${INGRESS_HOST}:80/echo?key=${ENDPOINTS_KEY}"i
    ```

## HTTPS Endpoints service using secured Ingress

The recommended way to securely access a mesh Endpoints service is through an ingress configured with mutual TLS.

1.  Expose the HTTP port in your mesh service.
Adding `"--http_port=8081"` in the ESP deployment arguments and expose the HTTP port:

    ```yaml
      - port: 80
        targetPort: 8081
        protocol: TCP
        name: http
    ```

1.  Turn on mTLS in Istio by using the following command:

    ```command
    $ kubectl edit cm istio -n istio-system
    ```

    And uncomment the line:

    ```yaml
    authPolicy: MUTUAL_TLS
    ```

1. After this, you will find access to `EXTERNAL_IP` no longer works because istio proxy only accept secure mesh connections.
Accessing through Ingress works because Ingress does HTTP terminations.

1. To secure the access at Ingress, following the [instructions]({{home}}/docs/tasks/traffic-management/ingress.html#configuring-secure-ingress-https).

1.  You can verify accessing the Endpoints service through secure Ingress:

    ```command
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${INGRESS_HOST}/echo?key=${ENDPOINTS_KEY}" -k
    ```

## HTTPS Endpoints service using `LoadBalancer EXTERNAL_IP`

This solution uses Istio proxy for TCP bypassing. The traffic is secured through ESP. This is not a recommended way.

1.  Modify the name of the HTTP port to be `tcp`

    ```yaml
      - port: 80
        targetPort: 8081
        protocol: TCP
        name: tcp
    ```

1.  Update the mesh service deployment. See further readings on port naming rules
[here]({{home}}/docs/setup/kubernetes/sidecar-injection.html#pod-spec-requirements).

1.  You can verify access to the Endpoints service through secure Ingress:

    ```command
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}" -k
    ```

## What's next

Learn more about [GCP Endpoints](https://cloud.google.com/endpoints/docs/).
