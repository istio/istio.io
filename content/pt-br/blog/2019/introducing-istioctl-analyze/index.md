---
title: Introducing istioctl analyze
description: Analyze your Istio configuration to detect potential issues and get general insights.
publishdate: 2019-11-14
subtitle:
attribution: David Ebbo (Google)
keywords: [debugging,istioctl,configuration]
target_release: 1.4
---

Istio 1.4 introduces an experimental new tool to help you analyze and debug your clusters running Istio.

[`istioctl analyze`](/docs/reference/commands/istioctl/#istioctl-experimental-analyze) is a diagnostic tool that detects potential issues with your
Istio configuration, as well as gives general insights to improve your configuration.
It can run against a live cluster or a set of local configuration files.
It can also run against a combination of the two, allowing you to catch problems before you
apply changes to a cluster.

To get started with it in just minutes, head over to the [documentation](/docs/ops/diagnostic-tools/istioctl-analyze/).

## Designed to be approachable for novice users

One of the key design goals that we followed for this feature is to make it extremely approachable.
This is achieved by making the command useful without having to pass any required complex parameters.

In practice, here are some of the scenarios that it goes after:

- *"There is some problem with my cluster, but I have no idea where to start"*
- *"Things are generally working, but I'm wondering if there is anything I could improve"*

In that sense, it is very different from some of the more advanced diagnostic tools, which go
after scenarios along the lines of (taking `istioctl proxy-config` as an example):

- *"Show me the Envoy configuration for this specific pod so I can see if anything looks wrong"*

This can be very useful for advanced debugging, but it requires a lot of expertize before you
can figure out that you need to run this specific command, and which pod to run it on.

So really, the one-line pitch for `analyze` is: just run it! It's completely safe, it takes no thinking,
it might help you, and at worst, you'll have wasted a minute!

## Improving this tool over time

In Istio 1.4, `analyze` comes with a nice set of analyzers that can detect a number of common issues.
But this is just the beginning, and we are planning to keep growing and fine tuning the analyzers with
each release.

In fact, we would welcome suggestions from Istio users. Specifically, if you encounter a situation
where you think an issue could be detected via configuration analysis, but is not currently flagged
by `analyze`, please do let us know. The best way to do this is to [open an issue on GitHub](https://github.com/istio/istio/issues).
