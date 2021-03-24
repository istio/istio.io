---
title: Security Best Practices
description: Best practices for securing applications using Istio.
force_inline_toc: true
weight: 30
owner: istio/wg-security-maintainers
test: no
---

Istio security features provide strong identity, powerful policy, transparent TLS encryption, and authentication, authorization and audit (AAA) tools to protect your services and data.
However, to fully make use of these features securely, care must be taken to follow best practices. It is recommended to review the [Security overview](/docs/concepts/security/) before proceeding.

## Mutual TLS

Istio will [automatically](/docs/ops/configuration/traffic-management/tls-configuration/#auto-mtls) encrypt traffic using [Mutual TLS](/docs/concepts/security/#mutual-tls-authentication) whenever possible.
However, proxies are configured in [permissive mode](/docs/concepts/security/#permissive-mode) by default, meaning they will accept both mutual TLS and plaintext traffic.

While this is required for incremental adoption or allowing traffic from clients without an Istio sidecar, it also weakens the security stance.
It is recommended to [migrate to strict mode](/docs/tasks/security/authentication/mtls-migration/) when possible, to enforce that mutual TLS is used.

Mutual TLS alone is not always enough to fully secure traffic, however, as it provides only authentication, not authorization.
This means that anyone with a valid certificate can still access a service.

To fully lock down traffic, it is recommended to configure [authorization policies](/docs/tasks/security/authorization/).
These allow creating fine-grained policies to allow or deny traffic. For example, you can allow only requests from the `app` namespace to access the `hello-world` service.

## Understand traffic capture limitations

The Istio sidecar works by capturing both inbound traffic and outbound traffic and directing them through the sidecar proxy.

However, not *all* traffic is captured:

* Redirection only handles TCP based traffic. Any UDP or ICMP packets will not be captured or modified.
* Inbound capture is disabled on many [ports used by the sidecar](/docs/ops/deployment/requirements/#ports-used-by-istio) as well as port 22. This list can be expanded by options like `traffic.sidecar.istio.io/excludeInboundPorts`.
* Outbound capture may similarly be reduced through settings like `traffic.sidecar.istio.io/excludeOutboundPorts` or other means.

In general, there is minimal security boundary between an application and its sidecar proxy. Configuration of the sidecar is allowed on a per-pod basis, and both run in the same network/process namespace.
As such, the application may have the ability to remove redirection rules and remove, alter, terminate, or replace the sidecar proxy.
This allows a pod to intentionally bypass its sidecar for outbound traffic or intentionally allow inbound traffic to bypass its sidecar.

As a result, it is not secure to rely on all traffic being captured unconditionally by Istio.
Instead, the security boundary is that a client may not bypass *another* pod's sidecar.

For example, if I run the `reviews` application on port `9080`, I can assume that all traffic from the `productpage` application will be captured by the sidecar proxy,
where Istio authentication and authorization policies may apply.

### Defense in depth with `NetworkPolicy`

To further secure traffic, Istio policies can be layered with Kubernetes [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).
This enables a strong [defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) strategy that can be used to further strengthen the security of your mesh.

For example, you may choose to only allow traffic to port `9080` of our `reviews` application.
In the event of a compromised pod or security vulnerability in the cluster, this may limit or stop an attackers progress.

### Securing egress traffic

A common misconception is that options like [`outboundTrafficPolicy: REGISTRY_ONLY`](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services) acts as a security policy preventing all access to undeclared services.
However, this is not a strong security boundary as mentioned above, and should be considered best-effort.

While this is useful to prevent accidental dependencies, if you want to secure egress traffic, and enforce all outbound traffic goes through a proxy, you should instead rely on an [Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/).
When combined with a [Network Policy](/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies), you can enforce all traffic, or some subset, goes through the egress gateway.
This ensures that even if a client accidentally or maliciously bypasses their sidecar, the request will be blocked.

## Configure TLS verification in Destination Rule when using TLS origination

Istio offers the ability to [originate TLS](/docs/tasks/traffic-management/egress/egress-tls-origination/) from the sidecar proxy.
This enables applications that send plaintext HTTP traffic to be transparently "upgraded" to HTTPS.

Care must be taken when configuring the `DestinationRule`'s `tls` setting to specify the `caCertificates` field.
When this is not set, the servers certificate will not be verified.

For example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: google-tls
spec:
  host: google.com
  trafficPolicy:
    tls:
      mode: SIMPLE
      caCertificates: /etc/ssl/certs/ca-certificates.crt
{{< /text >}}

## Gateways

When running an Istio [gateway](/docs/tasks/traffic-management/ingress/), there are a few resources involved:

* `Gateway`s, which controls the ports and TLS settings for the gateway.
* `VirtualService`s, which control the routing logic. These are associated with `Gateway`s by direct reference in the `gateways` field and a mutual agreement on the `hosts` field in the `Gateway` and `VirtualService`.

### Restrict `Gateway` creation privileges

It is recommended to restrict creation of Gateway resources to trusted cluster administrators. This can be achieved by [Kubernetes RBAC policies](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) or tools like [Open Policy Agent](https://www.openpolicyagent.org/).

### Avoid overly broad `hosts` configurations

When possible, avoid overly broad `hosts` settings in `Gateway`.

For example, this configuration will allow any `VirtualService` to bind to the `Gateway`, potentially exposing unexpected domains:

{{< text yaml >}}
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "*"
{{< /text >}}

This should be locked down to allow only specific domains or specific namespaces:

{{< text yaml >}}
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "foo.example.com" # Allow only VirtualServices that are for foo.example.com
  - "default/bar.example.com" # Allow only VirtualServices in the default namespace that are for bar.example.com
  - "route-namespace/*" # Allow only VirtualServices in the route-namespace namespace for any host
{{< /text >}}

### Isolate sensitive services

It may be desired to enforce stricter physical isolation for sensitive services. For example, you may want to run a
[dedicated gateway instance](/docs/setup/install/istioctl/#configure-gateways) for a sensitive `payments.example.com`, while utilizing a single
shared gateway instance for less sensitive domains like `blog.example.com` and `store.example.com`.
This can offer a stronger defense-in-depth and help meet certain regulatory compliance guidelines.

## Protocol detection

Istio will [automatically determine the protocol](/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection) of traffic it sees.
To avoid accidental or intentional miss detection, which may result in unexpected traffic behavior, it is recommended to [explicitly declare the protocol](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection) where possible.

## CNI

In order to transparently capture all traffic, Istio relies on `iptables` rules configured by the `istio-init` `initContainer`.
This adds a [requirement](/docs/ops/deployment/requirements/) for the `NET_ADMIN` and `NET_RAW` [capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container) to be available to the pod.

To reduce privileges granted to pods, Istio offers a [CNI plugin](/docs/setup/additional-setup/cni/) which removes this requirement.

{{< warning >}}
The Istio CNI plugin is currently an alpha feature.
{{< /warning >}}

## Use hardened docker images

Istio's default docker images, including those run by the control plane, gateway, and sidecar proxies, are based on `ubuntu`.
This provides various tools such as `bash` and `curl`, which trades off convenience for an increase attack surface.

Istio also offers a smaller image based on [distroless images](/docs/ops/configuration/security/harden-docker-images/) that reduces the dependencies in the image.

{{< warning >}}
Distroless images are currently an alpha feature.
{{< /warning >}}

## Release and security policy

In order to ensure your cluster has the latest security patches for known vulnerabilities, it is important to stay on the latest patch release of Istio and ensure that you are on a [supported release](/about/supported-releases) that is still receiving security patches.

## Detect invalid configurations

While Istio provides validation of resources when they are created, these checks cannot catch all issues preventing configuration being distributed in the mesh.
This could result in applying a policy that is unexpectedly ignored, leading to unexpected results.

* Run `istioctl analyze` before or after applying configuration to ensure it is valid.
* Monitor the control plane for rejected configurations. These are exposed by the `pilot_total_xds_rejects` metric, in addition to logs.
* Test your configuration to ensure it gives the expected results.
  For a security policy, it is useful to run positive and negative tests to ensure you do not accidentally restrict too much or too few traffic.

## Avoid alpha and experimental features

All Istio features and APIs are assigned a [feature status](/about/feature-stages/), defining its stability, deprecation policy, and security policy.

Because alpha and experimental features do not have as strong security guarantees, it is recommended to avoid them whenever possible.
Security issues found in these features may not be fixed immediately or otherwise not follow our standard [security vulnerability](/about/security-vulnerabilities/) process.

To determine the feature status of features in use in your cluster, consult the [Istio features](/about/feature-stages/#istio-features) list.

<!-- In the future, we should document the `istioctl` command to check this when available. -->

## Lock down ports

Istio configures a [variety of ports](/docs/ops/deployment/requirements/#ports-used-by-istio) that may be locked down to improve security.

### Control Plane

Istiod exposes a few unauthenticated plaintext ports for convenience by default. If desired, these can be closed:

* Port `8080` exposes the debug interface, which offers read access to a variety of details about the clusters state.
  This can be disabled by set the environment variable `ENABLE_DEBUG_ON_HTTP=false` on Istiod. Warning: many `istioctl` commands
  depend on this interface and will not function if it is disabled.
* Port `15010` exposes the XDS service over plaintext. This can be disabled by adding the `--grpcAddr=""` flag to the Istiod Deployment.
  Note: highly sensitive services, such as the certificate signing and distribution services, are never served over plaintext.

### Data Plane

The proxy exposes a variety of ports. Exposed externally are port `15090` (telemetry) and port `15021` (health check).
Ports `15020` and `15000` provide debugging endpoints. These are exposed over `localhost` only.
As a result, the applications running in the same pod as the proxy have access; there is no trust boundary between the sidecar and application.

## Configure third party service account tokens

To authenticate with the Istio control plane, the Istio proxy will use a Service Account token. Kubernetes supports two forms of these tokens:

* Third party tokens, which have a scoped audience and expiration.
* First party tokens, which have no expiration and are mounted into all pods.

Because the properties of the first party token are less secure, Istio will default to using third party tokens. However, this feature is not enabled on all Kubernetes platforms.

If you are using `istioctl` to install, support will be automatically detected. This can be done manually as well, and configured by passing `--set values.global.jwtPolicy=third-party-jwt` or `--set values.global.jwtPolicy=first-party-jwt`.

To determine if your cluster supports third party tokens, look for the `TokenRequest` API. If this returns no response, then the feature is not supported:

    {{< text bash >}}
    $ kubectl get --raw /api/v1 | jq '.resources[] | select(.name | index("serviceaccounts/token"))'
    {
        "name": "serviceaccounts/token",
        "singularName": "",
        "namespaced": true,
        "group": "authentication.k8s.io",
        "version": "v1",
        "kind": "TokenRequest",
        "verbs": [
            "create"
        ]
    }
    {{< /text >}}

While most cloud providers support this feature now, many local development tools and custom installations may not prior to Kubernetes 1.20. To enable this feature, please refer to the [Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection).
