---
title: "Extending Istio 1.5 with Gloo API Gateway"
subtitle: Integrating with Istio 1.5 SDS at the edge for API Gateway functionality
description: Gloo integrates with Istio 1.5 SDS to provide API Gateway functionality at the edge.
publishdate: 2020-04-21
attribution: "Christian Posta (Solo.io)"
keywords: [istio, sds, mTLS, edge, ingress, gloo, solo.io]
draft: true
---

[Gloo is an open-source API Gateway](https://docs.solo.io/gloo/latest/) built on Envoy Proxy that highly complements a service mesh like Istio with edge capabilities, such as [request/response transformations](https://docs.solo.io/gloo/latest/guides/traffic_management/request_processing/transformations/), [direct-response actions](https://docs.solo.io/gloo/latest/guides/traffic_management/request_processing/direct_response_action/), and [Open API Spec/Swagger and gRPC discovery](https://docs.solo.io/gloo/latest/installation/advanced_configuration/fds_mode/). This benefits you by having API Gateway capabilities at the edge of your mesh (or multiple clusters of a mesh) without manually adding support for this into the Istio ingress gateway using Lua, etc. [Gloo Enterprise](https://www.solo.io/products/gloo/) supports more sophisticated security edge requirements, such as [OIDC authentication](https://docs.solo.io/gloo/latest/guides/security/auth/oauth/), [OPA authorization](https://docs.solo.io/gloo/latest/guides/security/auth/opa/), [Web Application Fire walling (WAF)](https://docs.solo.io/gloo/latest/guides/security/waf/), rate limiting and others. There is also a custom-auth framework for building your own edge security protocols (common ones like non-standard security handshakes, HMAC, etc) into the ext-auth server that Gloo uses. A lot of Gloo users put Gloo at the edge for North/South concerns and [integrate with Istio for East-West traffic management](https://www.solo.io/blog/using-gloo-as-an-ingress-gateway-with-istio-and-mtls-updated-for-istio-1-1/).

In the [Istio 1.5 release](/news/releases/1.5.x/announcing-1.5/), many architectural considerations have changed with how folks deploy and manage Istio. The way mTLS is implemented in Istio has also changed a bit. For example, In the past, Istio would create secrets for each service account and mount those in for the workloads to assume their identity. That has now changed. Istio uses [Envoy’s SDS](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret) to [distribute workload identity/certificates by default with Istio 1.5 now](/docs/concepts/security/#pki).

Gloo [has had integration with Istio SDS](https://docs.solo.io/gloo/latest/guides/integrations/service_mesh/gloo_istio_mtls/) for a while now while giving the option to use SDS (more secure) or the secret mounting approach, but now with the Istio 1.5 change, we’ve updated the Gloo functionality to show how to get [Gloo working with Istio 1.5](https://docs.solo.io/gloo/latest/guides/integrations/service_mesh/gloo_istio_mtls/#istio-15x).

There are two different approaches to doing this. The supported way for Gloo OSS is to load an Istio proxy (and istio-agent) to connect to the mesh and pull down the certificates and allow upstreams to use that. This requires, unfortunately, running another Envoy next to the Gloo proxy (also based on Envoy) that does nothing other than pull down certificates. [This is the recommended way to accomplish integration with SDS](/blog/2020/proxy-cert/) and Istio. However, for Gloo Enterprise, we feel we can do better. We have a custom build of the istio-agent that can serve SDS for Istio without the need for running an entirely separate Envoy. This slims down the deployment of the Gloo API Gateway when integrating with Istio.

See a quick demo of integrating open-source Gloo with Istio 1.5:

<iframe width="560" height="315" src="https://www.youtube.com/embed/zhUR3HgeFSg" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
