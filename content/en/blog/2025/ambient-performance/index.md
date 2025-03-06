---
title: "Istio: The Highest-Performance Solution for Network Security"
description: Ambient mode provides more encrypted throughput than any other project in the Kubernetes ecosystem.
publishdate: 2025-03-06
attribution: "John Howard (Solo.io)"
keywords: [istio,performance,ambient]
---

Encryption in transit is a baseline requirement for almost all Kubernetes environments today, and forms the foundation of a zero-trust security posture.

However, the challenge with security is that it doesn’t come without a cost: it often involves a trade-off between complexity, user experience, and performance.

While most Cloud Native users will know of Istio as a service mesh, providing advanced HTTP functionality, it can also serve the role of providing a foundational network security layer. When we set out to build [Istio's ambient mode](/docs/overview/dataplane-modes/#ambient-mode), these two layers were explicitly split. One of our primary objectives was to be able to offer security (and a long list of [other features](/docs/concepts/)!) without compromise.

With ambient mode, **Istio is now the highest-bandwidth way to achieve a secure zero-trust network in Kubernetes**.

Lets look at some results before we dive into the how and why.

## Putting it to the test

To test performance, we utilized a standard network benchmarking tool, [`iperf`](https://iperf.fr/), to measure the bandwidth of TCP traffic flowing through various popular Kubernetes network security solutions.

{{< image width="60%"
    link="./service-mesh-throughput.svg"
    alt="Performance of various network security solutions."
    >}}

The results speak for themselves: Istio decisively leads the pack as the highest-performing network security solution.
Even more impressive is that this gap continues to grow with each Istio release:

{{< image width="60%"
    link="./ztunnel-performance.svg"
    alt="Performance of Ztunnel, by version."
    >}}

Istio's performance is driven by [ztunnel](https://github.com/istio/ztunnel), a purpose built data plane that is light, fast, and secure.
Over the last 4 releases, the performance of Ztunnel has improved by 75%!

<details>
<summary>Testing Details</summary>

Implementations under test:
* Istio: version 1.26 (prerelease), default settings
* <a href="https://linkerd.io/">Linkerd</a>: version `edge-25.2.2`, default settings
* <a href="https://cilium.io/">Cilium</a>: version `v1.16.6` with `kubeProxyReplacement=true`
  * WireGuard uses `encryption.type=wireguard`
  * IPsec uses `encryption.type=ipsec` with the `GCM-128-AES` algorithm
  * Additionally, both modes were tested with all of the recommendations in <a href="https://docs.cilium.io/en/stable/operations/performance/tuning/">Cilium's tuning guide</a> (including `netkit`, `native` routing mode, BIGTCP (for WireGuard; IPsec is incompatible), BPF masquerade, and BBR bandwidth manager). However, the results were the same with and without these settings applied, so only one result is reported.
* <a href="https://www.tigera.io/project-calico/">Calico</a>: version `v3.29.2` with `calicoNetwork.linuxDataplane=BPF` and `wireguardEnabled=true`
* <a href="https://kindnet.es/">Kindnet</a>: version `v1.8.5` with `--ipsec-overlay=true`.

Some implementations only encrypt traffic cross-node, so are excluded from the same-node tests.

Tests were run on a single `iperf` connection (`iperf3 -c iperf-server`), averaging the result of 3 consecutive runs.
The tests run on 16 core x86 machines running Linux 6.13. For various reasons, no implementation makes use of more than 1-2 cores when handling a single connection, so the core count is not a bottleneck.

Note: many of these implementations support HTTP control.
This test does not exercise this functionality in any implementation.
[Previous posts](/blog/2024/ambient-vs-cilium/) have focused on this area of Istio.

</details>

## Outpacing the Kernel

A very common perception in networking performance is that doing everything in the kernel, either natively or by using eBPF extensions, is the optimal way to achieve high performance.
However, these results show the opposite effect: the user-space implementations - Linkerd and Istio - substantially outperform the kernel implementations. What gives?

One major factor is the speed of innovation.
Performance is not static, and there is a constant progression of micro-optimizations, innovations, and adaptations to hardware improvements.
The kernel serves a large number of use cases, and must evolve deliberately. Even when improvements are made, they can take many years to filter through to real world environments.

In contrast, user-space implementations are able to rapidly change and adapt to their specific targeted use cases, and run on any kernel version.
Ztunnel is a great example of this effect in action, with substantial performance improvements coming in each quarterly release.
A few of the most impactful changes:

* Migrating to `rustls`, a high performance TLS library focusing on safety ([#820](https://github.com/istio/ztunnel/pull/820)).
* Reducing data copying on outbound traffic ([#1012](https://github.com/istio/ztunnel/pull/1012)).
* Dynamically tuning buffer sizes of active connections ([#1024](https://github.com/istio/ztunnel/pull/1024)).
* Optimizing memory copies ([#1169](https://github.com/istio/ztunnel/pull/1169)).
* Moving the cryptography library to `AWS-LC`, a high-performance cryptography library optimized for modern hardware ([#1466](https://github.com/istio/ztunnel/pull/1466)).

Some other factors include:
* WireGuard and Linkerd use the `ChaCha20-Poly1305` encryption algorithm, while Istio uses `AES-GCM`. The latter is highly optimized on modern hardware.
* WireGuard and IPsec operate on individual packets (typically at most 1500 bytes, bound by the network MTU) while TLS operates on records of up to 16KB.

## Try ambient mode today

If you're looking to enhance your cluster's security without compromising on complexity or performance, now is the perfect time to try Istio's ambient mode!

Follow the [getting started guide](/docs/ambient/getting-started/) to learn how easy it is to install and enable.

You can engage with the developers in the #ambient channel on [the Istio Slack](https://slack.istio.io), or use the [discussion forum on GitHub](https://github.com/istio/istio/discussions) for any questions you may have.
