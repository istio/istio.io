---
title: Large Scale Security Policy Performance Tests
subtitle: The effect of security policies on latency of requests
description: The effect of security policies on latency of requests.
publishdate: 2020-09-15
attribution: "Michael Eizaguirre (Google), Yangmin Zhu (Google), Carolyn Hu (Google)"
keywords: [test,security policy,performance]
---

## Overview

Istio has a wide range of security policies which can be easily configured into systems of services. As the number of applied policies increases, it is important to understand the relationship of latency, memory usage, and CPU usage of the system.

This blog post goes over common security policies use cases and how the number of security policies or the number of specific rules in a security policy can affect the overall latency of requests.

## Setup

There are a wide range of security policies and many more combinations of those policies. We will go over 6 of the most commonly used test cases.

The following test cases are run in an environment which consists of a [Fortio](https://fortio.org/) client sending requests to a Fortio server, with a baseline of no Envoy sidecars deployed. The following data was gathered by using the [Istio performance benchmarking tool](https://github.com/istio/tools/tree/master/perf/benchmark).
{{< image width="55%" ratio="45.34%"
    link="istio_setup.svg"
    alt="Environment setup"
    >}}

In these test cases, requests either do not match any rules or match only the very last rule in the security policies. This ensures that the RBAC filter is applied to all policy rules, and never matches a policy rule before before viewing all the policies. Even though this is not necessarily what will happen in your own system, this policy setup provides data for the worst possible performance of each test case.

## Test cases

1. Mutual TLS STRICT vs plaintext.

1. A single authorization policy with a variable number of principal rules as well as a `PeerAuthentication` policy. The principal rule is dependent on the `PeerAuthentication` policy being applied to the system.

1. A single authorization policy with a variable number of `requestPrincipal` rules as well as a `RequestAuthentication` policy. The `requestPrincipal` is dependent on the `RequestAuthentication` policy being applied to the system.

1. A single authorization policy with a variable number of `paths` vs `sourceIP` rules.

1. A variable number of authorization policies consisting of a single path or `sourceIP` rule.

1. A single `RequestAuthentication` policy with variable number of `JWTRules` rules.

## Data

The y-axis of each test is the latency in milliseconds, and the x-axis is the number of concurrent connections. The x-axis of each graph consists of 3 data points that represent a small load (qps=100, conn=8), medium load (qps=500, conn=32), and large load (qps=1000, conn=64).

{{< tabset category-name="platform" >}}

{{< tab name="MTLS vs plainText" category-value="one" >}}
{{< image width="90%" ratio="45.34%"
    link="mtls_plaintext.svg"
    alt="MTLS vs plaintext"
    caption=""
    >}}
The difference of latency between MTLS mode STRICT and plaintext is very small in lower loads. As the `qps` and `conn` increase, the latency of requests with MTLS STRICT increases. The additional latency increased in larger loads is minimal compared to that of the increase from having no sidecars to having sidecars in the plaintext.
{{< /tab >}}

{{< tab name="AuthZ mTLS SourcePrincipals" category-value="two" >}}
{{< image width="90%" ratio="45.34%"
    link="AuthZ_var_principals.svg"
    alt="Authorization policy variable number of principals"
    caption=""
    >}}

For Authorization policies with 10 vs 1000 principal rules, the latency increase of 10 principal rules compared to no policies is greater than the latency increase of 1000 principals compared to 10 principals.
{{< /tab >}}

{{< tab name="AuthZ JWT RequestPrincipal" category-value="three" >}}
{{< image width="90%" ratio="45.34%"
    link="AuthZ_var_requestPrincipals.svg"
    alt="Authorization policy with variable principals"
    caption=""
    >}}
For Authorization policies with a variable number of `requestPrincipal` rules, the latency increase of 10 `requestPrincipal` rules compared to no policies is nearly the same as the latency increase of 1000 `requestPrincipal` rules compared to 10 `requestPrincipal` rules.
{{< /tab >}}

{{< tab name="AuthZ sourceIP" category-value="four" >}}
{{< image width="90%" ratio="45.34%"
    link="AuthZ_var_sourceIP.svg"
    alt="Authorization policy with variable `sourceIP` rules"
    caption=""
    >}}
The latency increase of a single `AuthZ` policy with 10 `sourceIP` rules is not proportional to the latency increase of a single `AuthZ` policy with 1000 `sourceIP` rules compared to the system with sidecar and no policies.

{{< image width="90%" ratio="45.34%"
    link="AuthZ_paths_vs_sourceIP.svg"
    alt="Authorization policy with both paths and `sourceIP`"
    caption=""
    >}}
The latency increase of a variable number of `sourceIP` rules is marginally greater than that of path rules.
{{< /tab >}}

{{< tab name="AuthZ paths" category-value="five" >}}
{{< image width="90%" ratio="45.34%"
    link="AuthZ_var_paths.svg"
    alt="Authorization policy with variable number of paths"
    caption=""
    >}}
The latency increase of a single `AuthZ` policy with 10 path rules is not proportional to the latency increase of a single `AuthZ` policy with 1000 path rules compared to the system with sidecar and no policies. This trend is similar to that of `sourceIP` rules.
{{< image width="90%" ratio="45.34%"
    link="AuthZ_paths_vs_sourceIP.svg"
    alt="Authorization policy with both paths and `sourceIP`"
    caption=""
    >}}
The latency of a variable number of paths rules is marginally lesser than that of `sourceIP` rules.
{{< /tab >}}

{{< tab name="RequestAuthN JWT Issuer" category-value="six" >}}
{{< image width="90%" ratio="45.34%"
    link="RequestAuthN_jwks.svg"
    alt="Request Authentication with variable number of JWT issuers"
    caption=""
    >}}
The latency of a single JWT issuer is comparable to that of no policies, but as the number of JWT issuers increase, the latency increases disproportionately.
{{< /tab >}}

{{< tab name="Variable AuthZ" category-value="seven" >}}
To test how the number of Authorization policies affect runtime, the tests can be broken into two cases:

1. Every Authorization policy has a single `sourceIP` rule.

1. Every Authorization policy has a single path rule.

{{< image width="90%" ratio="45.34%"
    link="AuthZ_var_policies_sourceIP.svg"
    alt="Authorization policy with variable number of policies, with `sourceIP` rule"
    caption=""
    >}}
{{< image width="90%" ratio="45.34%"
    link="AuthZ_var_policies_paths.svg"
    alt="Authorization policy with variable number of policies, with path rule"
    caption=""
    >}}
The overall trends of both graphs are similar. This is consistent to the paths vs `sourceIP` data, which showed that the latency is marginally greater for `sourceIP` rules than that of path rules.
{{< /tab >}}

{{< /tabset >}}

## Conclusion

- In general, adding security policies does not add relatively high overhead to the system. The policies that add the most latency include:

    1. Authorization policy with `JWTRules` rules.

    1. Authorization policy with `requestPrincipal` rules.

    1. Authorization policy with principals rules.

- In lower loads (requests with lower qps and conn) the difference in latency for most policies is minimal.

- Envoy proxy sidecars increase latency more than most policies, even if the policies are large.

- The latency increase of extremely large policies is relatively similar to the latency increase of adding Envoy proxy sidecars compared to that of no sidecars.

- Two different tests determined that the `sourceIP` rule is marginally slower than a path rule.

If you are interested in creating your own large scale security policies and running performance tests with them, see the [performance benchmarking tool README](https://github.com/istio/tools/tree/master/perf/benchmark/security/generate_policies).

If you are interested in reading more about the security policies tests, see [our design doc](https://docs.google.com/document/d/1ZP9eQ_2EJEG12xnfsoo7125FDN38r62iqY1PUn9Dz-0/edit?usp=sharing). If you don't already have access, you can [join the Istio team drive](/get-involved/).
