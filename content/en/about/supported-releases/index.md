---
title: Supported Releases
description: The currently supported Istio releases.
weight: 35
icon: cadence
---

This page lists the status, timeline and policy for currently supported releases. Supported releases of Istio include releases that are in the active
maintenance window and are patched for security and bug fixes. Subsequent patch releases on a minor release do not contain backward incompatible
changes.

* [Support Policy](#support-policy)
* [Naming scheme](#naming-scheme)
* [Support status of Istio releases](#support-status-of-istio-releases)
* [Releases without known Common Vulnerabilities and Exposures (CVEs)](#releases-without-known-Common-Vulnerabilities-and Exposures)

## Support policy

We produce new builds of Istio for each commit. Around once a quarter, we build a minor release and
run through several additional tests as well as release qualification. We issue patch releases for issues found in minor
releases.

The different types represent a different product quality level and different level of support
from the Istio team. In this context, *support* means that we will produce patch releases for critical issues and
offer technical assistance. Separately, 3rd parties and partners may offer longer-term support solutions.

|Type              | Support Level                                                                                                         | Quality and Recommended Use
|------------------|-----------------------------------------------------------------------------------------------------------------------|----------------------------
|Development Build | No support                                                                                                            | Dangerous, may not be fully reliable. Useful to experiment with.
|Minor Release     | Support is provided until 3 months after the next minor release                                                       | Safe to deploy in production. Users are encouraged to upgrade to these releases as soon as possible.
|Patch             | Same as the corresponding Minor release                                                                               | Users are encouraged to adopt patch releases as soon as they are available for a given release.
|Security Patch    | Same as a Patch, however, it will not contain any additional code other than the security fix from the previous patch | Given the nature of security fixes, users are **strongly** encouraged to adopt security patches after release.

You can find available releases on the [releases page](https://github.com/istio/istio/releases),
and if you're the adventurous type, you can learn about our development builds on the [development builds wiki](https://github.com/istio/istio/wiki/Dev%20Builds).
You can find high-level releases notes for each LTS release [here](/news).

## Naming scheme

Our naming scheme is as follows:

{{< text plain >}}
<major>.<minor>.<patch>
{{< /text >}}

where `<minor>` is increased for each release, and `<patch>` counts the number of patches for the
current `<minor>` release. A patch is usually a small change relative to the `<minor>` release.

## Support status of Istio releases

| Version         | Currently Supported   | Release Date        | End of Life         | Supported Kubernetes Versions | Untested, but may work on Kubernetes Versions |
|-----------------|-----------------------|---------------------|---------------------|-------------------------------|-----------------------------------------------|
| master          | No, development only  |                     |                     |                               |                                               |
| 1.9             | N/A                   | ~Feb 2021(Expected) | ~Aug 2021(Expected) | 1.17, 1.18, 1.19, 1.20        | 1.15, 1.16                                    |
| 1.8             | Yes                   | November 10, 2020   | ~May 2021(Expected) | 1.16, 1.17, 1.18, 1.19        | 1.15                                          |
| 1.7             | Yes                   | August 21, 2020     | Feb 19, 2021         | 1.16, 1.17, 1.18              | 1.15                                          |
| 1.6             | No                    | May 21, 2020        | November 23, 2020   | 1.15, 1.16, 1.17, 1.18        |                                               |
| 1.5 and earlier | No                    |                     |                     |                               |                                               |

## Releases without known Common Vulnerabilities and Exposures (CVEs)

| LTS Release                | Patched versions with no known CVEs  |
|----------------------------|--------------------------------------|
| 1.9.x                      | 1.9.0                                |
| 1.8.x                      | 1.8.1, 1.8.2                         |
| 1.7.x                      | 1.7.3, 1.7.4, 1.7.5, 1.7.6, 1.7.7    |
| 1.6.x                      | 1.6.11, 1.6.12, 1.6.13, 1.6.14       |
| 1.5 and earlier            | None                                 |
