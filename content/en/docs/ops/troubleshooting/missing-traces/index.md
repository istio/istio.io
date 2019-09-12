---
title: Missing Zipkin Traces
description: Fix missing traces in Zipkin.
weight: 90
aliases:
    - /help/ops/troubleshooting/missing-traces
---
## No traces appearing in Zipkin when running Istio locally on Mac

Istio is installed and everything seems to be working except there are no traces showing up in Zipkin when there
should be.

This may be caused by a known [Docker issue](https://github.com/docker/for-mac/issues/1260) where the time inside
containers may skew significantly from the time on the host machine. If this is the case,
when you select a very long date range in Zipkin you will see the traces appearing as much as several days too early.

You can also confirm this problem by comparing the date inside a Docker container to outside:

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

To fix the problem, you'll need to shutdown and then restart Docker before reinstalling Istio.
