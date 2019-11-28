---
title: Announcing Istio 0.5
linktitle: 0.5
subtitle: Major Update
description: Istio 0.5 announcement.
publishdate: 2018-02-02
release: 0.5.0
aliases:
    - /about/notes/older/0.5
    - /about/notes/0.5/index.html
    - /news/2018/announcing-0.5
    - /news/announcing-0.5
---

In addition to the usual pile of bug fixes and performance improvements, this release includes the new or
updated features detailed below.

{{< relnote >}}

## Networking

- **Incremental Istio Deployment**. (Preview) You can now adopt Istio incrementally, more easily than before, by installing only
the components you want (e.g, Pilot+Ingress only as the minimal Istio install). Refer to the `istioctl` CLI tool for generating a
information on customized Istio deployments.

- **Automatic Proxy Injection**. We leverage Kubernetes 1.9's new
[mutating webhook feature](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.9.md#api-machinery) to provide automatic
pod-level proxy injection. Automatic injection requires Kubernetes 1.9 or beyond and
therefore doesn't work on older versions. The alpha initializer mechanism is no longer supported.
[Learn more](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)

- **Revised Traffic Rules**. Based on user feedback, we have made significant changes to Istio's traffic management
(routing rules, destination rules, etc.). We would love your continuing feedback while we polish this in the coming weeks.

## Mixer adapters

- **Open Policy Agent**. Mixer now has an authorization adapter implementing the [open policy agent](https://www.openpolicyagent.org) model,
providing a flexible fine-grained access control mechanism. [Learn more](https://docs.google.com/document/d/1U2XFmah7tYdmC5lWkk3D43VMAAQ0xkBatKmohf90ICA)

- **Istio RBAC**. Mixer now has a role-based access control adapter.
[Learn more](/docs/concepts/security/#authorization)

- **Fluentd**. Mixer now has an adapter for log collection through [Fluentd](https://www.fluentd.org).
[Learn more](/docs/tasks/observability/logs/fluentd/)

- **Stdio**. The stdio adapter now lets you log to files with support for log rotation & backup, along with a host
of controls.

## Security

- **Bring Your Own CA**. There have been many enhancements to the 'bring your own CA' feature.
[Learn more](/docs/tasks/security/citadel-config/plugin-ca-cert/)

- **PKCS8**. Add support for PKCS8 keys to Istio PKI.

- **Istio RBAC** Istio RBAC provides access control for services in Istio mesh.
[Learn more](/docs/concepts/security/#authorization).

## Other

- **Release-Mode Binaries**. We switched release and installation default to release for improved
performance and security.

- **Component Logging**. Istio components now offer a rich set of command-line options to control local logging, including
common support for log rotation.

- **Consistent Version Reporting**. Istio components now offer a consistent command-line interface to report their version information.

- **Optional Instance Fields**. Within configuration, definitions of Mixer instances no longer need to include every field of the
associated template. Omitted fields get a zero or empty value.

## Known issues

- Installing with Helm charts is currently broken.

- Automatic sidecar injection only works with Kubernetes 1.9 or later.
