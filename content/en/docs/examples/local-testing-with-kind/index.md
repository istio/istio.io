---
title: Testing Istio Locally With Kubernetes In Docker
description: Example of deploying Istio locally using Kubernetes In Docker for testing and evaluation.
weight: 10
keywords:
- kubernetes
- kind
- metallb
- cert-manager
- ingress
---

This example uses Kubernetes In Docker ([KIND][kind]) to deploy Istio locally. The cluster produced is intended to be used for further testing, evaluation and experimentation with Istio.

## Before you begin

Sections in this example provide a walk through of deploying a `kind` cluster similar to how the [Istio Kind Documentation](/docs/setup/platform-setup/kind) recommends, but with several important follow up steps to deploy certificate management and Istio gateways with TLS. Before proceeding, familiarize yourself with that documentation to make sure you have a general working knowledge of `kind`.

Make sure you have `jq` [installed][jq] on your local system for `JSON` processing.

## Deploying Kubernetes

Create a default Kubernetes cluster using `kind` with a single node:

{{< text bash >}}
$ kind create cluster --name istio-testing
{{< /text >}}

{{< tip >}}
If you're interested in building a multi-node cluster, or otherwise further customizing the cluster setup (e.g. different Kubernetes versions, more worker nodes) then be sure to check the [Kind Cluster Configuration Documentation](https://kind.sigs.k8s.io/docs/user/quick-start#configuring-your-kind-cluster) which will help you explore the available options.
{{< /tip >}}

Once the cluster has completed deployment switch your [kubectl][kubectl] context to start using it:

{{< text bash >}}
$ kubectl cluster-info --context kind-istio-testing
{{< /text >}}

And then test access to the cluster by retrieving resources to make sure everything is working (e.g. `kubectl get all -A`).

## Enabling external load balancers

By default, Istio creates a [Load Balancer Service][servicelb] which resolves with an external address. For the purposes of this example, use [MetalLB][metallb] to resolve the `LoadBalancer` type `Service` resources to an address available on the Docker network from the host machine.

{{< tip >}}
For this example assume that the default Docker network is used with an IP range of `172.17.255.1-172.17.255.250` (if you ran `kind` with no specific configuration, this should be the default). If however you are using an alternative network configuration, you'll need to make the appropriate updates to the `addresses` field in the below MetalLB configuration before deploying.
{{< /tip >}}

First pick the latest release and deploy the MetalLB components:

{{< text bash >}}
$ export LATEST_METALLB_RELEASE="$(curl -s https://api.github.com/repos/metallb/metallb/releases/latest | jq -r '.tag_name')"
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${LATEST_METALLB_RELEASE}/manifests/namespace.yaml
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${LATEST_METALLB_RELEASE}/manifests/metallb.yaml
{{< /text >}}

Next, generate a secret for MetalLB:

{{< text bash >}}
$ kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
{{< /text >}}

Then, add a configuration file for MetalLB so it knows what protocol to use and what address range is available to it:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: config
  namespace: metallb-system
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.17.255.1-172.17.255.250
EOF
{{< /text >}}

Now the external IP addresses for `LoadBalancer` type `Service` resources can be provisioned.

## Certificates

A default deployment of Istio serves only HTTP traffic, which can be very limiting for testing. For this example use [Cert Manager][certmanager] to provide a `ClusterIssuer`, which can sign certificates for testing HTTPS ingress through gateways.

{{< tip >}}
This example uses a self-signed certificate for simplicity (all testing is done over the local network). If you're adapting the examples here to a different kind of environment keep in mind that you'll need to change what kind of issuer you use. You may want to review other documentation such as the [Ingress With Cert Manager Task](/docs/ops/integrations/certmanager/) for your own adaptations.
{{< /tip >}}

First deploy the Cert Manager components themselves:

{{< text bash >}}
$ export LATEST_CERTMANAGER_RELEASE="$(curl -s https://api.github.com/repos/jetstack/cert-manager/releases/latest | jq -r '.tag_name')"
$ kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/${LATEST_CERTMANAGER_RELEASE}/cert-manager.yaml
{{< /text >}}

{{< tip >}}
Make sure to wait for all `Deployments` in the `cert-manager` namespace to be `READY`. If you try to create a `ClusterIssuer` and the webhook manager is not `READY`, you may receive 500 errors from the API until it's resolved.
{{< /tip >}}

Now, provide a `ClusterIssuer` for the certs:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF
{{< /text >}}

All set! Now certificates for `Gateway` resources can be more easily managed.

## Deploying Istio

After all the setup is done, it's time to deploy Istio.

