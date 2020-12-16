---
title: Supported Releases
description: The currently supported Istio releases.
weight: 35
icon: cadence
---

This page lists the status and timeline for currently supported releases. Supported releases of Istio include releases that are in the active
maintenance window and are patched for security and bug fixes. Subsequent patch releases on a LTS release do not contain backward incompatible
changes. For more information refer to the [Istio support policy](../release-cadence/).

## Support status of Istio releases

| Version         | Currently Supported   | Release Date      | End of Life       | Supported Kubernetes Versions |
|-----------------|-----------------------|-------------------|-------------------|-------------------------------|
| master          | No, development only  |                   |                   |                               |
| 1.8             | Yes                   | November 10, 2020 |                   | 1.16, 1.17, 1.18, 1.19        |
| 1.7             | Yes                   | August 21, 2020   |                   | 1.16, 1.17, 1.18              |
| 1.6             | No                    | May 21, 2020      | November 23, 2020 | 1.15, 1.16, 1.17, 1.18        |
| 1.5 and earlier | No                    |                   |                   |                               |

## Releases without known Common Vulnerabilities and Exposures (CVEs)

| LTS Release                | Patched versions with no known CVEs  |
|----------------------------|--------------------------------------|
| 1.8.x                      | 1.8.1                                |
| 1.7.x                      | 1.7.3, 1.7.4, 1.7.5, 1.7.6           |
| 1.6.x                      | 1.6.11, 1.6.12, 1.6.13, 1.6.14       |
| 1.5 and earlier            | None                                 |
