---
title: "Introducing centralized east-west traffic gateway"
description: "A light-weighted way to achieve layer 7 load balancing functions without per-pod sidecars."
publishdate: 2022-09-11T07:00:00-06:00
attribution: "Shaokai Zhang (Alibaba Cloud), Chengyun Lu(Alibaba Cloud), Yang Song(Alibaba Cloud)"
keywords: [centralized sidecars]
---

This document introduces a way to use advanced L7 load balancing features of sidecars without installing one with each pod.

## Background & introduction

The east-west traffic in Istio is carried by envoy sidecars, which are deployed in every pod
together with the application containers. Sidecars provide the functions of secure
service-to-service communication, load balancing for various protocols, flexible traffic control
and policy, and complete tracing. 

However, there are also a few disadvantages of sidecars. First of all, deploying one sidecar to
every pod can be resource-consuming and introduce complexity, especially when the number of pods is
huge. Not only must those resources be provisioned to the sidecars, but also the control plane to
manage the sidecar and to push configurations can be demanding. Second, a query needs to go through
two sidecars, one in the source pod and the other one in the destination pod,  in order to reach
the destination. For delay-sensitive applications, sometimes, the extra time spent in the sidecars
is not acceptable. 

We noted that, for the majority of our HTTP applications, many of the rich features in sidecars are
unused. That's why we want to propose a light-weighted way to serve east-west traffic without the
drawbacks mentioned in the previous paragraph. Our focus is on the HTTP applications that do not
require advanced security features, like mTLS. 

We propose the centralized east-west traffic gateway, which moves the sidecars and the
functionalities they carry to nodes that are dedicated for sidecars, and no application container
shares those nodes. This way, no modifications are required on the nodes, and we can save on the
resources and the delay. In addition, we can decouple the network management from application
management,  and also avoid the resource competition between application and networking. However,
because we move the sidecars out of the nodes of applications, we at the same time lose some of the
security and tracing abilities provided by the original sidecars. Our observation is that the
majority of our applications do not require those features.

## Detailed Proposal
The basic idea of a centralized east-west traffic gateway is shown below. 

{{< image width="100%"
    link="centralized_gw.png"
    caption="Centralized east-west traffic gateway"
    >}}

Because we move the sidecars out of the nodes running applications, we give up a few service mesh features in exchange for simple deployment, fewer resources, better delay, decoupling management, and zero resource competition. The main tradeoff is application may get involved in handling SSL key management if mTLS is needed. The centralized gateway can provide server authentication and authorization, but cannot provide the same security scrutiny for the clients by default. The second feature that is missing is the end-to-end tracing. Since the gateway sits in the middle, it can only trace the traffic after it arrives at the gateway, and miss the tracing on the application nodes. We figure the gateway side's tracing is enough for most our use cases, but for applications need additional node tracing information, it can be inconvenient.

The centralized east-west traffic gateway can still provide comparable features to the original sidecar mode in:

1. automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic
2. Fine-grained control of traffic behavior with rich routing rules, retries, failovers, and fault injection
3. A pluggable policy layer and configuration API supporting access controls, rate limits and quotas
The features below are provided, but with limitations compared to the original sidecar:
1. Secure communication in a cluster with server-side TLS encryption, strong identity-based server-side authentication and authorization.
2. Automatic metrics, logs, and traces for all traffic going through the gateway.


The gateway can be implemented by envoy、nginx、or commercial load balancers provided by cloud providers.  To save the resources further, the sidecar can be deployed together with ingress
gateway.

In this document, we demonstrate how to create a centralized east-west traffic gateway with Envoy:
1. First, create an InternalGateway service, which deploys envoys using router mode.
2. Create a Gateway target: Associate  the InternalGateway with the selector. The listening port can be configured through Service target.
3. Create a VirtualService target: associate the Gateway and Service created in the last step.
4. Configure DNS: for all the traffic targeting a service, redirect the traffic to the InternalGateway service. 
Examples are demonstrated in the next section.

##Related works

There are a few proposals in the istio community to address those problems mentioned above. For example, sidecars can be installed on each node instead of each pod, [1]. This way, the number of sidecars used can be reduced dramatically, and the delay is also reduced because the requests only need to go through one sidecar. However, this approach needs modifications on the node, and it can also cause resource competition between application and sidecars. Moreover, the upgrading and maintenance for the sidecars can be as demanding as the per-pod sidecar mode. 

A recently released document from istio proposes a similar centralized sidecar idea[2]. Since the sidecars are moved out of the nodes, it faces the similar problems we mentioned above: how to accomplish mtls and tracing features that are covered by the local sidecars. The solution used is to install an agent on the node. By this way, it provides comparable features to the original sidecars. However, because an agent is involved, complexity is introduced when the agent is installed or upgraded. It's a great solution for applications where those features are needed. For the HTTP applications that do not require mtls and end-to-end tracing, we still recommend our solution, where no modification on node is required.

##Configuration examples


Next, we introduce how to deploy centralized east-west traffic gateway.
Prerequisite:
1. Only one Gateway can be attached to InternalGateway.
2.  The VirtualService managed by InternalGateway must be attached to the Gateway mention in 1.
3. CoreDNS is required.

Use centralized east-west traffic gateway to handle east-west traffic
Step 1: Deploy InternalGateway service
Step 2: Create HelloWorld service. Note that the port opened must be consistent with the port
opened on the gateway.


```json
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
spec:
  ports:
  - port: 5000
    name: http
  selector:
    app: helloworld
```

Step 3: Create Gateway, and attach it to InternalGateway.
```json
kind: Gateway
metadata:
  name: internalGateway
  namespace: istio-system
spec:
  selector:
    app: internalGateway
  servers:
  - port:
      number: 5000
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

Step 4: Create VirtualService.
```json
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
  namespace: istio-system
spec:
  hosts:
  - "*"
  gateways:
  - internalGateway
  http:
  - match:
    - uri:
        exact: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
```
Step 5: Execute the following command. You should find the IP address of the HelloWorld service changed to the gateway's IP.
```shell
dig helloworld.default.svc.cluster.local
```





| Syntax      | Description |
| ----------- | ----------- |
| Header      | Title       |
| Paragraph   | Text        |