{{< tip >}}
Make sure you have `istoctl` [installed](/docs/ops/diagnostic-tools/istioctl/#before-you-begin)!
{{< /tip >}}

Start by using `istioctl` to deploy the base Istio installation with [SDS](/docs/tasks/traffic-management/ingress/secure-ingress/) and [Ingress with HTTPS](/docs/ops/integrations/certmanager/) enabled:

{{< text bash >}}
$ istioctl manifest apply \
  --set values.gateways.istio-ingressgateway.sds.enabled=true \
  --set values.global.k8sIngress.enabled=true \
  --set values.global.k8sIngress.enableHttps=true \
  --set values.global.k8sIngress.gatewayName=ingressgateway
{{< /text >}}

Since HTTPS is enabled for the ingress `Gateway` make sure to create a `Certificate` for it:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: ingress-cert
  namespace: istio-system
spec:
  secretName: ingress-cert
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  commonName: examples.istio.io
  dnsNames:
  - '*.istio.io'
EOF
{{< /text >}}

And patch the ingress `Gateway` to configure it for the `Certificate`:

{{< text bash >}}
$ kubectl -n istio-system patch gateway istio-autogenerated-k8s-ingress --type=json \
  -p='[{"op": "replace", "path": "/spec/servers/1/tls", "value": {"credentialName": "ingress-cert", "mode": "SIMPLE", "privateKey": "sds", "serverCertificate": "sds"}}]'
{{< /text >}}

At this point you should be able to reach the default `Gateway` over both HTTP and HTTPS (but note, that you'll receive a 404 from the `Gateway` at this point and that's expected):

{{< text bash >}}
$ export ISTIO_GATEWAY_IP=$(kubectl -n istio-system get svc istio-ingressgateway --template='{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}')
$ curl -v http://${ISTIO_GATEWAY_IP}
$ curl -k -v https://${ISTIO_GATEWAY_IP}
{{< /text >}}

Now testing can start!

## Testing traffic management

In this section there are a couple of small examples which can assist in testing and prove things are working with basic traffic management.

### HTTP test

For this test a simple [NGINX][nginx] web server is deployed to test HTTP traffic.

You can easily deploy an NGINX pod and service with:

{{< text bash >}}
$ kubectl run nginx --image nginx --wait=true
$ kubectl expose pod nginx --port 80 --target-port 80
{{< /text >}}

Create a `VirtualService` (that uses the default provided gateway) to access the server from outside the cluster:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: nginx
spec:
  gateways:
  - istio-system/istio-ingressgateway
  hosts:
  - 'http.examples.istio.io'
  http:
  - route:
    - destination:
        host: nginx
        port:
          number: 80
EOF
{{< /text >}}

That's it! You should be able to access the web server now with `curl`:

{{< text bash >}}
$ export ISTIO_GATEWAY_IP=$(kubectl -n istio-system get svc istio-ingressgateway --template='{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}')
$ curl --fail -H 'Host: http.examples.istio.io' http://${ISTIO_GATEWAY_IP}
{{< /text >}}

{{< tip >}}
It can take a few moments before the route works. Make sure to retry a few times if you can't reach the NGINX server immediately.
{{< /tip >}}

When things are working properly the response output will include: `<h1>Welcome to nginx!</h1>`

### HTTPS test

This example is a variant of the HTTP test with TLS termination at the ingress level.

Create and expose a new [NGINX][nginx] web server to test:

{{< text bash >}}
$ kubectl create namespace nginx
$ kubectl -n nginx run nginx --image nginx --wait=true
$ kubectl -n nginx expose pod nginx --port 80 --target-port 80
{{< /text >}}

Create a `Gateway` and `VirtualService` to serve traffic to the web server:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: nginx
  namespace: nginx
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      credentialName: ingress-cert
      mode: SIMPLE
      privateKey: sds
      serverCertificate: sds
    hosts:
    - "https.example.istio.io"
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx
  namespace: nginx
spec:
  hosts:
  - "https.example.istio.io"
  gateways:
  - nginx
  http:
  - route:
    - destination:
        port:
          number: 80
        host: nginx
EOF
{{< /text >}}

Now it should be possible to access your web server over the external IP using the `https.example.istio.io` domain:

{{< text bash >}}
$ export ISTIO_GATEWAY_IP=$(kubectl -n istio-system get svc istio-ingressgateway --template='{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}')
$ curl -k --resolve https.example.istio.io:443:${ISTIO_GATEWAY_IP} https://https.example.istio.io
{{< /text >}}

If everything worked properly you should see `<h1>Welcome to nginx!</h1>` in the output.

### TLS passthrough test

A simple test of TLS passthrough can be done by patching through to the Kubernetes API itself.

For this create a new `Gateway` with TLS mode set to `PASSTHROUGH`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kubernetes
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
    hosts:
    - examples.istio.io
EOF
{{< /text >}}

And then a `VirtualService` to attach to the Kubernetes API via the internal `Service`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: kubernetes
spec:
  gateways:
  - kubernetes
  hosts:
  - examples.istio.io
  tls:
  - match:
    - port: 443
      sni_hosts:
      - examples.istio.io
    route:
    - destination:
        host: kubernetes
        port:
          number: 443
EOF
{{< /text >}}

Then you should be able to access the Kubernetes API through the `Gateway`:

{{< text bash >}}
$ export ISTIO_GATEWAY_IP=$(kubectl -n istio-system get svc istio-ingressgateway --template='{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}')
$ curl -H 'Content-Type: application/json' -w '\n' -k --resolve examples.istio.io:443:${ISTIO_GATEWAY_IP} https://examples.istio.io/version
{{< /text >}}

If all went well the result of the above `curl` command should be the `/version` output from the Kubernetes API, similar to:

{{< text json >}}
{
  "major": "1",
  "minor": "17",
  "gitVersion": "v1.17.2",
  "gitTreeState": "clean",
  "goVersion": "go1.13.5",
  "compiler": "gc",
  "platform": "linux/amd64"
}
{{< /text >}}

## What's next

In this example a simple and relatively complete Istio enabled Kubernetes cluster was created.

From here you can look at some of the other [examples](/docs/examples) and [tasks](/docs/tasks) and try them on this cluster and otherwise test and experiment with Istio.

If you have any need for an integration testing environment which includes Istio for your own tests these examples may provide a foundation which can be expanded upon.

## Cleanup

Cleanup is as simple as deleting the `kind` cluster:

{{< text bash >}}
$ kind delete cluster --name istio-testing
{{< /text >}}

[jq]:https://github.com/stedolan/jq
[kind]:https://github.com/kubernetes-sigs/kind
[docker]:https://docs.docker.com/
[kubectl]:https://kubernetes.io/docs/reference/kubectl/overview/
[servicelb]:https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/
[metallb]:https://metallb.universe.tf/
[certmanager]:https://cert-manager.io/
[nginx]:https://nginx.com
