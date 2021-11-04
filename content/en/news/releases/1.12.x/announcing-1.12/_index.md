---
title: Announcing Istio 1.12
linktitle: 1.12
subtitle: Major Update
description: Istio 1.12 release announcement.
publishdate: 2021-11-16
release: 1.12.0
skip_list: true
aliases:
    - /news/announcing-1.12
    - /news/announcing-1.12.0
---

We are pleased to announce the release of Istio 1.12!

{{< relnote >}}

This is the last release of 2021. We would like to thank the entire Istio community.

{{< tip >}}
Istio 1.12.0 is officially supported on Kubernetes versions `1.18.0` to `1.22.0`.
{{< /tip >}}

Here are some of the highlights of the release:

## WasmPlugin
Provides a mechanism to extend the functionality provided by the Istio proxy through WebAssembly filters.

## Using Official Helm Repository
Istio is now using an official Helm repository. More information can be found [here](istio.io/latest/docs/setup/install/helm/#prerequisites).

## Global HTTP Retry Policy

## Topology Aware Load Balancing
Support general prioritized load balancing specified by a set of general labels.

## Telemetry API

## Verify Certificate At Client
`VERIFY_CERTIFICATE_AT_CLIENT` is `false` by default for Istio 1.12.
Unless specified, `caCertificates` in `DestinationRule`s do not get used to validate certificates for `SIMPLE` and `MUTUAL` TLS. Enabling the environmental variable `VERIFY_CERTIFICATE_AT_CLIENT=true` in istiod will automatically set `caCertificates` from the system's certificate store's CA certificate. If the system's CA certificate is only desired for select hosts, set the environmental variable `VERIFY_CERTIFICATE_AT_CLIENT=false` in istiod and set `caCertificates` as `system` for those select hosts' `DestinationRule`. Specifying the `caCertificate` in a `DestinationRule` will take priority and the system CA certificate will not be used.
