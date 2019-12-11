---
title: Istio 1.2.4 sidecar image vulnerability
description: An erroneous 1.2.4 sidecar image was available due to a faulty release operation.
publishdate: 2019-09-10
keywords: [community,blog,security]
aliases:
    - /zh/blog/2019/incorrect-sidecar-image-1.2.4
    - /zh/news/2019/incorrect-sidecar-image-1.2.4
---
To the Istio’s user community,

For the period between Aug 23rd 2019 09:16PM PST and Sep 6th 2019 09:26AM PST a Docker image shipped as Istio `proxyv2` 1.2.4 (c.f. [https://hub.docker.com/r/istio/proxyv2](https://hub.docker.com/r/istio/proxyv2) )
contained a faulty version of the proxy against the vulnerabilities [ISTIO-SECURITY-2019-003](/zh/news/security/istio-security-2019-003/) and
[ISTIO-SECURITY-2019-004](/zh/news/security/istio-security-2019-004/).

If you have installed Istio 1.2.4 during that time, please consider upgrading to Istio 1.2.5 that also contains additional security fixes.

## Detailed explanation

Because of the communication embargo that we have exercised when fixing the recent HTTP2 DoS vulnerabilities, as it is usual for this type of release, we have built, in advance, a fixed image of the sidecar privately. At the moment of the public disclosure, we pushed that image manually on Docker hub.

For any release that isn’t fixing a privately disclosed security vulnerability, this Docker image is usually pushed through our release pipeline job, entirely automatically.

Our automated release process does not work correctly with the manual interactions required by the vulnerability disclosure embargo: the release pipeline code kept a reference to an outdated version of the Istio repository.

For a problem to occur, an automated build needed to be launched on an old version, this is what happened during the release of Istio 1.2.5: we have experienced a problem that required a [revert commit](https://github.com/istio-releases/pipeline/commit/635d276ad7eac01bef9c3f195520a0f722626c0f) which triggered a rebuild of 1.2.4 against an outdated version of Istio’s code.

This revert commit happened on Aug 23rd 2019 09:16PM PST.
We have noticed this problem and pushed back the fixed image on Sep 6th 2019 09:26AM PST.

We are sorry for any inconvenience you may have experienced due to this incident, and [are working towards a better release system](https://github.com/istio/istio/issues/16887), as well as a more efficient way to deal with vulnerability reports.

The release managers for 1.2
