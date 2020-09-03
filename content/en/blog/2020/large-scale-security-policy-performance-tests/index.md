---
title: Large Scale Security Policy Perfomance Tests
subtitle: How does having security policies effect latency of requests
description: How does having security policies effect latency of request.
publishdate: 2020-09-02
attribution: "Michael Eizaguirre (Google)"
keywords: [test,security policy]
---

## Overview

Istio has a wide range of Security policies which can be easily configured into systems of services. As the number of Security policies being applied increases it is important to understand how much latency these Security policies are adding to the system.

This blog post goes over common Security policies use cases and how the number of Security policies or the number of specific rules in a Security policy can effect the overall latency of requests.

## Setup

There are a wide range of Security policies and many more combinations of those policies. We will go over 6 test cases that were determined to be more common/valuable to users.

The following test cases are run in an environment which consists of a fortio client sending requests to a fortio server, except of that of a the baseline which has no Envoy sidecars deployed.
{{< image width="55%" ratio="45.34%"
    link="./istio_setup.svg"
    caption="Environment setup"
    >}}

The policies that are applied are made to not match with any request or only the very last rule, this makes sure that the RBAC filter has to go through all the rules and policies. This forces the system to never short circuit (when the RBAC filter matches before viewing all the policies). Even though this is not necessarily what will happen in your individual system, this gives data of the worst possible performance of each test case.

## Test cases

1. MTLS STRICT vs plaintext.

1. A single authorization policy with a variable number of principal rules. For the RBAC filter to activate this rule a peer authentication policy must also be applied to the system.

1. Authorization policy with a variable number of `requestPrincipal` rules. For the RBAC filter to activate this rule a `requestAuthentication` policy must also be applied to the system.

1. A single authorization policy with variable number of paths vs `sourceIP` rules

1. Variable number of authorization policies each consisting of a single paths or `sourceIP` rule

1. A single `requestAuthentication` policy with variable number of `JWTRules` rules

## Data

The y axis of each test is the latency in milliseconds, and the x axis is the number of concurrent connections. The x axis of each graph will consist of 3 data points. This first being a small load (qps=100, conn=8), the second a medium load (qps=500, conn=32), and the third being a large load (qps=1000, conn=64)

{{< tabset category-name="platform" >}}

{{< tab name="MTLS vs plainText" category-value="one" >}}
{{< image width="90%" ratio="45.34%"
    link="./mtls_plaintext.svg"
    alt="MTLS vs plaintext"
    caption=""
    >}}
The difference between MTLS mode STRICT vs that of plaintext is very small in lower loads and as the number of qps and conn increase the latency of requests with MTLS STRICT rise higher. The additional latency increased in larger loads is minimal compared to that of the increase from having no sidecars vs having sidecars in the plaintext.
{{< /tab >}}

{{< tab name="AuthZ principals" category-value="two" >}}
{{< image width="90%" ratio="45.34%"
    link="./AuthZ_var_principals.svg"
    alt="Authorization policy variable number of principals"
    caption=""
    >}}

For Authorization policies with 10 vs 1000 principal rules, there is a larger increase of latency of having 10 principal rules compared to having no policies than there is with the increase of latency of having 1000 principals compared to having 10 principals.
{{< /tab >}}

{{< tab name="AuthZ requestPrincipals" category-value="three" >}}
{{< image width="90%" ratio="45.34%"
    link="./AuthZ_var_requestPrincipals.svg"
    alt="Authorization policy with variable principals"
    caption=""
    >}}
    For Authorization policies with a variable number of `requestPrincipal` rules, the difference of latency of having 10 `requestPrincipal` rules compared to no policies is nearly the same as the increase of having 1000 `requestPrincipal` rules compared to having 10 `requestPrincipal` rules.
{{< /tab >}}

{{< tab name="paths vs sourceIP" category-value="four" >}}
To compare the latency of having a variable number of path vs `sourceIP` the data is broken into 3 graphs.
The first showing the data of having a variable number of `sourceIP` rules in a single Authorization policy as well as the baseline.
{{< image width="90%" ratio="45.34%"
    link="./AuthZ_var_sourceIP.svg"
    alt="Authorization policy with variable `sourceIP` rules"
    caption=""
    >}}
The second graph shows the data of having a variable number of path rules in a single Authorization policy as well as the baseline.
{{< image width="90%" ratio="45.34%"
    link="./AuthZ_var_paths.svg"
    alt="Authorization policy with variable number of paths"
    caption=""
    >}}
And finally the last graph shows the data of having a variable number of `sourceIP` rules vs path rules without the baseline.
{{< image width="90%" ratio="45.34%"
    link="./AuthZ_paths_vs_sourceIP.svg"
    alt="Authorization policy with both paths and `sourceIP`"
    caption=""
    >}}
Having `sourceIP` rules increases the latency of request in a minimal amount compared to that of path rules.
{{< /tab >}}

{{< tab name="JWTRule" category-value="five" >}}
{{< image width="90%" ratio="45.34%"
    link="./RequestAuthN_jwks.svg"
    alt="Request Authentication with variable number of `JWTRules`"
    caption=""
    >}}
Having a single `JWTRule` applied to the system is comparable to that of having no policies applied, but as the number of `JWTRules` increase the latency increases disproportionately larger.
{{< /tab >}}

{{< tab name="Variable Authorization policies" category-value="six" >}}
To test how the number of Authorization policies effect runtime the tests can be broken into two cases.

- 1: Every Authorization policy has a single `sourceIP` rule.

- 2: Every Authorization policy has a single path rule.

{{< image width="90%" ratio="45.34%"
    link="./AuthZ_var_policies_sourceIP.svg"
    alt="Authorization policy with variable number of policies, with `sourceIP` rule"
    caption=""
    >}}
{{< image width="90%" ratio="45.34%"
    link="./AuthZ_var_policies_paths.svg"
    alt="Authorization policy with variable number of policies, with path rule"
    caption=""
    >}}
The overall trend of both graphs are similar. This is consistent to the paths vs `sourceIP` data which showed that the latency is marginally higher for `sourceIP` rules compared to that of path rules.
{{< /tab >}}

{{< /tabset >}}

## Conclusion

- In general adding security policies does not add relatively high overhead to the system, with the heavier policies being:

    1. Authorization policy with `JWTRules` rules.

    1. Authorization policy with `requestPrincipal` rules.

    1. Authorization policy with principals rules.

- In lower loads (requests with lower qps and conn) the difference in latency for most policies is minimal.

- That having sidecars creates a larger increase in latency than most policies even if those policies being applied are large.

- The overhead of having these extremely large policies add is relatively similar to the increase of latency of adding the Envoy proxies compared to that of no Envoy proxies.

- In a more particular note, with two different tests it was determined that the `sourceIP` rule is marginally slower than that of a path rule.

If you are interested in creating your own large scale Security policies and running performance tests with them see [README](https://github.com/istio/tools/tree/master/perf/benchmark/security/generate_policies)
