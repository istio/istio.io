---
title: "gRPC Proxyless Service Mesh"
description: Introduction to Istio support for gRPC's proxyless service mesh features.
publishdate: 2021-08-15
attribution: "Steven Landow (Google)"
---

## Background

Recent releases of gRPC have added support for consuming [`xDS`](https://blog.envoyproxy.io/the-universal-data-plane-api-d15cec7a)
directly. This means you can get many of the benefits of a service mesh, without the overhead of a sidecar proxy. 

Istio 1.11 adds experimental support for basic service discovery, some `VirtualService` based traffic policy, and
mutual TLS.

## Supported Features

The current implementation of the xDS APIs within gRPC is limited in some areas compared to Envoy. The following
features should work, although this is not an exhaustive list and other features may have partial functionality:

* Basic service discovery. Your gRPC service can reach other pods and virtual machines registered in the mesh.
* [`DestinationRule`](/docs/reference/config/networking/destination-rule/):
  * Subsets: Your gRPC service can split traffic based on label selectors to different groups of instances. 
  * The only Istio `loadBalancer` currently supported is `ROUND_ROBIN`, `consistentHash` will be added in the future.
  * `tls` settings are restricted to `DISABLE` or `ISTIO_MUTUAL`. Other modes will be treated as `DISABLE`.
* [`VirtualService`](/docs/reference/config/networking/virtual-service/):
  * Header match and URI match in the format `/ServiceName/RPCName`
  * Override destination host and subset.
  * Weighted traffic shifting.
  * // TODO does timeout work (I think we must set MaxStreamDuration for this to work – I don' think we do today)
  * // TODO do retries work
  * // TODO do faults work
  * // TODO does mirror work
  * // tested not working: rewrite
* [`PeerAuthentication`](/docs/reference/config/security/peer_authentication/):
  * Only `DISABLE` and `STRICT` are supported. Other modes will be treated as `DSIABLE`.
  * Support for auto-mTLS may exist in a future release.

## Architecture Overview

{{< image width="80%" link="./architecture.svg" caption="Diagram of how gRPC services communicate with the istiod." >}}

Although this doesn't use a proxy for data plane communication, it still requires an agent for initialization and
communication with the control-plane. First, the agent generates a [bootstrap file](https://github.com/grpc/proposal/blob/master/A27-xds-global-load-balancing.md#xdsclient-and-bootstrap-file).
This tells the `gRPC` library how to connect to `istiod`, where it can find certificates for data plane communication,
and what metadata to send to the control plane. Next, the agent acts as an `xDS` proxy, connecting and authenticating
with `istiod` on the application's behalf. Finally, the agent fetches and rotates certificates used in data plane
traffic. 

## Changes to application code

> Here we cover gRPC’s XDS support in Go. See <insert link> for information on other languages. 

To enable the xDS features in gRPC, there are a handful of required changes your application must make. Your gRPC
version should be at least `1.39.0`. 

### In the client

The following side-effect import will register the xDS resolvers and balancers within gRPC. It should be added in your
`main` package or in the same package calling `grpc.Dial`.   

{{< text go >}}
_ "google.golang.org/grpc/xds"
{{< /text >}}

When creating a gRPC connection the URL must use the `xds:///` scheme. For now, the fully-qualified domain name must be
used to reach your service.

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

To support server-side configurations, such as mTLS, there are a couple of modifications that must be made here as well.

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

### In the environment

// TODO talk about env vars required for bootstrap, security, etc; describe what Istio sets for you.

### In your Kubernetes Deployment

Assuming your application code is compatible, the Pod simply needs the annotation “inject.istio.io/templates: grpc-agent”. 
This will set the environment variables described above, and add the agent sidecar discussed in Architecture Overview.

// TODO Hold app till proxy (adding to template, won't be in 1.11.0)


## Example

// TODO prereqs 

Istio has a pre-made application, echo, that already supports both serverside and clientside proxyless gRPC. 
In this guide we will deploy echo with the grpc-agent template and demonstrate some supported traffic policies
and how to enable mTLS. 

### Deploy the application

Create an injection-enabled namespace `echo-grpc`. Next deploy two instances of the `echo` app as well as the Service.

{{< text bash >}}
$ kubectl create namespace echo-grpc
$ kubectl label namespace echo-grpc istio-injection=enabled
$ kubectl -n echo-grpc apply -f samples/echo/echo-grpc.yaml
{{< /text >}}

Make sure the two pods are running:

{{< text bash >}}
$ kubectl -n echo-grpc get pods
NAME                       READY   STATUS    RESTARTS   AGE
echo-v1-69d6d96cb7-gpcpd   2/2     Running   0          58s
echo-v2-5c6cbf6dc7-dfhcb   2/2     Running   0          58s
{{< /text >}}

Make some requests from the application
Firt, port-forward `17171` to one of the Pods. This port is a non-XDS backed gRPC server that allows making requests from the port-forwarded Pod. 

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

### Creating subsets with destination rule
// TODO 

### Traffic shifting
// TODO 

### Enabling mTLS
// TODO 

## Limitations

// TODO 
Strict mtls only - must configure in both DR and PA. No plain TLS yet.
Only Round Robin load balancing (gRPC supports ring-hash, we don’t yet)
Application-code gotchas:
Health-checks: With mTLS enabled, your healthcheck must use a different port or it will fail authentication. 
Race between grpc.Serve(listener), and bootstrap getting created by agent. 
Hold app till proxy (adding to template, won't be in 1.11.0)

## Performance

## Experiment Setup

* Using Fortio, a Go-based load testing app
  * Slightly modified, to support gRPC’s XDS features (PR)
* Resources:
  * GKE 1.20 cluster with 3 e2-standard-16 nodes (16cpu + 64GB RAM each)
  * Fortio client/server app: 1500m CPU, 1000Mi memory
  * Sidecar (istio-agent and/or Envoy proxy) : 1cpu, 512Mi ram
* Workload types tested:
  * Baseline: regular gRPC with no Envoy proxy or Proxyless xDS in use
  * Envoy: standard istio-agent + Envoy proxy sidecar
  * Proxyless: gRPC using the xDS gRPC server implementation and xds:/// resolver on the client
  * mTLS enabled/disabled via PeerAuthentication and DestinationRule

## Results

### Latency

{{< image width="40%" link="./latencies_p50.svg" caption="p50 latency comparison chart" >}}
{{< image width="40%" link="./latencies_p99.svg" caption="p99 latency comparison chart" >}}

There is a marginal increase in latency when using the proxyless gRPC resolvers. Compared to Envoy however, this is a
massive improvement that still allows for advanced traffic management features and mTLS.

### istio-proxy container resource usage

|                     | Client mCPU | Client Memory (MiB) | Server mCPU | Server Memory (mCPU) |
|---------------------|-------------|---------------------|-------------|----------------------|
| Envoy Plaintext     | 320.44      | 66.93               | 243.78      | 64.91                |
| Envoy mTLS          | 340.87      | 66.76               | 309.82      | 64.82                |
| Proxyless Plaintext | 0.72        | 23.54               | 0.84        | 24.31                |
| Proxyless mTLS      | 0.73        | 25.05               | 0.78        | 25.43                |

Even though we still require an agent, the agent uses less than 0.1% of a full vCPU, and only 25 MiB of memory, which is less than half of what it requires to run Envoy. 

These metrics don’t include additional resource usage by gRPC in the application container, but serve to demonstrate the resource usage impact of the istio-agent when running in this mode. 

