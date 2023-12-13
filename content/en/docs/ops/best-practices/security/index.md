---
title: Security Best Practices
description: Best practices for securing applications using Istio.
force_inline_toc: true
weight: 30
owner: istio/wg-security-maintainers
test: n/a
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

## Authorization policies

Istio [authorization](/docs/concepts/security/#authorization) plays a critical part in Istio security.
It takes effort to configure the correct authorization policies to best protect your clusters.
It is important to understand the implications of these configurations as Istio cannot determine the proper authorization for all users.
Please follow this section in its entirety.

### Safer Authorization Policy Patterns

#### Use default-deny patterns

We recommend you define your Istio authorization policies following the default-deny pattern to enhance your cluster's security posture.
The default-deny authorization pattern means your system denies all requests by default, and you define the conditions in which the requests are allowed.
In case you miss some conditions, traffic will be unexpectedly denied, instead of traffic being unexpectedly allowed.
The latter typically being a security incident while the former may result in a poor user experience, a service outage or will not match your SLO/SLA.

For example, in the [authorization for HTTP traffic task](/docs/tasks/security/authorization/authz-http/),
the authorization policy named `allow-nothing` makes sure all traffic is denied by default.
From there, other authorization policies allow traffic based on specific conditions.

#### Use `ALLOW-with-positive-matching` and `DENY-with-negative-match` patterns

Use the `ALLOW-with-positive-matching` or `DENY-with-negative-matching` patterns whenever possible. These authorization policy
patterns are safer because the worst result in the case of policy mismatch is an unexpected 403 rejection instead of
an authorization policy bypass.

The `ALLOW-with-positive-matching` pattern is to use the `ALLOW` action only with **positive** matching fields (e.g. `paths`, `values`)
and do not use any of the **negative** matching fields (e.g. `notPaths`, `notValues`).

The `DENY-with-negative-matching` pattern is to use the `DENY` action only with **negative** matching fields (e.g. `notPaths`, `notValues`)
and do not use any of the **positive** matching fields (e.g. `paths`, `values`).

For example, the authorization policy below uses the `ALLOW-with-positive-matching` pattern to allow requests to path `/public`:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths: ["/public"]
{{< /text >}}

The above policy explicitly lists the allowed path (`/public`). This means the request path must be exactly the same as
`/public` to allow the request. Any other requests will be rejected by default eliminating the risk
of unknown normalization behavior causing policy bypass.

The following is an example using the `DENY-with-negative-matching` pattern to achieve the same result:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo
spec:
  action: DENY
  rules:
  - to:
    - operation:
        notPaths: ["/public"]
{{< /text >}}

### Understand path normalization in authorization policy

The enforcement point for authorization policies is the Envoy proxy instead of the usual resource access point in the backend application. A policy mismatch happens when the Envoy proxy and the backend application interpret the request
differently.

A mismatch can lead to either unexpected rejection or a policy bypass. The latter is usually a security incident that needs to be
fixed immediately, and it's also why we need path normalization in the authorization policy.

For example, consider an authorization policy to reject requests with path `/data/secret`. A request with path `/data//secret` will
not be rejected because it does not match the path defined in the authorization policy due to the extra forward slash `/` in the path.

The request goes through and later the backend application returns the same response that it returns for the path `/data/secret`
because the backend application normalizes the path `/data//secret` to `/data/secret` as it considers the double forward slashes
`//` equivalent to a single forward slash `/`.

In this example, the policy enforcement point (Envoy proxy) had a different understanding of the path than the resource access
point (backend application). The different understanding caused the mismatch and subsequently the bypass of the authorization policy.

This becomes a complicated problem because of the following factors:

* Lack of a clear standard for the normalization.

* Backends and frameworks in different layers have their own special normalization.

* Applications can even have arbitrary normalizations for their own use cases.

Istio authorization policy implements built-in support of various basic normalization options to help you to better address
the problem:

* Refer to [Guideline on configuring the path normalization option](/docs/ops/best-practices/security/#guideline-on-configuring-the-path-normalization-option)
  to understand which normalization options you may want to use.

* Refer to [Customize your system on path normalization](/docs/ops/best-practices/security/#customize-your-system-on-path-normalization) to
  understand the detail of each normalization option.

* Refer to [Mitigation for unsupported normalization](/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization) for
  alternative solutions in case you need any unsupported normalization options.

### Guideline on configuring the path normalization option

#### Case 1: You do not need normalization at all

Before diving into the details of configuring normalization, you should first make sure that normalizations are needed.

You do not need normalization if you don't use authorization policies or if your authorization policies don't
use any `path` fields.

You may not need normalization if all your authorization policies follow the [safer authorization pattern](/docs/ops/best-practices/security/#safer-authorization-policy-patterns)
which, in the worst case, results in unexpected rejection instead of policy bypass.

#### Case 2: You need normalization but not sure which normalization option to use

You need normalization but you have no idea of which option to use. The safest choice is the strictest normalization option
that provides the maximum level of normalization in the authorization policy.

This is often the case due to the fact that complicated multi-layered systems make it practically impossible to figure
out what normalization is actually happening to a request beyond the enforcement point.

You could use a less strict normalization option if it already satisfies your requirements and you are sure of its implications.

For either option, make sure you write both positive and negative tests specifically for your requirements to verify the
normalization is working as expected. The tests are useful in catching potential bypass issues caused by a misunderstanding
or incomplete knowledge of the normalization happening to your request.

Refer to [Customize your system on path normalization](/docs/ops/best-practices/security/#customize-your-system-on-path-normalization)
for more details on configuring the normalization option.

#### Case 3: You need an unsupported normalization option

If you need a specific normalization option that is not supported by Istio yet, please follow
[Mitigation for unsupported normalization](/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization)
for customized normalization support or create a feature request for the Istio community.

### Customize your system on path normalization

Istio authorization policies can be based on the URL paths in the HTTP request.
[Path normalization (a.k.a., URI normalization)](https://en.wikipedia.org/wiki/URI_normalization) modifies and standardizes the incoming requests' paths,
so that the normalized paths can be processed in a standard way.
Syntactically different paths may be equivalent after path normalization.

Istio supports the following normalization schemes on the request paths,
before evaluating against the authorization policies and routing the requests:

| Option | Description | Example |
| --- | --- | --- |
| `NONE` | No normalization is done. Anything received by Envoy will be forwarded exactly as-is to any backend service. | `../%2Fa../b` is evaluated by the authorization policies and sent to your service. |
| `BASE` | This is currently the option used in the *default* installation of Istio. This applies the [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path) option on Envoy proxies, which follows [RFC 3986](https://tools.ietf.org/html/rfc3986) with extra normalization to convert backslashes to forward slashes. | `/a/../b` is normalized to `/b`. `\da` is normalized to `/da`. |
| `MERGE_SLASHES` | Slashes are merged after the _BASE_ normalization. | `/a//b` is normalized to `/a/b`. |
| `DECODE_AND_MERGE_SLASHES` | The most strict setting when you allow all traffic by default. This setting is recommended, with the caveat that you will need to thoroughly test your authorization policies routes. [Percent-encoded](https://tools.ietf.org/html/rfc3986#section-2.1) slash and backslash characters (`%2F`, `%2f`, `%5C` and `%5c`) are decoded to `/` or `\`, before the `MERGE_SLASHES` normalization. | `/a%2fb` is normalized to `/a/b`. |

{{< tip >}}
The configuration is specified via the [`pathNormalization`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
field in the [mesh config](/docs/reference/config/istio.mesh.v1alpha1/).
{{< /tip >}}

To emphasize, the normalization algorithms are conducted in the following order:

1. Percent-decode `%2F`, `%2f`, `%5C` and `%5c`.
1. The [RFC 3986](https://tools.ietf.org/html/rfc3986) and other normalization implemented by the [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path) option in Envoy.
1. Merge slashes

{{< warning >}}
While these normalization options represent recommendations from HTTP standards and common industry practices,
applications may interpret a URL in any way it chooses to. When using denial policies, ensure that you understand how your application behaves.
{{< /warning >}}

For a complete list of supported normalizations, please refer to [authorization policy normalization](/docs/reference/config/security/normalization/).

#### Examples of configuration

Ensuring Envoy normalizes request paths to match your backend services' expectation is critical to the security of your system.
The following examples can be used as reference for you to configure your system.
The normalized URL paths, or the original URL paths if _NONE_ is selected, will be:

1. Used to check against the authorization policies
1. Forwarded to the backend application

| Your application... | Choose... |
| --- | --- |
| Relies on the proxy to do normalization | `BASE`, `MERGE_SLASHES` or `DECODE_AND_MERGE_SLASHES` |
| Normalizes request paths based on [RFC 3986](https://tools.ietf.org/html/rfc3986) and does not merge slashes | `BASE` |
| Normalizes request paths based on [RFC 3986](https://tools.ietf.org/html/rfc3986), merges slashes but does not decode [percent-encoded](https://tools.ietf.org/html/rfc3986#section-2.1) slashes | `MERGE_SLASHES` |
| Normalizes request paths based on [RFC 3986](https://tools.ietf.org/html/rfc3986), decodes [percent-encoded](https://tools.ietf.org/html/rfc3986#section-2.1) slashes and merges slashes | `DECODE_AND_MERGE_SLASHES` |
| Processes request paths in a way that is incompatible with [RFC 3986](https://tools.ietf.org/html/rfc3986) | `NONE` |

#### How to configure

You can use `istioctl` to update the [mesh config](/docs/reference/config/istio.mesh.v1alpha1/):

{{< text bash >}}
$ istioctl upgrade --set meshConfig.pathNormalization.normalization=DECODE_AND_MERGE_SLASHES
{{< /text >}}

or by altering your operator overrides file

{{< text bash >}}
$ cat <<EOF > iop.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    pathNormalization:
      normalization: DECODE_AND_MERGE_SLASHES
EOF
$ istioctl install -f iop.yaml
{{< /text >}}

Alternatively, if you want to directly edit the mesh config,
you can add the [`pathNormalization`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
to the [mesh config](/docs/reference/config/istio.mesh.v1alpha1/), which is the `istio-<REVISION_ID>` configmap in the `istio-system` namespace.
For example, if you choose the `DECODE_AND_MERGE_SLASHES` option, you modify the mesh config as the following:

{{< text yaml >}}
apiVersion: v1
  data:
    mesh: |-
      ...
      pathNormalization:
        normalization: DECODE_AND_MERGE_SLASHES
      ...
{{< /text >}}

### Mitigation for unsupported normalization

This section describes various mitigations for unsupported normalization. These could be useful when you need a specific
normalization that is not supported by Istio.

Please make sure you understand the mitigation thoroughly and use it carefully as some mitigations rely on things that are
out the scope of Istio and also not supported by Istio.

#### Custom normalization logic

You can apply custom normalization logic using the WASM or Lua filter. It is recommended to use the WASM filter because
it's officially supported and also used by Istio. You could use the Lua filter for a quick proof-of-concept DEMO but we do
not recommend using the Lua filter in production because it is not supported by Istio.

##### Example custom normalization (case normalization)

In some environments, it may be useful to have paths in authorization policies compared in a case insensitive manner.
For example, treating `https://myurl/get` and `https://myurl/GeT` as equivalent.

In those cases, the `EnvoyFilter` shown below can be used to insert a Lua filter to normalize the path to lower case.
This filter will change both the path used for comparison and the path presented to the application.

{{< text syntax=yaml snip_id=ingress_case_insensitive_envoy_filter >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ingress-case-insensitive
  namespace: istio-system
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_FIRST
      value:
        name: envoy.lua
        typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
            inlineCode: |
              function envoy_on_request(request_handle)
                local path = request_handle:headers():get(":path")
                request_handle:headers():replace(":path", string.lower(path))
              end
{{< /text >}}

#### Writing Host Match Policies

Istio generates hostnames for both the hostname itself and all matching ports. For instance, a virtual service or Gateway
for a host of `example.com` generates a config matching `example.com` and `example.com:*`. However, exact match authorization
policies only match the exact string given for the `hosts` or `notHosts` fields.

[Authorization policy rules](/docs/reference/config/security/authorization-policy/#Rule) matching hosts should be written using
prefix matches instead of exact matches.  For example, for an `AuthorizationPolicy` matching the Envoy configuration generated
for a hostname of `example.com`, you would use `hosts: ["example.com", "example.com:*"]` as shown in the below `AuthorizationPolicy`.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - to:
    - operation:
        hosts: ["example.com", "example.com:*"]
{{< /text >}}

Additionally, the `host` and `notHosts` fields should generally only be used on gateway for external traffic entering the mesh
and not on sidecars for traffic within the mesh. This is because the sidecar on server side (where the authorization policy is enforced)
does not use the `Host` header when redirecting the request to the application. This makes the `host` and `notHost` meaningless
on sidecar because a client could reach out to the application using explicit IP address and arbitrary `Host` header instead of
the service name.

If you really need to enforce access control based on the `Host` header on sidecars for any reason, follow with the [default-deny patterns](/docs/ops/best-practices/security/#use-default-deny-patterns)
which would reject the request if the client uses an arbitrary `Host` header.

#### Specialized Web Application Firewall (WAF)

Many specialized Web Application Firewall (WAF) products provide additional normalization options. They can be deployed in
front of the Istio ingress gateway to normalize requests entering the mesh. The authorization policy will then be enforced
on the normalized requests. Please refer to your specific WAF product for configuring the normalization options.

#### Feature request to Istio

If you believe Istio should officially support a specific normalization, you can follow the [reporting a vulnerability](/docs/releases/security-vulnerabilities/#reporting-a-vulnerability)
page to send a feature request about the specific normalization to the Istio Product Security Work Group for initial evaluation.

Please do not open any issues in public without first contacting the Istio Product Security Work Group because the
issue might be considered a security vulnerability that needs to be fixed in private.

If the Istio Product Security Work Group evaluates the feature request as not a security vulnerability, an issue will
be opened in public for further discussions of the feature request.

### Known limitations

This section lists known limitations of the authorization policy.

#### Server-first TCP protocols are not supported

Server-first TCP protocols mean the server application will send the first bytes right after accepting the TCP connection
before receiving any data from the client.

Currently, the authorization policy only supports enforcing access control on inbound traffic and not the outbound traffic.

It also does not support server-first TCP protocols because the first bytes are sent by the server application even before
it received any data from the client. In this case, the initial first bytes sent by the server are returned to the client
directly without going through the access control check of the authorization policy.

You should not use the authorization policy if the first bytes sent by the server-first TCP protocols include any sensitive
data that need to be protected by proper authorization.

You could still use the authorization policy in this case if the first bytes does not include any sensitive data, for example,
the first bytes are used for negotiating the connection with data that are publicly accessible to any clients. The authorization
policy will work as usual for the following requests sent by the client after the first bytes.

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

Depending on the actual implementation, changes to network policy may not affect existing connections in the Istio proxies.
You may need to restart the Istio proxies after applying the policy so that existing connections will be closed and
new connections will be subject to the new policy.

### Securing egress traffic

A common misconception is that options like [`outboundTrafficPolicy: REGISTRY_ONLY`](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services) acts as a security policy preventing all access to undeclared services.
However, this is not a strong security boundary as mentioned above, and should be considered best-effort.

While this is useful to prevent accidental dependencies, if you want to secure egress traffic, and enforce all outbound traffic goes through a proxy, you should instead rely on an [Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/).
When combined with a [Network Policy](/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies), you can enforce all traffic, or some subset, goes through the egress gateway.
This ensures that even if a client accidentally or maliciously bypasses their sidecar, the request will be blocked.

## Configure TLS verification in Destination Rule when using TLS origination

Istio offers the ability to [originate TLS](/docs/tasks/traffic-management/egress/egress-tls-origination/) from a sidecar proxy or gateway.
This enables applications that send plaintext HTTP traffic to be transparently "upgraded" to HTTPS.

Care must be taken when configuring the `DestinationRule`'s `tls` setting to specify the `caCertificates`, `subjectAltNames`, and `sni` fields.
The `caCertificate` can be automatically set from the system's certificate store's CA certificate by enabling the environment variable `VERIFY_CERTIFICATE_AT_CLIENT=true` on Istiod.
If the Operating System CA certificate being automatically used is only desired for select host(s), the environment variable `VERIFY_CERTIFICATE_AT_CLIENT=false` on Istiod, `caCertificates` can be set to `system` in the desired `DestinationRule`(s).
Specifying the `caCertificates` in a `DestinationRule` will take priority and the OS CA Cert will not be used.
By default, egress traffic does not send SNI during the TLS handshake.
SNI must be set in the `DestinationRule` to ensure the host properly handle the request.

{{< warning >}}
In order to verify the server's certificate it is important that both `caCertificates` and `subjectAltNames` be set.

Verification of the certificate presented by the server against a CA is not sufficient, as the Subject Alternative Names must also be validated.

If `VERIFY_CERTIFICATE_AT_CLIENT` is set, but `subjectAltNames` is not set then you are not verifying all credentials.

If no CA certificate is being used, `subjectAltNames` will not be used regardless of it being set or not.
{{< /warning >}}

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
      subjectAltNames:
      - "google.com"
      sni: "google.com"
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

### Explicitly disable all the sensitive http host under relaxed SNI host matching

It is reasonable to use multiple `Gateway`s to define mutual TLS and simple TLS on different hosts.
For example, use mutual TLS for SNI host `admin.example.com` and simple TLS for SNI host `*.example.com`.

{{< text yaml >}}
kind: Gateway
metadata:
  name: guestgateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*.example.com"
    tls:
      mode: SIMPLE
---
kind: Gateway
metadata:
  name: admingateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - admin.example.com
    tls:
      mode: MUTUAL
{{< /text >}}

If the above is necessary, it's highly recommended to explicitly disable the http host `admin.example.com` in the `VirtualService` that attaches to `*.example.com`. The reason is that currently the underlying [envoy proxy does not require](https://github.com/envoyproxy/envoy/issues/6767) the http 1 header `Host` or the http 2 pseudo header `:authority` following the SNI constraints, an attacker can reuse the guest-SNI TLS connection to access admin `VirtualService`. The http response code 421 is designed for this `Host` SNI mismatch and can be used to fulfill the disable.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: disable-sensitive
spec:
  hosts:
  - "admin.example.com"
  gateways:
  - guestgateway
  http:
  - match:
    - uri:
        prefix: /
    fault:
      abort:
        percentage:
          value: 100
        httpStatus: 421
    route:
    - destination:
        port:
          number: 8000
        host: dest.default.cluster.local
{{< /text >}}

## Protocol detection

Istio will [automatically determine the protocol](/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection) of traffic it sees.
To avoid accidental or intentional miss detection, which may result in unexpected traffic behavior, it is recommended to [explicitly declare the protocol](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection) where possible.

## CNI

In order to transparently capture all traffic, Istio relies on `iptables` rules configured by the `istio-init` `initContainer`.
This adds a [requirement](/docs/ops/deployment/requirements/) for the `NET_ADMIN` and `NET_RAW` [capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container) to be available to the pod.

To reduce privileges granted to pods, Istio offers a [CNI plugin](/docs/setup/additional-setup/cni/) which removes this requirement.

## Use hardened docker images

Istio's default docker images, including those run by the control plane, gateway, and sidecar proxies, are based on `ubuntu`.
This provides various tools such as `bash` and `curl`, which trades off convenience for an increase attack surface.

Istio also offers a smaller image based on [distroless images](/docs/ops/configuration/security/harden-docker-images/) that reduces the dependencies in the image.

{{< warning >}}
Distroless images are currently an alpha feature.
{{< /warning >}}

## Release and security policy

In order to ensure your cluster has the latest security patches for known vulnerabilities, it is important to stay on the latest patch release of Istio and ensure that you are on a [supported release](/docs/releases/supported-releases) that is still receiving security patches.

## Detect invalid configurations

While Istio provides validation of resources when they are created, these checks cannot catch all issues preventing configuration being distributed in the mesh.
This could result in applying a policy that is unexpectedly ignored, leading to unexpected results.

* Run `istioctl analyze` before or after applying configuration to ensure it is valid.
* Monitor the control plane for rejected configurations. These are exposed by the `pilot_total_xds_rejects` metric, in addition to logs.
* Test your configuration to ensure it gives the expected results.
  For a security policy, it is useful to run positive and negative tests to ensure you do not accidentally restrict too much or too few traffic.

## Avoid alpha and experimental features

All Istio features and APIs are assigned a [feature status](/docs/releases/feature-stages/), defining its stability, deprecation policy, and security policy.

Because alpha and experimental features do not have as strong security guarantees, it is recommended to avoid them whenever possible.
Security issues found in these features may not be fixed immediately or otherwise not follow our standard [security vulnerability](/docs/releases/security-vulnerabilities/) process.

To determine the feature status of features in use in your cluster, consult the [Istio features](/docs/releases/feature-stages/#istio-features) list.

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

## Configure a limit on downstream connections

By default, Istio (and Envoy) have no limit on the number of downstream connections. This can be exploited by a malicious actor (see [security bulletin 2020-007](/news/security/istio-security-2020-007/)). To work around you this, you must configure an appropriate connection limit for your environment.

### Configure `global_downstream_max_connections` value

The following configuration can be supplied during installation:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "overload.global_downstream_max_connections": "100000"
{{< /text >}}
