---
title: On Demand Egress Gateways
subtitle: Deploy Egress Gateways independently in a seamless way
description: Deploying Egress Gateways independently to have fine-grained control of egress communication.
publishdate: 2020-11-07
attribution: Antonio Berben (Deutsche Telekom - PAN-NET)
keywords: [configuration,egress,gateway,external,service]
target_release: 1.8.0
---

At [Deutsche Telekom Pan-Net](https://pan-net.cloud/aboutus), we have embraced Istio as the umbrella to cover our services.

Unfortunately, there are services which have not yet been migrated to Kubernetes, or cannot be. 

## Scenario

If you are familiar with Istio, one of the methods offered to connect to external services is through an [egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/).

However, if you want to satisfy the [single-responsibility principle](https://en.wikipedia.org/wiki/Single-responsibility_principle), you will need to deploy multiple and individual (1..N) egress gateways, as this picture shows:

{{< image width="75%" ratio="45.34%"
    link="./on-demand-egress-gateway-overview.svg"
    alt="Overview multiple Egress Gateways"
    caption="Overview multiple Egress Gateways"
    >}}

With this model, one egress gateway is in charge of exactly one upstream service.

Although the `IstioOperator` spec allows you to deploy multiple egress gateways, the manifest can become unmanageable:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
[...]
spec:
    egressGateways:
    - name: egressgateway-1
      enabled: true
    - name: egressgateway-2
      enabled: true
    [egressgateway-3, egressgateway-4 ,...]
    - name: egressgateway-N
      enabled: true
[...]
{{< /text >}}

As a benefit of decoupling egress getaways from the `IstioOperator` manifest, you have enabled the possibility of setting up custom readiness probes to have both services (Gateway and upstream Service) aligned.
As well, you can apply the sidecar pattern to inject, for example, OPA into the pod to perform authorization with complex rules ([OPA envoy plugin](https://github.com/open-policy-agent/opa-envoy-plugin)).

{{< image width="75%" ratio="45.34%"
    link="./on-demand-egress-gateway-authz.svg"
    alt="Authorization with OPA and `healthcheck` to external service"
    caption="Authorization with OPA and `healthcheck` to external"
    >}}

At this point, you might be convinced that this is the right path to go.

## Solution

There are several ways to achieve this task:

- Create multiple `IstioOperator` (simple solution)
- Create an operator (recommended for a second iteration in the development process)

At **PAN-NET**, we have created our own operator with the [Operator SDK - Ansible type](https://sdk.operatorframework.io/docs/building-operators/).

However, you want to start simple. Thus, better you start with the `IstioOperator` option.

{{< quote >}}
Yes! `Istio 1.8.0` introduced the possibility to have fine-grained control over the objects that `IstioOperator` deploys. This gives you the opportunity to patch them as you wish. Exactly what you need to deploy on demand `Egress Gateways`.
{{< /quote >}}

In the following section you will  deploy an `Egress Gateway` to connect to an external service: `httpbin` ([https://httpbin.org/](https://httpbin.org/))

At the end, you will have:

{{< image width="75%" ratio="45.34%"
    link="./on-demand-egress-gateway-communicatin.svg"
    alt="Communication"
    caption="Communication"
    >}}

## Hands on

### Prerequisites

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) (`kubernetes in docker`. Perfect for local development)
- [Istioctl](/docs/setup/getting-started/#download)

#### Kind

{{< warning >}}
If you use `kind`, do not forget to set up `service-account-issuer` and `service-account-signing-key-file` as described below. Otherwise, `Istio` installation might complain.
{{< /warning >}}

{{< text yaml >}}
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
kubeadmConfigPatches:
  - |
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: ClusterConfiguration
    metadata:
      name: config
    apiServer:
      extraArgs:
        "service-account-issuer": "kubernetes.default.svc"
        "service-account-signing-key-file": "/etc/kubernetes/pki/sa.key"
{{< /text >}}

{{< text bash >}}
$ kind create cluster --name <my-cluster-name> --config <path-to-config-file>
{{< /text >}}

Where `<my-cluster-name>` is the name for the cluster and `<path-to-config-file>` is the config defined in the block above.

#### Istio Operator with Istioctl

Install the `Istio Operator`

{{< text bash >}}
$ istioctl operator init --watchedNamespaces=istio-operator
{{< /text >}}

{{< text bash >}}
$ kubectl create ns istio-system
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f <my-istiooperator-manifest>
{{< /text >}}

Where `<my-istiooperator-manifest>` is the path to the a file with following content:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-operator
  namespace: istio-operator
spec:
  profile: default
  tag: 1.8.0
  meshConfig:
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
{{< /text >}}

{{< tip >}}
Notice that `outboundTrafficPolicy.mode: REGISTRY_ONLY` to block all communications which are not specified by a `ServiceEntry` resource.
{{< /tip >}}

### Deploy Egress Gateway

The steps for this task assume:

- The service is installed under the namespace: `httpbin`.
- The service name is: `http-egress`.

As it is mentioned before, `Istio 1.8.0` introduced the possibility to fine-grain control the `Istio` resources. Now, you will take advantage of it.

Create a file with following content:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  tag: 1.8.0
  namespace: httpbin
  components:
    egressGateways:
    - name: httpbin-egress
      enabled: true
      label:
        app: istio-egressgateway
        istio: egressgateway
        custom-egress: httpbin-egress
      k8s:
        overlays:
        - kind: Deployment
          name: httpbin-egress
          patches:
          - path: spec.template.spec.containers[0].readinessProbe
            value:
              failureThreshold: 30
              exec:
                command:
                  - /bin/sh
                  - -c
                  - curl http://localhost:15021/healthz/ready && curl https://httpbin.org/status/200
              initialDelaySeconds: 1
              periodSeconds: 2
              successThreshold: 1
              timeoutSeconds: 1
  values:
    gateways:
      istio-egressgateway:
        runAsRoot: true
{{< /text >}}

{{< tip >}}
Notice the block under `overlays`. You are patching the default `egressgateway` to deploy only that component with the new `readinessProbe`
{{< /tip >}}

Create the namespace where you will install the egress gateway:

{{< text bash >}}
$ kubectl create ns httpbin
{{< /text >}}

As it is described in the [documentation](/docs/setup/install/istioctl/#customize-kubernetes-settings), you can deploy several `IstioOperator` resources. However, they have to be pre-parsed and then applied to the cluster.

{{< text bash >}}
$ istioctl manifest generate -f <path-to-egress-file> | kubectl apply -f -
{{< /text >}}

Where `<path-to-egress-file>` is the path where you have saved the new `IstioOperator` CR.

### Istio configuration

Now you will set up `Istio` to connect to the external service [https://httpbin.org](https://httpbin.org)

#### Certificate for TLS

How to generate a certificate is explained in the [Istio ingress documentation](/docs/tasks/traffic-management/ingress/secure-ingress/#generate-client-and-server-certificates-and-keys).

{{< text bash >}}
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=<my-hostname>' -keyout example.com.key -out example.com.crt
{{< /text >}}

{{< text bash >}}
$ openssl req -out httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin.example.com.key -subj "/CN=<my-hostname>/O=httpbin organization"
{{< /text >}}

{{< text bash >}}
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin.example.com.csr -out httpbin.example.com.crt
{{< /text >}}

{{< text bash >}}
$ kubectl create -n istio-system secret tls <my-secret-name> --key=httpbin.example.com.key --cert=httpbin.example.com.crt
{{< /text >}}

Where `<my-secret-name>` is the name used later for the `Gateway` resource. `<my-hostname>` is the hostname used to access your service.

#### Ingress Gateway

Create a `Gateway` resource to operate ingress gateway to accept requests.

{{< warning >}}
Make sure that only one `Gateway` spec matches the hostname. `Istio` gets confused when there are multiple Gateway definitions covering the same hostname.
{{< /warning >}}

An example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: my-ingressgateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "<my-hostname>"
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
     httpsRedirect: true
  - port:
      number: 443
      name: https
      protocol: https
    hosts:
    - "<my-hostname>"
    tls:
      mode: SIMPLE
      credentialName: <my-secret-name>
{{< /text >}}

Where `<my-hostname>` is the hostname to access the service through the `my-ingressgateway` and `<my-secret-name>` is the secret which contains the certificate.

#### Egress Gateway

Create another Gateway object, but this time to operate the `Egress Gateway` you have already installed with `helm`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: "httpbin-egress"
  namespace: "httpbin"
spec:
  selector:
    istio: egressgateway
    service.istio.io/canonical-name: "httpbin-egress"
  servers:
  - hosts:
    - "<my-hostname>"
    port:
      number: 80
      name: http
      protocol: HTTP
{{< /text >}}

Where `<my-hostname>` is the hostname to access through the `my-ingressgateway`.

#### Virtual Service

Create a `VirtualService` for three use cases:

- **Mesh** gateway for service-to-service communications within the mesh
- **Ingress Gateway** for the communication from outside the mesh
- **Egress Gateway** for the communication to the external service

{{< tip >}}
Mesh and Ingress Gateway will share the same specification. It will redirect the traffic to your `Egress Gateway` service.
{{< /tip >}}

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: "httpbin-egress"
  namespace: "httpbin"
spec:
  hosts:
  - "<my-hostname>"
  gateways:
  - mesh
  - "istio-system/my-ingressgateway"
  - "httpbin/httpbin-egress"
  http:
  - match:
    - gateways:
      - "istio-system/my-ingressgateway"
      - mesh
      uri:
        prefix: "/"
    route:
    - destination:
        host: "httpbin-egress.httpbin.svc.cluster.local"
        port:
          number: 80
  - match:
    - gateways:
      - "httpbin/httpbin-egress"
      uri:
        prefix: "/"
    route:
    - destination:
        host: "httpbin.org"
        subset: "http-egress-subset"
        port:
          number: 443
{{< /text >}}

Where `<my-hostname>` is the hostname to access through the `my-ingressgateway`.

#### Service Entry

Create a `ServiceEntry` to allow the communication to the external service:

{{< tip >}}
Notice that the port is configured for TLS protocol
{{< /tip >}}

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: "httpbin-egress"
  namespace: "httpbin"
spec:
  hosts:
  - "httpbin.org"
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: TLS
  resolution: DNS
{{< /text >}}

#### Destination Rule

Create a `DestinationRule` to allow TLS origination for egress traffic as explained in the [documentation](/docs/tasks/traffic-management/egress/egress-tls-origination/#tls-origination-for-egress-traffic)

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: "httpbin-egress"
  namespace: "httpbin"
spec:
  host: "httpbin.org"
  subsets:
  - name: "http-egress-subset"
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 443
        tls:
          mode: SIMPLE
{{< /text >}}

#### Peer Authentication

To secure the service-to-service, you need to enforce mTLS:

{{< text yaml >}}
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "httpbin-egress"
  namespace: "httpbin"
spec:
  mtls:
    mode: STRICT
{{< /text >}}

### Test

Verify that everything in `Istio` works.

{{< text bash >}}
$ istioctl analyze --all-namespaces
{{< /text >}}

#### External access

Test the `Egress Gateway` from outside the cluster forwarding the `ingressgateway` service's port and calling the service

{{< text bash >}}
$ kubectl -n istio-system port-forward svc/istio-ingressgateway 15443:443
{{< /text >}}

{{< text bash >}}
$ curl -vvv -k -HHost:<my-hostname> --resolve "<my-hostname>:15443:127.0.0.1" --cacert example.com.crt "https://<my-hostname>:15443/status/200"
{{< /text >}}

Where `<my-hostname>` is the hostname to access through the `my-ingressgateway` and `example.com.crt` is the certificate defined for the `ingressgateway` object. This is due to `tls.mode: SIMPLE` which [does not terminate TLS](/docs/tasks/traffic-management/ingress/secure-ingress/)

#### Service-to-service access

Test the `Egress Gateway` from inside the cluster deploying the sleep service. This is useful when you design failover.

{{< text bash >}}
$ kubectl label namespace httpbin istio-injection=enabled --overwrite
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n httpbin -f  {{< github_file >}}/1.8.0/samples/sleep/sleep.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl -n httpbin "$(kubectl get pod -n httpbin -l app=sleep -o jsonpath={.items..metadata.name})" -- curl -vvv http://<my-hostname>/status/200
{{< /text >}}

Where `<my-hostname>` is the hostname to access through the `my-ingressgateway`.

{{< tip >}}
Notice that `http` (and not `https`) is the protocol used for service-to-service communication. This is due to `Istio` handling the `TLS` itself. Developers do not care anymore about certificates management. **Fancy!**
{{< /tip >}}

{{< quote >}}
Eat, Sleep, Rave, **REPEAT!**
{{< /quote >}}

Now it is time to create a second, third and fourth `Egress Gateway` pointing to another external service.

## Final thoughts

{{< quote >}}
Is the juice worth the squeeze?
{{< /quote >}}

`Istio` might seem complex to configure. But, definitely, it is worthy due to the huge set of benefits it brings to your services (extra **Olé!** for `kiali`).

The way `Istio` is developed allows, with a small effort, to satisfy uncommon requirements like the one presented in this article.

To finish, just to mention that `Istio`, as a good cloud native technology, does not require a full set of engineers to be maintained. For example, our current team is composed of 3 engineers.

To discuss more about `Istio` and its possibilities, you can find us in:

- `Antonio Berben` ([`twitter @antonio_berben`](https://twitter.com/antonio_berben))
- `Piotr Ciążyński` ([`LinkedIn`](https://www.linkedin.com/in/piotr-ciazynski))
- `Kristián Patlevič` ([`LinkedIn`](https://www.linkedin.com/in/patlevic))
