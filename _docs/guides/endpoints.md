---
title: Install Istio for Google Cloud Endpoints Services
overview: Explains how to manually integrate Google Cloud Endpoints services with Istio.

order: 42
layout: docs
type: markdown
---
{% include home.html %}

This document shows how to manually integrate Istio with existing
Google Cloud Endpoints services.

## Before you begin

If you don't have an Endpoints service and want to try it out, you can follow
the instruction to setup an Endpoints service on GKE
[instructions](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine).
After setup, you should be able to get an API key and store it in `ENDPOINTS_KEY` environment variable and the external IP address `EXTERNAL_IP`.
You may test the service using the following command:
```bash
curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${EXTERNAL_IP}:80/echo?key=${ENDPOINTS_KEY}"
```

You need to install Istio with [instructions]({{home}}/docs/setup/kubernetes/quick-start.html#google-kubernetes-engine).

## HTTP Endpoints service

1. Inject the service into mesh using `--includeIPRanges` so that Egress is allowed to call external services directly.
Otherwise, ESP won't be able to access Google cloud service control. Follow the [instructions]({{home}}/docs/tasks/traffic-management/egress.html#calling-external-services-directly).

1. After injection, issue the same test command as above to insure calling ESP continues to work.

1. If you want to access the service through Ingress, create the following ingress service:
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

1. Get the Ingress IP through [instructions]({{home}}/docs/tasks/traffic-management/ingress.html#verifying-http-ingress).
You can verify accessing the Endpoints service through Ingress:
```bash
curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${INGRESS_HOST}:80/echo?key=${ENDPOINTS_KEY}"i
```

## HTTPS Endpoints service using secured Ingress

The recommended way to securely access a mesh Endpoints service is through secured Ingress with a mTLS enabled mesh.

1. Expose HTTP port in your mesh service.
Adding `"--http_port=8081"` in the ESP deployment arguments and expose a HTTP port through Service ports:
```yaml
  - port: 80
    targetPort: 8081
    protocol: TCP
    name: http
```
Update the mesh service deployment.

1. Turn on mTLS in Istio. By using the following command:
```bash
kubectl edit cm istio -n istio-system
```

And uncomment the line:
```yaml
authPolicy: MUTUAL_TLS
```

1. After this, you will find access `EXTERNAL_IP` no longer works because istio proxy only accept secure mesh connections.
Accessing through Ingress still works because Ingress does HTTP terminations.

1. To secure the access at Ingress, following the [instructions]({{home}}/docs/tasks/traffic-management/ingress.html#configuring-secure-ingress-https).

1. You may verify accessing the Endpoints service through secure Ingress:
```bash
curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${INGRESS_HOST}/echo?key=${ENDPOINTS_KEY}" -k
```

## HTTPS Endpoints service using `LoadBalancer EXTERNAL_IP`

This solution uses Istio proxy for TCP bypassing. The traffic is secured through ESP. This is not a recommended way.
See port naming rules [here]({{home}}/docs/setup/kubernetes/sidecar-injection.html#pod-spec-requirements).

1. Modify the name of the HTTP port to be `tcp`
```yaml
  - port: 80
    targetPort: 8081
    protocol: TCP
    name: tcp
```
Update the mesh service deployment.

1. You can verify access to the Endpoints service through secure Ingress:
```bash
curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}" -k
```

## Additional readings

1. GCP Endpoints [website](https://cloud.google.com/endpoints/docs/).
