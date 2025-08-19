---
title: Proxying legacy services using Istio egress gateways 
subtitle: Deploy mesh egress gateways independently to allow secure connectivity between legacy and internet services
description: Deploy multiple Istio egress gateways independently to have fine-grained control of egress communication from the mesh.
publishdate: 2020-12-16
attribution: Antonio Berben (Deutsche Telekom - PAN-NET)
keywords: [configuration,egress,gateway,external,service]
target_release: 1.8.0
---

At [Deutsche Telekom Pan-Net](https://pan-net.cloud/aboutus), we have embraced Istio as the umbrella to cover our services. Unfortunately, there are services which have not yet been migrated to Kubernetes, or cannot be.

We can set Istio up as a proxy service for these upstream services. This allows us to benefit from capabilities like authorization/authentication, traceability and observability, even while legacy services stand as they are.

At the end of this article there is a hands-on exercise where you can simulate the scenario. In the exercise, an upstream service hosted at [https://httpbin.org](https://httpbin.org) will be proxied by an Istio egress gateway.

If you are familiar with Istio, one of the methods offered to connect to upstream services is through an [egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/).

You can deploy one to control all the upstream traffic or you can deploy multiple in order to have fine-grained control and satisfy the [single-responsibility principle](https://en.wikipedia.org/wiki/Single-responsibility_principle) as this picture shows:

{{< image width="75%" ratio="45.34%"
    link="./proxying-legacy-services-using-egress-gateways-overview.svg"
    alt="Overview multiple Egress Gateways"
    caption="Overview multiple Egress Gateways"
    >}}

With this model, one egress gateway is in charge of exactly one upstream service.

Although the Operator spec allows you to deploy multiple egress gateways, the manifest can become unmanageable:

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
    [egressgateway-3, egressgateway-4, ...]
    - name: egressgateway-N
      enabled: true
[...]
{{< /text >}}

As a benefit of decoupling egress getaways from the Operator manifest, you have enabled the possibility of setting up custom readiness probes to have both services (Gateway and upstream Service) aligned.

You can also inject OPA as a sidecar into the pod to perform authorization with complex rules ([OPA envoy plugin](https://github.com/open-policy-agent/opa-envoy-plugin)).

{{< image width="75%" ratio="45.34%"
    link="./proxying-legacy-services-using-egress-gateways-authz.svg"
    alt="Authorization with OPA and `healthcheck` to upstream service"
    caption="Authorization with OPA and `healthcheck` to external"
    >}}

As you can see, your possibilities increase and Istio becomes very extensible.

Let's look at how you can implement this pattern.

## Solution

There are several ways to perform this task, but here you will find how to define multiple Operators and deploy the generated resources.

{{< quote >}}
Yes! `Istio 1.8.0` introduced the possibility to have fine-grained control over the objects that Operator deploys. This gives you the opportunity to patch them as you wish. Exactly what you need to proxy legacy services using Istio egress gateways.
{{< /quote >}}

In the following section you will  deploy an egress gateway to connect to an upstream service: `httpbin` ([https://httpbin.org/](https://httpbin.org/))

At the end, you will have:

{{< image width="75%" ratio="45.34%"
    link="./proxying-legacy-services-using-egress-gateways-communication.svg"
    alt="Communication"
    caption="Communication"
    >}}

## Hands on

### Prerequisites

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) (Kubernetes-in-Docker - perfect for local development)
- [istioctl](/docs/setup/getting-started/#download)

#### Kind

{{< warning >}}
If you use `kind`, do not forget to set up `service-account-issuer` and `service-account-signing-key-file` as described below. Otherwise, Istio may not install correctly.
{{< /warning >}}

Save this as `config.yaml`.

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
$ kind create cluster --name <my-cluster-name> --config config.yaml
{{< /text >}}

Where `<my-cluster-name>` is the name for the cluster.

#### Istio Operator with Istioctl

Install the Operator

{{< text bash >}}
$ istioctl operator init --watchedNamespaces=istio-operator
{{< /text >}}

{{< text bash >}}
$ kubectl create ns istio-system
{{< /text >}}

Save this as `operator.yaml`:

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
`outboundTrafficPolicy.mode: REGISTRY_ONLY` is used to block all external communications which are not specified by a `ServiceEntry` resource.
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f operator.yaml
{{< /text >}}

### Deploy Egress Gateway

The steps for this task assume:

- The service is installed under the namespace: `httpbin`.
- The service name is: `http-egress`.

Istio 1.8 introduced the possibility to apply overlay configuration, to give fine-grain control over the created resources.

Save this as `egress.yaml`:

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
Notice the block under `overlays`. You are patching the default `egressgateway` to deploy only that component with the new `readinessProbe`.
{{< /tip >}}

Create the namespace where you will install the egress gateway:

{{< text bash >}}
$ kubectl create ns httpbin
{{< /text >}}

As it is described in the [documentation](/docs/setup/install/istioctl/#customize-kubernetes-settings), you can deploy several Operator resources. However, they have to be pre-parsed and then applied to the cluster.

{{< text bash >}}
$ istioctl manifest generate -f egress.yaml | kubectl apply -f -
{{< /text >}}

### Istio configuration

Now you will configure Istio to allow connections to the upstream service at [https://httpbin.org](https://httpbin.org).

#### Certificate for TLS

You need a certificate to make a secure connection from outside the cluster to your egress service.

How to generate a certificate is explained in the [Istio ingress documentation](/docs/tasks/traffic-management/ingress/secure-ingress/#generate-client-and-server-certificates-and-keys).

Create and apply one to be used at the end of this article to access the service from outside the cluster (`<my-proxied-service-hostname>`):

{{< text bash >}}
$ kubectl create -n istio-system secret tls <my-secret-name> --key=<key> --cert=<cert>
{{< /text >}}

Where `<my-secret-name>` is the name used later for the `Gateway` resource. `<key>` and `<cert>` are the files for the certificate. `<cert>`.

{{< tip >}}
You need to remember `<my-proxied-service-hostname>`, `<cert>` and `<my-secret-name>` because you will use them later in the article.
{{< /tip >}}

#### Ingress Gateway

Create a `Gateway` resource to operate ingress gateway to accept requests.

{{< warning >}}
Make sure that only one Gateway spec matches the hostname. Istio gets confused when there are multiple Gateway definitions covering the same hostname.
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
    - "<my-proxied-service-hostname>"
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
    - "<my-proxied-service-hostname>"
    tls:
      mode: SIMPLE
      credentialName: <my-secret-name>
{{< /text >}}

Where `<my-proxied-service-hostname>` is the hostname to access the service through the `my-ingressgateway` and `<my-secret-name>` is the secret which contains the certificate.

#### Egress Gateway

Create another Gateway object, but this time to operate the egress gateway you have already installed:

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
    - "<my-proxied-service-hostname>"
    port:
      number: 80
      name: http
      protocol: HTTP
{{< /text >}}

Where `<my-proxied-service-hostname>` is the hostname to access through the `my-ingressgateway`.

#### Virtual Service

Create a `VirtualService` for three use cases:

- **Mesh** gateway for service-to-service communications within the mesh
- **Ingress Gateway** for the communication from outside the mesh
- **Egress Gateway** for the communication to the upstream service

{{< tip >}}
Mesh and Ingress Gateway will share the same specification. It will redirect the traffic to your egress gateway service.
{{< /tip >}}

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: "httpbin-egress"
  namespace: "httpbin"
spec:
  hosts:
  - "<my-proxied-service-hostname>"
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

Where `<my-proxied-service-hostname>` is the hostname to access through the `my-ingressgateway`.

#### Service Entry

Create a `ServiceEntry` to allow the communication to the upstream service:

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

Verify that your objects were all specified correctly:

{{< text bash >}}
$ istioctl analyze --all-namespaces
{{< /text >}}

#### External access

Test the egress gateway from outside the cluster forwarding the `ingressgateway` service's port and calling the service

{{< text bash >}}
$ kubectl -n istio-system port-forward svc/istio-ingressgateway 15443:443
{{< /text >}}

{{< text bash >}}
$ curl -vvv -k -HHost:<my-proxied-service-hostname> --resolve "<my-proxied-service-hostname>:15443:127.0.0.1" --cacert <cert> "https://<my-proxied-service-hostname>:15443/status/200"
{{< /text >}}

Where `<my-proxied-service-hostname>` is the hostname to access through the `my-ingressgateway` and `<cert>` is the certificate defined for the `ingressgateway` object. This is due to `tls.mode: SIMPLE` which [does not terminate TLS](/docs/tasks/traffic-management/ingress/secure-ingress/)

#### Service-to-service access

Test the egress gateway from inside the cluster deploying the sleep service. This is useful when you design failover.

{{< text bash >}}
$ kubectl label namespace httpbin istio-injection=enabled --overwrite
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n httpbin -f  {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl -n httpbin "$(kubectl get pod -n httpbin -l app=sleep -o jsonpath={.items..metadata.name})" -- curl -vvv http://<my-proxied-service-hostname>/status/200
{{< /text >}}

Where `<my-proxied-service-hostname>` is the hostname to access through the `my-ingressgateway`.

{{< tip >}}
Notice that `http` (and not `https`) is the protocol used for service-to-service communication. This is due to Istio handling the `TLS` itself. Developers do not care anymore about certificates management. **Fancy!**
{{< /tip >}}

{{< quote >}}
Eat, Sleep, Rave, **REPEAT!**
{{< /quote >}}

Now it is time to create a second, third and fourth egress gateway pointing to other upstream services.

## Final thoughts

{{< quote >}}
Is the juice worth the squeeze?
{{< /quote >}}

Istio might seem complex to configure. But it is definitely worthwhile, due to the huge set of benefits it brings to your services (with an extra **Olé!** for Kiali).

The way Istio is developed allows us, with minimal effort, to satisfy uncommon requirements like the one presented in this article.

To finish, I just wanted to point out that Istio, as a good cloud native technology, does not require a large team to maintain. For example, our current team is composed of 3 engineers.

To discuss more about Istio and its possibilities, please contact one of us:

- [Antonio Berben](https://twitter.com/antonio_berben)
- [Piotr Ciążyński](https://www.linkedin.com/in/piotr-ciazynski)
- [Kristián Patlevič](https://www.linkedin.com/in/patlevic)
