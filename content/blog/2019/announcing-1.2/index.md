---
title: Announcing Istio 1.2
subtitle: Major Update
description: Istio 1.2 release announcement.
publishdate: 2019-06-18
attribution: The Istio Team
release: 1.1.0
---

We are pleased to announce the release of Istio 1.2!

{{< relnote linktonote="true" >}}

The theme of 1.2 is Predictable Releases - predictable in quality (we want
every release to be a good release) as well as in time (we want to be able
to ship on well known schedules).

As nearly anyone using Istio 1.0 noticed, it took us a long time to get 1.1
out. Far too long. One of the reasons was that we needed to do some work on
our testing and infrastructure -- it was simply far too manual a process to
build, test and release. Because of that, 1.2 focuses on improving the
stability of these new features, and improving general product health.

In order to make release quality and timing predictable, we declared a
"Code Mauve",  meaning that we would spend the next iteration focusing on
project infrastructure. As a result, we’ve been investing a ton of effort
in our build, test and release machinery.

We formed 3 new teams (GitHub Workflow, Source Organization, Testing
Methodology, and Build & Release Automation). Each had a set of issues to
take on and a set of exit criteria. Code Mauve isn’t over yet, in fact we
expect it to go
on for some time.   We’re putting in place the infrastructure to measure the
metrics each team decided on (paraphrasing Peter Drucker: if you can’t
measure it, you can’t manage it).

You might have noticed that the [patch releases](/about/notes) for 1.1 have
been coming fast and furious. 

In order to get features in the hands of our customers and users as soon as
possible, most of the new features from the last three months have been
delivered in 1.1.x releases. With 1.2, those features are now officially
part of the release.  See a complete
list of changes in the [release notes](/about/notes/1.2).

We're seeing early results from the usability group. In the release notes,
you'll find that you can now set log levels for the control plane and the
data plane globally.  You can use `istioctl` to validate that your Kubernetes
installation meets Istio's requirements. And the new
`traffic.sidecar.istio.io/includeInboundPorts` annotation to eliminate the
need for service owner to declare `containerPort` in the deployment yaml.

Some of the features have matured as well. The following features have
progressed from Beta status
to Stable:  SNI at ingress, distributed tracing, and service tracing. The
following features have reached beta status: cert management on ingress,
configuration resource validation, and configuration processing with Galley.
We know there are lots of feature requests outstanding, and we have an
exciting roadmap (watch for a forthcoming post from the TOC on that). The
work we have done in this release has taken care of some technical debt which
will help us get those features out reliably in future.

As always, there is also a lot happening in the [Community
Meeting](https://github.com/istio/community#community-meeting) (Thursdays at
`11 a.m. Pactific`) and in the [Working
Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md). And
if you haven’t yet joined the conversation at
[discuss.istio.io](https://discuss.istio.io), head over, log in with your
GitHub credentials and join us!
