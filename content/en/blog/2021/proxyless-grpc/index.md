---
title: "gRPC Proxyless Service Mesh"
description: Introduction to Istio support for gRPC's proxyless service mesh features.
publishdate: 2021-10-28
attribution: "Steven Landow (Google)"
---

Istio dynamically configures its Envoy sidecar proxies using a set of discovery APIs, collectively known as the
[xDS APIs](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/dynamic_configuration).
These APIs aim to become a [universal data-plane API](https://blog.envoyproxy.io/the-universal-data-plane-api-d15cec7a?gi=64aa2eea0283).
The gRPC project has significant support for the xDS APIs, which means you can manage gRPC workloads
without having to deploy an Envoy sidecar along with them. You can learn more about the integration in a
[KubeCon EU 2021 talk from Megan Yahya](https://www.youtube.com/watch?v=cGJXkZ7jiDk). The latest updates on gRPC's
support can be found in their [proposals](https://github.com/grpc/proposal/search?q=xds) along with implementation
status.

Istio 1.11 adds experimental support for adding gRPC services directly to the mesh. We support basic service
discovery, some VirtualService based traffic policy, and mutual TLS.

## Supported Features

The current implementation of the xDS APIs within gRPC is limited in some areas compared to Envoy. The following
features should work, although this is not an exhaustive list and other features may have partial functionality:

* Basic service discovery. Your gRPC service can reach other pods and virtual machines registered in the mesh.
* [`DestinationRule`](/docs/reference/config/networking/destination-rule/):
    * Subsets: Your gRPC service can split traffic based on label selectors to different groups of instances.
    * The only Istio `loadBalancer` currently supported is `ROUND_ROBIN`, `consistentHash` will be added in
      future versions of Istio (it is supported by gRPC).
    * `tls` settings are restricted to `DISABLE` or `ISTIO_MUTUAL`. Other modes will be treated as `DISABLE`.
* [`VirtualService`](/docs/reference/config/networking/virtual-service/):
    * Header match and URI match in the format `/ServiceName/RPCName`.
    * Override destination host and subset.
    * Weighted traffic shifting.
* [`PeerAuthentication`](/docs/reference/config/security/peer_authentication/):
    * Only `DISABLE` and `STRICT` are supported. Other modes will be treated as `DISABLE`.
    * Support for auto-mTLS may exist in a future release.

Other features including faults, retries, timeouts, mirroring and rewrite rules may be supported in a future release.
Some of these features are awaiting implementation in gRPC, and others require work in Istio to support. The status
of xDS features in gRPC can be found [here](https://github.com/grpc/grpc/blob/master/doc/grpc_xds_features.md). The
status of Istio's support will exist in future official docs.

{{< warning >}}
This is feature is [experimental](/docs/releases/feature-stages/). Standard Istio features will become supported
over time along with improvements to the overall design.
{{< /warning >}}

## Architecture Overview

{{< image width="80%" link="./architecture.svg" caption="Diagram of how gRPC services communicate with the istiod" >}}

Although this doesn't use a proxy for data plane communication, it still requires an agent for initialization and
communication with the control-plane. First, the agent generates a [bootstrap file](https://github.com/grpc/proposal/blob/master/A27-xds-global-load-balancing.md#xdsclient-and-bootstrap-file)
at startup the same way it would generate bootstrap for Envoy. This tells the `gRPC` library how to connect to `istiod`,
where it can find certificates for data plane communication, and what metadata to send to the control plane. Next, the
agent acts as an `xDS` proxy, connecting and authenticating with `istiod` on the application's behalf. Finally, the
agent fetches and rotates certificates used in data plane traffic.

## Changes to application code

{{< tip >}}
This section covers gRPC’s XDS support in Go. Similar APIs exist for other languages.
{{< /tip >}}

To enable the xDS features in gRPC, there are a handful of required changes your application must make. Your gRPC version should be at least `1.39.0`.

### In the client

The following side-effect import will register the xDS resolvers and balancers within gRPC. It should be added in your
`main` package or in the same package calling `grpc.Dial`.

{{< text go >}}
import _ "google.golang.org/grpc/xds"
{{< /text >}}

When creating a gRPC connection the URL must use the `xds:///` scheme.

{{< text go >}}
conn, err := grpc.DialContext(ctx, "xds:///foo.ns.svc.cluster.local:7070")
{{< /text >}}

Additionally, for (m)TLS support, a special `TransportCredentials` option has to be passed to `DialContext`.
The `FallbackCreds` allow us to succeed when istiod doesn’t send security config.

{{< text go >}}
import "google.golang.org/grpc/credentials/xds"

...

creds, err := xds.NewClientCredentials(xds.ClientOptions{
FallbackCreds: insecure.NewCredentials()
})
// handle err
conn, err := grpc.DialContext(
ctx,
"xds:///foo.ns.svc.cluster.local:7070",
grpc.WithTransportCredentials(creds),
)
{{< /text >}}

### On the server

To support server-side configurations, such as mTLS, there are a couple of modifications that must be made.

First, we use a special constructor to create the `GRPCServer`:

{{< text go >}}
import "google.golang.org/grpc/xds"

...

server = xds.NewGRPCServer()
RegisterFooServer(server, &fooServerImpl)
{{< /text >}}

If your `protoc` generated Go code is out of date, you may need to regenerate it to be compatible with the xDS server.
Your generated `RegisterFooServer` function should look like the following:

{{< text go >}}
func RegisterFooServer(s grpc.ServiceRegistrar, srv FooServer) {
s.RegisterService(&FooServer_ServiceDesc, srv)
}
{{< /text >}}

Finally, as with the client-side changes, we must enable security support:

{{< text go >}}
creds, err := xds.NewServerCredentials(xdscreds.ServerOptions{FallbackCreds: insecure.NewCredentials()})
// handle err
server = xds.NewGRPCServer(grpc.Creds(creds))
{{< /text >}}

### In your Kubernetes Deployment

Assuming your application code is compatible, the Pod simply needs the annotation `inject.istio.io/templates: grpc-agent`.
This adds a sidecar container running the agent described above, and some environment variables that gRPC uses to find
the bootstrap file and enable certain features.

For gRPC servers, your Pod should also be annotated with `proxy.istio.io/config: '{"holdApplicationUntilProxyStarts": true}'`
to make sure the in-agent xDS proxy and bootstrap file are ready before your gRPC server is initialized.

## Example

In this guide you will deploy `echo`, an application that already supports both server-side and client-side
proxyless gRPC. With this app you can try out some supported traffic policies enabling mTLS.

### Prerequisites

This guide requires the Istio (1.11+) control plane [to be installed](/docs/setup/install/) before proceeding.

### Deploy the application

Create an injection-enabled namespace `echo-grpc`. Next deploy two instances of the `echo` app as well as the Service.

{{< text bash >}}
$ kubectl create namespace echo-grpc
$ kubectl label namespace echo-grpc istio-injection=enabled
$ kubectl -n echo-grpc apply -f samples/grpc-echo/grpc-echo.yaml
{{< /text >}}

Make sure the two pods are running:

{{< text bash >}}
$ kubectl -n echo-grpc get pods
NAME                       READY   STATUS    RESTARTS   AGE
echo-v1-69d6d96cb7-gpcpd   2/2     Running   0          58s
echo-v2-5c6cbf6dc7-dfhcb   2/2     Running   0          58s
{{< /text >}}

### Test the gRPC resolver

First, port-forward `17171` to one of the Pods. This port is a non-xDS backed gRPC server that allows making
requests from the port-forwarded Pod.

{{< text bash >}}
$ kubectl -n echo-grpc port-forward $(kubectl -n echo-grpc get pods -l version=v1 -ojsonpath='{.items[0].metadata.name}') 17171 &
{{< /text >}}

Next, we can fire off a batch of 5 requests:

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070", "count": 5}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'  | grep Hostname
Handling connection for 17171
[0 body] Hostname=echo-v1-7cf5b76586-bgn6t
[1 body] Hostname=echo-v2-cf97bd94d-qf628
[2 body] Hostname=echo-v1-7cf5b76586-bgn6t
[3 body] Hostname=echo-v2-cf97bd94d-qf628
[4 body] Hostname=echo-v1-7cf5b76586-bgn6t
{{< /text >}}

You can also use Kubernetes-like name resolution for short names:

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join
("")'  | grep Hostname
[0 body] Hostname=echo-v1-7cf5b76586-ltr8q
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r
'.output | join("")'  | grep Hostname
[0 body] Hostname=echo-v1-7cf5b76586-ltr8q
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r
'.output | join("")'  | grep Hostname
[0 body] Hostname=echo-v2-cf97bd94d-jt5mf
{{< /text >}}

### Creating subsets with destination rule

First, create a subset for each version of the workload.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: echo-versions
  namespace: echo-grpc
spec:
  host: echo.echo-grpc.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
{{< /text >}}

### Traffic shifting

Using the subsets defined above, you can send 80 percent of the traffic to a specific version:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: echo-weights
  namespace: echo-grpc
spec:
  hosts:
  - echo.echo-grpc.svc.cluster.local
  http:
  - route:
    - destination:
        host: echo.echo-grpc.svc.cluster.local
        subset: v1
      weight: 20
    - destination:
        host: echo.echo-grpc.svc.cluster.local
        subset: v2
      weight: 80
EOF
{{< /text >}}

Now, send a set of 10 requests:

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070", "count": 10}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'  | grep ServiceVersion
{{< /text >}}

The response should contain mostly `v2` responses:

{{< text plain >}}
[0 body] ServiceVersion=v2
[1 body] ServiceVersion=v2
[2 body] ServiceVersion=v1
[3 body] ServiceVersion=v2
[4 body] ServiceVersion=v1
[5 body] ServiceVersion=v2
[6 body] ServiceVersion=v2
[7 body] ServiceVersion=v2
[8 body] ServiceVersion=v2
[9 body] ServiceVersion=v2
{{< /text >}}

### Enabling mTLS

Due to the changes to the application itself required to enable security in gRPC, Istio's traditional method of
automatically detecting mTLS support is unreliable. For this reason, the initial release requires explicitly enabling
mTLS on both the client and server.

To enable client-side mTLS, apply a `DestinationRule` with `tls` settings:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: echo-mtls
  namespace: echo-grpc
spec:
  host: echo.echo-grpc.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

Now an attempt to call the server that is not yet configured for mTLS will fail.

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'
Handling connection for 17171
ERROR:
Code: Unknown
Message: 1/1 requests had errors; first error: rpc error: code = Unavailable desc = all SubConns are in TransientFailure
{{< /text >}}

To enable server-side mTLS, apply a `PeerAuthentication`.

{{< warning >}}
The following policy forces STRICT mTLS for the entire namespace.
{{< /warning >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: echo-mtls
  namespace: echo-grpc
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Requests will start to succeed after applying the policy.

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'
Handling connection for 17171
[0] grpcecho.Echo(&{xds:///echo.echo-grpc.svc.cluster.local:7070 map[] 0  5s false })
[0 body] x-request-id=0
[0 body] Host=echo.echo-grpc.svc.cluster.local:7070
[0 body] content-type=application/grpc
[0 body] user-agent=grpc-go/1.39.1
[0 body] StatusCode=200
[0 body] ServiceVersion=v1
[0 body] ServicePort=17070
[0 body] Cluster=
[0 body] IP=10.68.1.18
[0 body] IstioVersion=
[0 body] Echo=
[0 body] Hostname=echo-v1-7cf5b76586-z5p8l
{{< /text >}}

## Limitations

The initial release comes with several limitations that may be fixed in a future version:

* Auto-mTLS isn't supported, and permissive mode isn't supported. Instead we require explicit mTLS configuration with
  `STRICT` on the server and `ISTIO_MUTUAL` on the client. Envoy can be used during the migration to `STRICT`.
* `grpc.Serve(listener)` or `grpc.Dial("xds:///...")` called before the bootstrap is written or xDS proxy is ready can
  cause a failure. `holdApplicationUntilProxyStarts` can be used to work around this, or the application can be more
  robust to these failures.
* If the xDS-enabled gRPC server uses mTLS then you will need to make sure your health checks can work around this.
  Either a separate port should be used, or your health-checking client needs a way to get the proper client
  certificates.
* The implementation of xDS in gRPC does not match Envoys. Certain behaviors may be different, and some features may
  be missing. The [feature status for gRPC](https://github.com/grpc/grpc/blob/master/doc/grpc_xds_features.md) provides more detail. Make sure to test that any Istio
  configuration actually applies on your proxyless gRPC apps.

## Performance

### Experiment Setup

* Using Fortio, a Go-based load testing app
    * Slightly modified, to support gRPC’s XDS features (PR)
* Resources:
    * GKE 1.20 cluster with 3 `e2-standard-16` nodes (16 CPUs + 64 GB memory each)
    * Fortio client and server apps: 1.5 vCPU, 1000 MiB memory
    * Sidecar (istio-agent and possibly Envoy proxy): 1 vCPU, 512 MiB memory
* Workload types tested:
    * Baseline: regular gRPC with no Envoy proxy or Proxyless xDS in use
    * Envoy: standard istio-agent + Envoy proxy sidecar
    * Proxyless: gRPC using the xDS gRPC server implementation and `xds:///` resolver on the client
    * mTLS enabled/disabled via `PeerAuthentication` and `DestinationRule`

### Latency

{{< image width="80%" link="./latencies_p50.svg" caption="p50 latency comparison chart" >}}
{{< image width="80%" link="./latencies_p99.svg" caption="p99 latency comparison chart" >}}

There is a marginal increase in latency when using the proxyless gRPC resolvers. Compared to Envoy this is a massive
improvement that still allows for advanced traffic management features and mTLS.

### istio-proxy container resource usage

|                     | Client `mCPU` | Client Memory (`MiB`) | Server `mCPU` | Server Memory (`MiB`) |
|---------------------|-------------|---------------------|-------------|----------------------|
| Envoy Plaintext     | 320.44      | 66.93               | 243.78      | 64.91                |
| Envoy mTLS          | 340.87      | 66.76               | 309.82      | 64.82                |
| Proxyless Plaintext | 0.72        | 23.54               | 0.84        | 24.31                |
| Proxyless mTLS      | 0.73        | 25.05               | 0.78        | 25.43                |

Even though we still require an agent, the agent uses less than 0.1% of a full vCPU, and only 25 MiB of memory,
which is less than half of what running Envoy requires.

These metrics don’t include additional resource usage by gRPC in the application container,
but serve to demonstrate the resource usage impact of the istio-agent when running in this mode.
