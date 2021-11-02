---
title: Change Notes
linktitle: 1.12.0
subtitle: Minor Release
description: Istio 1.12.0 release notes.
publishdate: 2021-11-16
release: 1.12.0
weight: 10
aliases:
    - /news/announcing-1.12.0
---

{{< warning >}}
This is an automatically generated rough draft of the release notes and has not yet been reviewed.
{{< /warning >}}

# Changes


- '**Improved** TCP probes now working as expected: When using TCP probes with older versions of istio the check was always successful, even if the application didn't open the port.'
 ([details]( https://istio.io/latest/docs/ops/configuration/mesh/app-health-check/)) 

- **Improved** Analyzers reports output to match the naming scheme expected by the API, i.e `<ns>/<name>` instead of `<name>.<ns>`.
  ([Issue #35405](https://github.com/istio/istio/issues/35405))

- **Improved** destination rule ca analyzer to show exact error line when using `istioctl analyze`,
otherwise it will show the first line of its yaml configuration chunk.
  

- **Improved** support for headless services with undeclared protocols to not required specific `Host` headers.
  ([Issue #34679](https://github.com/istio/istio/issues/34679))

- **Improved** performance of TLS certificate Secret watches to reduce memory usage.
  ([Issue #35231](https://github.com/istio/istio/issues/35231))

- **Updated** `istioctl x create-remote-secret` and `istioctl x remote-clusters` to the top level command, out of
experimental.
  

- **Updated** `istioctl tag set default` to control which revision handles Istio resource validation. The revision indicated
through the default tag will also win leader elections and assume singleton cluster responsibilities.
  

- **Added** support to istiod to notice cacerts file changes via the `AUTO_RELOAD_PLUGIN_CERTS` env var.
  ([Issue #31522](https://github.com/istio/istio/issues/31522))

- **Added** `VERTIFY_CERT_AT_CLIENT` environmental variable to istiod. Setting `VERTIFY_CERT_AT_CLIENT` to `true` will verify server certificates using the OS CA certificates when not using a `DestinationRule` `caCertificates` field [Issue #33472](github.com/istio/istio/issues/33472).  ([Issue #33472](https://github.com/istio/istio/issues/33472))

- **Added** `istioctl install` will now do `IST0139` analysis on webhooks.
  ([Issue #33537](https://github.com/istio/istio/issues/33537))

- **Added** labels on pod level for istio-operator and istiod. 
  ([Issue #33879](https://github.com/istio/istio/issues/33879))

- **Added** validator for empty regex match.
  ([Issue #34065](https://github.com/istio/istio/issues/34065))

- **Added** `istioctl x remote-clusters` to list the remote clusters each `istiod` instance has API Server credentials for,
and the service registry sync status of each cluster.
  ([Issue #33799](https://github.com/istio/istio/issues/33799))

- **Added** Auto mTLS support for workload level peer authentication. You no longer need to configure destination rule when servers are configured with workload level peer authentication policy. This can be disabled by setting ENABLE_AUTO_MTLS_CHECK_POLICIES to "false". 
  ([Issue #33809](https://github.com/istio/istio/issues/33809))

- **Added** the pod alias `po` for users to use `istioctl x describe po`, which is consistent with `kubectl` command.
  

- **Added** support for sourceip hash loadbalancing in TCP proxy.
  ([Issue #33558](https://github.com/istio/istio/issues/33558))

- **Added** support for envoy to track active connections during drain and quit if active connections become zero 
          instead of waiting for entire drain duration. This is disabled by default and can be enabled by setting
          `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` to true.  ([Issue #34855](https://github.com/istio/istio/issues/34855))

- **Added** pilot service annotations on helm chart
  ([Issue #35229](https://github.com/istio/istio/issues/35229))

- **Added** support for `trafficPolicy.loadBalancer.consistentHash` in `DestinationRule` for proxyless gRPC clients.
  

- **Added** the support of integrating with GKE workload certificates.
  ([Issue #35385](https://github.com/istio/istio/issues/35385))

- **Added** the ability for users to specify Envoy's LOGICAL_DNS as a connection type for a cluster using 'DNS_ROUND_ROBIN' in ServiceEntry.
  ([Issue #35475](https://github.com/istio/istio/issues/35475))

- **Added** precheck now detects usage of Alpha Annotations.
  

- **Added** `istioctl operator dump` now supports the `watchedNamespaces` argument to specify the namespaces the operator controller watches.
  ([Issue #35485](https://github.com/istio/istio/issues/35485))

- **Added** Support arm64 api for operator, add nodeAffinity arm64 expression.
  

- **Added** `failoverPriority` loadbalancing traffic policy, which allows users to set an ordered list of labels used to sort endpoints to do priority based load balancing.  

- **Added** support for creating mirrored QUIC listeners for non-passthrough HTTPS listeners at gateways
  

- **Added** support for the `v1alpha2` version of the [gateway-api](https://gateway-api.org/).
  

- **Added** values to the Istio Gateway Helm charts for configuring annotations on the ServiceAccount.  Can be used to enable [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) on AWS EKS.
  

- **Added** experimental support for the `cluster.local` host behavior as defined by
the Kubernetes Multi-Cluster Services (MCS) spec. This feature is off by default,
but can be enabled by setting the following flags in Istio:
`ENABLE_MCS_CLUSTER_LOCAL`, `ENABLE_MCS_HOST` and `ENABLE_MCS_SERVICE_DISCOVERY`.
When enabled, requests to the `cluster.local` host will be routed to only those
endpoints residing within the same cluster as the client.  ([Issue #35424](https://github.com/istio/istio/issues/35424))

- **Added** support for Istio WasmPlugin API
  



- **Fixed** a bug where specifying same port number with different protocols (TCP and UDP)
lead to incorrect merging and rendered erroneous manifest.  ([Issue #33841](https://github.com/istio/istio/issues/33841))

- **Fixed** Gateway API xRoute does not forward the traffic to that backend when weight `0`.
  ([Issue #34129](https://github.com/istio/istio/issues/34129))

- **Fixed** an issue in which ADS would hang due to the wrong `syncCh` size being provided.
  

- **Fixed** Istioctl does not wait on CNI DaemonSet update
  ([Issue #34811](https://github.com/istio/istio/issues/34811))

- **Fixed** `istioctl operator` subcommands now support remote URLs specified in the `--manifests` argument.
  ([Issue #34896](https://github.com/istio/istio/issues/34896))

- **Fixed** `istioctl admin log` format.
  

- **Fixed** No Permission to list ServiceExport from remote clusters in primary cluster.
  ([Issue #35068](https://github.com/istio/istio/issues/35068))

- **Fixed** the EnvoyExternalAuthorizationHttpProvider to match HTTP headers in a case-insensitive way.  ([Issue #35220](https://github.com/istio/istio/issues/35220))

- **Fixed** APP pods (such as httpbin) can not be created if not using 'istio-system' as the Istio namespace to install Istio at the first time. And `istioctl install`, `istioctl tag set` and `istioctl tag generate` will be influenced. For example, user can set a specified namespace (`mesh-1` as an example) to install Istio via `istioctl install --set profile=demo --set values.global.istioNamespace=mesh-1 -y`
  ([Issue #35539](https://github.com/istio/istio/issues/35539))

- **Fixed** `istioctl bug-report` has the extra default system namespaces displayed when `--exclude` is not set.
  

- **Fixed** the release tar URL by adding the patch version.
  

- **Fixed** an issue with WorkloadGroup and WorkloadEntry labeling of canonical revision.
  ([Issue #34395](https://github.com/istio/istio/issues/34395))

- **Fixed** and issue causing Ingress resources with the same name but different namespaces from conflicting.
  ([Issue #31833](https://github.com/istio/istio/issues/31833))

- **Fixed** an issue in istioctl bug-report where --context and --kubeconfig were not being honored  ([Issue #35574](https://github.com/istio/istio/issues/35574))





# Security update


