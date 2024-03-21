---
title: Supported Releases
description: The currently supported Istio releases.
weight: 35
aliases:
    - /about/supported-releases
    - /latest/about/supported-releases
owner: istio/wg-docs-maintainers
test: n/a
---

This page lists the status, timeline and policy for currently supported releases. Supported releases of Istio include
releases that are in the active maintenance window and are patched for security and bug fixes. Subsequent patch releases
on a minor release do not contain backward incompatible changes.

- [Support policy](#support-policy)
- [Naming scheme](#naming-scheme)
- [Control Plane/Data Plane Skew](#control-planedata-plane-skew)
- [Support status of Istio releases](#support-status-of-istio-releases)
- [Supported releases without known Common Vulnerabilities and Exposures (CVEs)](#supported-releases-without-known-common-vulnerabilities-and-exposures-cves)
- [Relationship between Istio and Envoy](#supported-envoy-versions)

## Support policy

We produce new builds of Istio for each commit. Around once a quarter, we build a minor release and run through several
additional tests as well as release qualification. We release patch versions for issues found in minor releases.

The various types of releases represent a different product quality level and level of assistance from the Istio community.
In this context, *support* means that the community will produce patch releases for critical issues and offer technical
assistance. Separately, 3rd parties and partners may offer longer-term support solutions.

| Type              | Support Level                                                                                                          | Quality and Recommended Use                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Development Build | No support                                                                                                             | Dangerous, may not be fully reliable. Useful to experiment with.                                               |
| Minor Release     | Support provided until 6 weeks after the N+2 minor release (ex. 1.11 supported until 6 weeks after 1.13.0 is released) |
| Patch             | Same as the corresponding Minor release                                                                                | Users are encouraged to adopt patch releases as soon as they are available for a given release.                |
| Security Patch    | Same as a Patch, but contains a security fix.  Sometimes security patches will contain additional code/fixes in addition to the security fixes.  | Given the nature of security fixes, users are **strongly** encouraged to adopt security patches after release. |

You can find available releases on the [releases page](https://github.com/istio/istio/releases),
and if you're the adventurous type, you can learn about our development builds on the [development builds wiki](https://github.com/istio/istio/wiki/Dev%20Builds).
You can find high-level releases notes for each minor and patch release [here](/news).

## Naming scheme

Our naming scheme is as follows:

{{< text plain >}}
<major>.<minor>.<patch>
{{< /text >}}

where `<minor>` is increased for each release, and `<patch>` counts the number of patches for the
current `<minor>` release. A patch is usually a small change relative to the `<minor>` release.

## Control Plane/Data Plane Skew

The Istio control plane can be one version ahead of the data plane. However, the data plane cannot be ahead of control plane. We recommend using [revisions](/docs/setup/upgrade/canary/) so that there is no skew at all.

As of now, data plane to data plane is compatible across all versions; however, this may change in the future.

## Support status of Istio releases

{{< support_status_table >}}

## Supported releases without known Common Vulnerabilities and Exposures (CVEs)

{{< warning >}}
Istio does not guarantee that minor releases that fall outside the support window have all known CVEs patched.
Please keep up-to-date and use a supported version.
{{< /warning >}}

| Minor Releases   | Patched versions with no known CVEs                  |
| ---------------- | ---------------------------------------------------- |
| 1.21.x           | 1.21.0                                              |
| 1.20.x           | 1.20.3+                                              |
| 1.19.x           | 1.19.7+                                              |

## Supported Envoy Versions

Istio's data plane is based on [Envoy](https://github.com/envoyproxy/envoy).

The relationship between the two project's versions:

| Istio version | Envoy release branch |
| ------------- | -------------------- |
| 1.21.x        | release/v1.29        |
| 1.20.x        | release/v1.28        |
| 1.19.x        | release/v1.27        |

You can find the precise Envoy commit used by Istio in [`istio/proxy`](https://github.com/istio/proxy/blob/master/WORKSPACE#L38).
