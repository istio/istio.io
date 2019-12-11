---
title: Announcing Istio 1.4
linktitle: 1.4
subtitle: Major Update
description: Istio 1.4 release announcement.
publishdate: 2019-11-14
release: 1.4.0
skip_list: true
aliases:
    - /zh/news/2019/announcing-1.4
    - /zh/news/announcing-1.4.0
    - /zh/news/announcing-1.4
---

We are pleased to announce the release of Istio 1.4!

{{< relnote >}}

Istio 1.4 continues our efforts at improving the Istio user experience,
with a focus on simplification. We've also continued to add features that
improve the performance and experience of running Istio.

## Mixer-less telemetry

Our implementation of telemetry without Mixer will simplify installation and
operation of meshes, all while vastly improving performance. The in-proxy
generation of HTTP metrics has graduated from experimental to alpha. Users
are very excited about this improvement and we are working hard to get it
ready. We've also added new experimental features that don't require Mixer:
TCP metrics and Stackdriver metrics.

## Authorization policy model in `beta`

The authorization policy model is now in Beta with the introduction of the
[`v1beta1` authorization policy](/zh/blog/2019/v1beta1-authorization-policy/) that
focuses on simplification and flexibility. This will also replace the old
[`v1alpha1` RBAC policy](/zh/docs/reference/config/security/istio.rbac.v1alpha1/).

## Automatic mutual TLS

We added [automatic mutual TLS support](/zh/docs/tasks/security/authentication/auto-mtls/). It allows
you to adopt mutual TLS without needing to configure destination rules. Istio automatically programs
client sidecar proxies to send mutual TLS to server endpoints that are able to accept mutual TLS.

Currently this feature must be explicitly enabled, but we plan to enable it by default in a
future release.

## Improved troubleshooting

We're introducing the
[`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) command to
improve troubleshooting of your mesh. Check for problems with
configuration in your mesh, and even validate new configuration prior to
submitting it to the mesh.

## Better sidecar

We've been doing tons of work to improve Envoy, its feature set, and the
experience of using it. Envoy now exits more gracefully on crashes, supports
more metrics, and can mirror traffic to a percentage of traffic. It reports
the direction of traffic and has better configuration of `stat patterns`.
Finally, there is a new
[experimental command](/zh/docs/reference/commands/istioctl/#istioctl-experimental-wait)
that can tell you when configuration
has been pushed to all proxies in the mesh.

## Other enhancements

- Citadel will now periodically check for and rotate expired root certificates
- We've added support for OpenAPI v3 schema validation
- Experimental multi-cluster setup has been added to `istioctl`
- We simplified installation by removing the `proxy_init` Docker image

As always, there is a lot happening in the
[Community Meeting](https://github.com/istio/community#community-meeting);
join us every other Thursday at 11 AM Pacific.

We were very proud to be called out as one of the top five
[fastest growing](https://octoverse.github.com/#top-and-trending-projects)
open source projects in all of GitHub. Want to get involved? Join one of our
[Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)
and help us make Istio even better.

To join the conversation, go to [discuss.istio.io](https://discuss.istio.io),
log in with your GitHub credentials and join us!
