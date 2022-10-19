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
- [Support status of Istio releases](#support-status-of-istio-releases)
- [Supported releases without known Common Vulnerabilities and Exposures (CVEs)](#supported-releases-without-known-common-vulnerabilities-and-exposures-cves)

## Support policy

We produce new builds of Istio for each commit. Around once a quarter, we build a minor release and run through several
additional tests as well as release qualification. We release patch versions for issues found in minor releases.

The various types of releases represent a different product quality level and level of assistance from the Istio community.
In this context, *support* means that the community will produce patch releases for critical issues and offer technical
assistance. Separately, 3rd parties and partners may offer longer-term support solutions.

| Type              | Support Level                                                                                                         | Quality and Recommended Use                                                                                    |
|-------------------|-----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| Development Build | No support                                                                                                            | Dangerous, may not be fully reliable. Useful to experiment with.                                               |
| Minor Release     | Support provided until 6 weeks after the N+2 minor release (ex. 1.11 supported until 6 weeks after 1.13.0 is released)|
| Patch             | Same as the corresponding Minor release                                                                               | Users are encouraged to adopt patch releases as soon as they are available for a given release.                |
| Security Patch    | Same as a Patch, however, it will not contain any additional code other than the security fix from the previous patch | Given the nature of security fixes, users are **strongly** encouraged to adopt security patches after release. |

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

## Support status of Istio releases

| Version         | Currently Supported  | Release Date      | End of Life              | Supported Kubernetes Versions | Tested, but not supported          |
|-----------------|----------------------|-------------------|--------------------------|-------------------------------|------------------------------------|
| master          | No, development only |                   |                          |                               |                                    |
| 1.15            | Yes                  | August 31, 2022   | ~March 2023 (Expected)   | 1.22, 1.23, 1.24, 1.25        | 1.16, 1.17, 1.18, 1.19, 1.20, 1.21 |
| 1.14            | Yes                  | May 24, 2022      | ~January 2023 (Expected) | 1.21, 1.22, 1.23, 1.24        | 1.16, 1.17, 1.18, 1.19, 1.20       |
| 1.13            | Yes                  | February 11, 2022 | Oct 12, 2022             | 1.20, 1.21, 1.22, 1.23        | 1.16, 1.17, 1.18, 1.19             |
| 1.12            | No                   | November 18, 2021 | Jul 12, 2022             | 1.19, 1.20, 1.21, 1.22        | 1.16, 1.17, 1.18                   |
| 1.11            | No                   | August 12, 2021   | Mar 25, 2022             | 1.18, 1.19, 1.20, 1.21, 1.22  | 1.16, 1.17                         |
| 1.10            | No                   | May 18, 2021      | Jan 7, 2022              | 1.18, 1.19, 1.20, 1.21        | 1.16, 1.17, 1.22                   |
| 1.9             | No                   | February 9, 2021  | Oct 8, 2021              | 1.17, 1.18, 1.19, 1.20        | 1.15, 1.16                         |
| 1.8             | No                   | November 10, 2020 | May 12, 2021             | 1.16, 1.17, 1.18, 1.19        | 1.15                               |
| 1.7             | No                   | August 21, 2020   | Feb 25, 2021             | 1.16, 1.17, 1.18              | 1.15                               |
| 1.6 and earlier | No                   |                   |                          |                               |                                    |

{{< warning >}}
[Kubernetes 1.22 removed some deprecated APIs](https://kubernetes.io/blog/2021/07/14/upcoming-changes-in-kubernetes-1-22/) and as a result versions of Istio prior to 1.10.0 will no longer work. If you are upgrading your Kubernetes version, make sure that your Istio version is still supported.
{{< /warning >}}

## Supported releases without known Common Vulnerabilities and Exposures (CVEs)

{{< warning >}}
Istio does not guarantee that minor releases that fall outside the support window have all known CVEs patched.
Please keep up-to-date and use a supported version.
{{< /warning >}}

| Minor Releases   | Patched versions with no known CVEs           |
|------------------|-----------------------------------------------|
| 1.15.x           | 1.15.2+                                       |
| 1.14.x           | 1.14.5+                                       |
| 1.13.x           | 1.13.9+                                       |
| 1.12 and earlier | None, all versions have known vulnerabilities |
