---
title: Supported Releases
description: The currently supported Istio releases.
weight: 35
icon: cadence
---

This page lists the status, timeline and policy for currently supported releases. Supported releases of Istio include releases that are in the active
maintenance window and are patched for security and bug fixes. Subsequent patch releases on a LTS release do not contain backward incompatible
changes.

* [Support Policy](#support-policy)
* [Naming scheme](#naming-scheme)
* [Support status of Istio releases](#support-status-of-istio-releases)
* [Releases without known Common Vulnerabilities and Exposures (CVEs)](#releases-without-known-Common-Vulnerabilities-and Exposures) 

## Support policy

We produce new builds of Istio for each commit. Around once a quarter or so, we build a Long Term Support (LTS) release,
and run through a bunch more tests and release qualification. Finally, if we find something wrong with an
LTS release, we issue patches.

The different types represent different product quality levels and different levels of support
from the Istio team. In this context, *support* means that we will produce patch releases for critical issues and
offer technical assistance. Separately, 3rd parties and partners may offer longer-term support solutions.

|Type              | Support Level                                            | Quality and Recommended Use
|------------------|----------------------------------------------------------|----------------------------
|Development Build | No support                                               | Dangerous, may not be fully reliable. Useful to experiment with.
|LTS Release       | Support is provided until 3 months after the next LTS    | Safe to deploy in production. Users are encouraged to upgrade to these releases as soon as possible.
|Patches           | Same as the corresponding Snapshot/LTS release           | Users are encouraged to adopt patch releases as soon as they are available for a given release.

You can find available releases on the [releases page](https://github.com/istio/istio/releases),
and if you're the adventurous type, you can learn about our development builds on the [development builds wiki](https://github.com/istio/istio/wiki/Dev%20Builds).
You can find high-level releases notes for each LTS release [here](/news).

## Naming scheme

Our naming scheme for LTS releases is:

{{< text plain >}}
<major>.<minor>.<patch>
{{< /text >}}

where `<minor>` is increased for every LTS release, and `<LTS patch level>` counts the number of patches for the
current LTS release. A patch is usually a small change relative to the LTS.

For snapshot releases, our naming scheme is:

{{< text plain >}}
<major>.<minor>-alpha.<sha>
{{< /text >}}

where `<major>.<minor>` represent the next LTS, and
`<sha>` represents the git commit the release is built from.


## Support status of Istio releases

| Version         | Currently Supported   | Release Date      | End of Life       | Supported Kubernetes Versions | Untested, but may work on Kubernetes Versions |
|-----------------|-----------------------|-------------------|-------------------|-------------------------------|-----------------------------------------------|
| master          | No, development only  |                   |                   |                               |                                               |
| 1.9             | N/A                   | TBD               |                   | 1.17, 1.18, 1.19, 1.20        | 1.15, 1.16                                    |
| 1.8             | Yes                   | November 10, 2020 |                   | 1.16, 1.17, 1.18, 1.19        | 1.15                                          |
| 1.7             | Yes                   | August 21, 2020   |                   | 1.16, 1.17, 1.18              | 1.15                                          |
| 1.6             | No                    | May 21, 2020      | November 23, 2020 | 1.15, 1.16, 1.17, 1.18        |                                               |
| 1.5 and earlier | No                    |                   |                   |                               |                                               |

## Releases without known Common Vulnerabilities and Exposures (CVEs)

| LTS Release                | Patched versions with no known CVEs  |
|----------------------------|--------------------------------------|
| 1.8.x                      | 1.8.1                                |
| 1.7.x                      | 1.7.3, 1.7.4, 1.7.5, 1.7.6           |
| 1.6.x                      | 1.6.11, 1.6.12, 1.6.13, 1.6.14       |
| 1.5 and earlier            | None                                 |
