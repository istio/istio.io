---
title: "Istio publishes results of ztunnel security audit"
description: Passes with flying colors.
publishdate: 2025-04-18
attribution: "Craig Box - Solo.io, for the Istio Product Security Working Group"
keywords: [istio,security,audit,ztunnel,ambient]
---

Istio’s ambient mode splits the service mesh into two distinct layers: Layer 7 processing (the "[waypoint proxy](/docs/ambient/usage/waypoint/)"), which remains powered by the traditional Envoy proxy; and a secure overlay (the "zero-trust tunnel" or "[ztunnel](https://github.com/istio/ztunnel)"), which is [a new codebase](/blog/2023/rust-based-ztunnel/), written from the ground up in Rust.

It is our intention that the ztunnel project be safe to install by default in every Kubernetes cluster, and to that end, it needs to be secure and performant.

We comprehensively demonstrated ztunnel’s performance, showing that it is [the highest-bandwidth way to achieve a secure zero-trust network in Kubernetes](/blog/2025/ambient-performance/) — providing higher TCP throughput than even in-kernel data planes like IPsec and WireGuard — and that its performance has increased by 75% over the past 4 releases.

Today, we are excited to validate the security of ztunnel, publishing [the results of an audit of the codebase](https://ostif.org/wp-content/uploads/2025/04/Istio-Ztunnel-Final-Summary-Report-1.pdf) performed by [Trail of Bits](https://www.trailofbits.com/).

We would like to thank the [Cloud Native Computing Foundation](https://cncf.io/) for funding this work, and [OSTIF for its coordination](https://ostif.org/istio-ztunnel-audit-complete/).

## Scope and overall findings

Istio has been assessed in [2020](/blog/2021/ncc-security-assessment/) and [2023](/blog/2023/ada-logics-security-assessment/), with the Envoy proxy [receiving independent assessment](https://github.com/envoyproxy/envoy#security-audit). The scope of this review was the new code in Istio’s ambient mode, the ztunnel component: specifically code relating to L4 authorization, inbound request proxying, transport-layer security (TLS), and certificate management.

The auditors stated that "the ztunnel codebase is well-written and structured", and had no findings relating to vulnerabilities in the code. Their three findings — one of medium severity and two of informational — refer to recommendations regarding external factors, including software supply chain and testing.

## Resolution and suggested improvements

### Improving dependency management

At the time of the audit, the [cargo audit](https://crates.io/crates/cargo-audit) report for ztunnel’s dependencies showed three versions with current security advisories. There was no suggestion that any vulnerable code paths in ztunnel dependencies could be reached, and the maintainers would regularly update the dependencies to the latest appropriate versions. To streamline this, we’ve [adopted GitHub’s Dependabot](https://github.com/istio/ztunnel/pull/1400) for automated updates.

The auditors pointed out the risk of Rust crates in the dependency chain of ztunnel that either unmaintained or maintained by a single owner. This is a common situation in the Rust ecosystem (and indeed all of open source). We replaced the two crates that were explicitly identified.

### Enhancing test coverage

The Trail of Bits team found that most ztunnel functionality is well-tested, but identified some error-handling code paths which were not covered by [mutation testing](https://mutants.rs/).

We evaluated the suggestions and found that the gaps in coverage highlighted by these results apply to test code, and to code that does not affect correctness.

While mutation testing is useful to identify potential areas to improve, the goal is not to get to a point where a report returns no results. Mutations can trigger no test failures in a number of expected cases, such as behavior with no ‘correct’ result (e.g., log messages), behavior that impacts only performance but not correctness (measured outside of the scope the tooling is aware of), code paths that have multiple ways to achieve the same result, or code used only for testing. Testing and security is a core priority for the Istio team and we are constantly improving our test coverage — using tools like mutation testing and by [developing novel solutions](https://blog.howardjohn.info/posts/ztunnel-testing/) to test proxies.

### Hardening HTTP header parsing

A third-party library was used for parsing the value of the HTTP [Forwarded](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Forwarded) header, which may be present on connections made to ztunnel. The auditors pointed out that header parsing is a common area of attack, and expressed concern that the library we used was not fuzz tested. Given that we were only using this library for parsing one header, we [wrote a custom parser for the Forwarded header](https://github.com/istio/ztunnel/pull/1418), complete with a fuzzing harness to test it.

## Get involved

With strong performance and now validated security, ambient mode continues to advance the state of the art in service mesh design. We encourage you to try it out today.

If you would like to get involved with Istio product security, or become a maintainer, we’d love to have you! Join [our Slack workspace](https://slack.istio.io/) or [our public meetings](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) to raise issues or learn about what we are doing to keep Istio secure.
