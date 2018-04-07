---
title: Install Istio over Google Cloud Endpoints Services  
overview: Guideline to manually integrate Google Cloud Endpoints services with Istio.

order: 42

layout: docs
type: markdown
---

This document provides a guideline to manually integrate Istio with existing
Google Cloud Endpoints services. 

# Integrate Istio with a HTTP Endpoints service.

## Before you begin

You need to follow the instruction to setup an Endpoints service on GKE [instructions](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine)
After setup, you should be able to get an API key and store it in `ENDPOINTS_KEY` environment variable and the external IP address `EXTERNAL_IP`.
You may test the service using the following command: 
```curl --request POST       --header "content-type:application/json"       --data '{"message":"hello world"}'       "http://${EXTERNAL_IP}:80/echo?key=${ENDPOINTS_KEY}"```

You need to install Istio with [instructions]({{home}}/docs/setup/kubernetes/quick-start.html#google-kubernetes-engine).

## Tasks

1. Inject the service into Istio mesh using `--includeIPRanges` so that Egress is allowed to call external services directly. 
Otherwise, ESP won't be able to access Google cloud service control. Follow the [instructions]({{home}}/docs/tasks/traffic-management/egress.html#calling-external-services-directly)

2. After injection, the same testing command by calling ESP directly continue to work. 

3. If you want to access the service through Ingress, setup the following:
```
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

4. Get the Ingress IP through [instructions]({{home}}/docs/tasks/traffic-management/ingress.html#verifying-ingress)
You can verify accessing the Endpoints service through Ingress:
```curl --request POST       --header "content-type:application/json"       --data '{"message":"hello world"}'       "http://${INGRESS_HOST}:80/echo?key=${ENDPOINTS_KEY}"```

# Integrate Istio with an HTTPS Endpoints service. 

The recommended way to securely access a mesh Endpoints service is through secured Ingress with mTLS enabled mesh.

## Secure through Istio mesh.

1. Expose HTTP port in your mesh service. 
Adding `"--http_port=8081"` in the ESP deployment arguments and expose a HTTP port through Service ports:
```
  - port: 80
    targetPort: 8081
    protocol: TCP
    name: http
``` 
Update the mesh service deployment.

2. Turn on mTLS in Istio. By using the following command:
```kubectl edit cm istio -n istio-system``` and uncomment the line: ```# authPolicy: MUTUAL_TLS```

3. After this, you will find access `EXTERNAL_IP` no longer works because istio proxy only accept secure mesh connections.
But accessing through Ingress still works because Ingress does HTTP terminations.

4. To secure the access at Ingress, following the [instructions]({{home}}/docs/tasks/traffic-management/ingress.html#configuring-secure-ingress-https)

5. You may verify accessing the Endpoints service through secure Ingress: 
```curl --request POST       --header "content-type:application/json"       --data '{"message":"hello world"}'       "https://${INGRESS_HOST}/echo?key=${ENDPOINTS_KEY}" -k```

## Continue to use LoadBalancer EXTERNAL_IP.

This solution uses Istio proxy as a TCP bypassing. The traffic is secured through ESP. This is not a recommended way.

1. Modify the name of HTTP port to be `tcp`
```
  - port: 80
    targetPort: 8081
    protocol: TCP
    name: tcp
``` 
Update the mesh service deployment.

2. You may verify accessing the Endpoints service through secure Ingress: 
```curl --request POST       --header "content-type:application/json"       --data '{"message":"hello world"}'       "https://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}" -k```

