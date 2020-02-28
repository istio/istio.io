---
title: Enabling Policy Enforcement (Deprecated)
description: This task shows you how to enable Istio policy enforcement.
weight: 1
keywords: [policies]
---

{{< warning >}}
The mixer policy is deprecated in Istio 1.5 and not recommended for production usage.

* Rate limiting: Consider using [Envoy native rate limiting](https://www.envoyproxy.io/docs/envoy/v1.13.0/intro/arch_overview/other_features/global_rate_limiting)
instead of mixer rate limiting. Istio will add support for native rate limiting API through the Istio extensions API.

* Control headers and routing: Consider using Envoy [`ext_authz` filter](https://www.envoyproxy.io/docs/envoy/v1.13.0/intro/arch_overview/security/ext_authz_filter),
[`lua` filter](https://www.envoyproxy.io/docs/envoy/v1.13.0/configuration/http/http_filters/lua_filter),
or write a filter using the [`Envoy-wasm` sandbox](https://github.com/envoyproxy/envoy-wasm/tree/master/test/extensions/filters/http/wasm/test_data).

* Denials and White/Black Listing: Please use the [Authorization Policy](/docs/concepts/security/#authorization) for
enforcing access control to a workload.
{{< /warning >}}

This task shows you how to enable Istio policy enforcement.

## At install time

In the default Istio installation profile, policy enforcement is disabled. To install Istio
with policy enforcement on, use the `--set values.global.disablePolicyChecks=false` and `--set values.pilot.policy.enabled=true` install option.

Alternatively, you may [install Istio using the demo profile](/docs/setup/getting-started/),
which enables policy checks by default.

## For an existing Istio mesh

1. Check the status of policy enforcement for your mesh.

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: true
    {{< /text >}}

    If policy enforcement is enabled (`disablePolicyChecks` is false), no further action is needed.

1. Update the `istio` configuration to enable policy checks.

    Execute the following command from the root Istio directory:

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.disablePolicyChecks=false --set values.pilot.policy.enabled=true
    configuration "istio" replaced
    {{< /text >}}

1. Validate that policy enforcement is now enabled.

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
    disablePolicyChecks: false
    {{< /text >}}
