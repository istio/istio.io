---
title: FAQ
overview: Common issues, known limitations and work arounds, and other frequently asked questions on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

* _How can I view the current rules I have configured with Istio?_

  Rules can be viewed using `istioctl get routerules -o yaml` or `kubectl get routerules -o yaml`.

* _I created a weighted Route Rule to split traffic between two versions of a service but I am not seeing
  the expected behavior._
  
  For the current Envoy sidecar implementation, up to 100 requests may be required for the desired
  distribution to be observed.
  
* _How come some of my services are unreachable after creating Route Rules?_
 
  This is an known issue with the current Envoy sidecar implementation.  After two seconds of creating the 
  rule, services should become available.

* _Can I use standard Ingress specification without any route rules?_

  Simple ingress specifications, with host, TLS, and exact path based
  matches will work out of the box without the need for route
  rules. However, note that the path used in the ingress resource should
  not have any `.` characters.
  
  For example, the following ingress resource matches requests for
  example.com host, with /helloworld as the URL.
  
  ```bash
  cat <<EOF | kubectl create -f -
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: simple-ingress
    annotations:
      kubernetes.io/ingress.class: istio
  spec:
    rules:
    - host: example.com
      http:
        paths:
        - path: /helloworld
          backend:
            serviceName: myservice
            servicePort: grpc
  EOF
  ```
 
  However, the following rules will not work because it uses regular
  expressions in the path and uses `ingress.kubernetes.io` annotations.

  ```bash
  cat <<EOF | kubectl create -f -
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: this-will-not-work
    annotations:
      kubernetes.io/ingress.class: istio
      # Ingress annotations other than ingress class will not be honored
      ingress.kubernetes.io/rewrite-target: /
  spec:
    rules:
    - host: example.com
      http:
        paths:
        - path: /hello(.*?)world/
          backend:
            serviceName: myservice
            servicePort: grpc
  EOF
  ```
 
