---
title: Behavioral Changes in 1.1
description: Major changes in behavior, both backward compatibility breaking and non, in Istio 1.1.
weight: 15
icon: setup

---

# Major Behavioral Changes in Istio 1.1

## Installer Changes

### Changes with upgrade impact

- Istio’s CRDs have been placed into their own Helm chart `istio-init`.  This prevents loss of custom resource data, facilitates the upgrade process, and enables the Istio project to evolve beyond a Helm-based installation.  The upgrade documentation (**TODO link**) provides the proper procedure for upgrading from Istio 1.0.6 to Istio 1.1.0.  Please follow these instructions **carefully and precisely** when upgrading.  If certmanager is desired, it is mandatory to use the `--set certmanager=true` flag when installing both istio-init and istio charts with either `template` or `tiller` installation modes.
- The 1.0 istio-remote chart used for multicluster VPN **(TODO link**) and multicluster split horizon(**TODO link**) remote cluster installation has been consolidated into the Istio chart.  To generate an equivalent istio-remote chart, use the flag `--set global.istioRemote=true`.
- Addons are no longer be exposed via separate load balancers.  Instead addons are exposed via the ingressgateway.  To expose an addon via the ingressgateway, please follow the instructions **(TODO FIX LINK** <https://preliminary.istio.io/docs/tasks/telemetry/gateways/>).
- The built-in Istio statsd collector has been removed.  Istio retains the capability of integrating with your own statsd collector.
- Grafana, Prometheus, Kiali, and Jaeger passwords and username are now stored in Kubernetes secrets **(TODO link)** instead of command line configuration options, values.yaml, or configmaps for improved security and compliance.
- Jaeger has replaced Zipkin as the default tracing system.
- The “ingress” series of options for configuring a Kubernetes Ingress have been removed.  Kubernetes Ingress is still functional using the ‘gateways.istio-ingressateway’, by following these instructions **(TODO link)**.

### Changes without upgrade impact

- Several installation profiles have been added to simplify the installation process.  To use this feature, read the Helm Installation Instructions **(TODO link)** and select a profile from the document tabs.  This feature enables a better user experience by simplifying the installation process for severeal well-known patterns.
- The envoy proxy access log defaults have been changed such that no access logging occurs by default.  Access logging can be re-enabled by using the installation flag `--set global.proxy.accessLogFile=”/dev/stdout”`.  Enabling access logs significantly decreases performance.
- The integrated packages Certmanager, Grafana, Jaeger, Kiali, and Prometheus have been revised to their latest versions improving performance, reliability, and features.
- The CoreDNS component has been added to Istio to enable multicluster gateway **(TODO link)** and split-horizon **(TODO link)** DNS discovery.  This change enables applications to use Istio’s CoreDNS proxy to resolve remote cluster service names in multiple Kubernetes clusters transparently.
- Resource limits have been added to Envoy to improve performance and reliability.  **TODO link to Mandar's PR or perf tuning guide and blog**
- Envoy lightstep has been integrated into the installation.
- Horizontal auto-scaling maximums for all components have been increased from one to five.  This enables better performance in clusters with more services with minimal impact in clusters with less services.

Additional installation commentary can be found in: [https://github.com/istio/istio.io/pull/3704](https://github.com/istio/istio.io/pull/3704).

## Networking Changes

### Outbound traffic policy now defaults to ALLOW_ANY 

Traffic to unknown ports will be forwarded as-is. Traffic to known ports (e.g., port 80) will be matched with one of the services in the system and forwarded accordingly

### Revised destination rule resolution for Envoy sidecars

During sidecar routing to a service, destination rules for the target service in the same namespace as the sidecar will take precedence, followed by destination rules in the service’s namespace, and finally followed by destination rules in other namespaces if applicable.

### Gateway resources should be stored in the same namespace as the gateway workload

We recommend storing gateway resources in the same namespace as the gateway workload (e.g., istio-system in case of istio-ingressgateway).  When referring to gateway resources in virtual services, use the namespace/name format instead of using name.namespace.svc.cluster.local

### Service Graph is now deprecated in favor of Kiali

The Service Graph component has now been deprecated in favor of the Kiali Monitoring tool.  For more information about Kiali and its visualization capabilities please refer to the [Telemetry section](https://istio.io/docs/tasks/telemetry/) of the documentation and the [Kiali website](https://www.kiali.io/).

If you would like to see new features as they are being developed please check out the [Kiali service mesh observability project](https://www.youtube.com/channel/UCcm2NzDN_UCZKk2yYmOpc5w) on YouTube where you will find the end of sprint demos.

### Egress Gateway is now disabled by default

The optional egress gateway is disabled by default.  It is enabled in the demo profile for users to explore but disabled in all other profiles by default.  If you need to control and secure your outbound traffic through the egress gateway, you will need to enable `gateways.istio-egressgateway.enabled=true` manually in any of the non-demo profiles. 

## Policy & Telemetry Changes

### Policy & Quota checks are now disabled by default

Istio-policy is disabled by default.  It is enabled in the demo profile for users to explore but disabled in all other profiles.  This change is only for Istio-policy not for istio-telemetry.

In order to re-enable policy checking, run helm template with `--set global.disablePolicyChecks=false` and re-apply the configuration.

## Security Changes - TODO duderino reformat this section

- Envoy is able to get key/cert via SecretDiscoveryService (SDS) API instead of secret volume mount. It is an opt-in feature and the tutorial can be found [here](https://preliminary.istio.io/docs/tasks/security/auth-sds/). To upgrade from the secret volume mount to the SDS scheme, the users can upgrade the control plane with the “SDS” feature enabled. **Caveat**: the transition will take impact to all workloads at the same time. We do not suggest doing this upgrade on clusters running in production.
- You can configure a TLS or mutual TLS ingress gateway to fetch credentials from the ingress gateway agent via secret discovery service (SDS). This is an opt-in feature. To upgrade an existing ingress gateway controller, follow the task [here](https://preliminary.istio.io/docs/tasks/traffic-management/secure-ingress/sds/).
- Citadel agent can integrate with Vault as PKI. This empowers users to plug their Vault CAs into Istio (i.e., bring your own CA). This is opt-in feature and the tutorial can be found [here](https://preliminary.istio.io/docs/tasks/security/vault-ca/).
- Istio supports customizable organization or cluster specific trust domains in the identities. By default, the trust domain is “cluster.local” and it can be configured.
- Replaced the RbacConfig resource with the ClusterRbacConfig resource to implement the correct cluster scope. See [Migrating RbacConfig to ClusterRbacConfig](https://preliminary.istio.io/docs/setup/kubernetes/upgrade/#migrating-from-rbacconfig-to-clusterrbacconfig) for migration instructions.
- Authorization now enforces on TCP services in addition to HTTP and gRPC services. The tutorial can be found [here](https://preliminary.istio.io/docs/tasks/security/authz-tcp/). 
- You can now authorize based on `groups` claim or any list typed claims in JWT. The tutorial can be found [here](https://preliminary.istio.io/docs/tasks/security/rbac-groups/). 