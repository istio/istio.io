---
title: "Announcing Support for 1.8 to 1.10 Direct Upgrades"
description: "Moving Towards a Smoother Upgrade Process."
publishdate: 2021-05-24
attribution: "Mitch Connors (Google), Sam Naser (Google)"
keywords: [upgrade,Istio,revision]
---

As Service Mesh technology moves from cutting edge to stable infrastructure, many users have expressed an interest in upgrading their service mesh less frequently, as qualifying a new minor release can take a lot of time. Upgrading can be especially difficult for users who don’t keep up with new releases, as Istio has not supported upgrades across multiple minor versions.  To upgrade from `1.6.x` to `1.8.x`, users first had to upgrade to `1.7.x` and then to `1.8.x`.

With the release of Istio 1.10, we are announcing Alpha level support for upgrading directly from Istio `1.8.x` to `1.10.x`, without upgrading to `1.9.x`.  We hope this will reduce the operational burden of running Istio, in keeping with our 2021 theme of improving Day 2 Operations.

## Upgrade From 1.8 to 1.10

For direct upgrades we recommend using the canary upgrade method so that control plane functionality can be verified before cutting workloads over to the new version. We’ll also be using [revision tags](/blog/2021/revision-tags/) in this guide, an improvement to canary upgrades that was introduced in 1.10, so users don’t have to change the labels on a namespace while upgrading.

First, using a version `1.10` or newer `istioctl`, create a revision tag `stable` pointed to your existing `1.8` revision. From now on let’s assume this revision is called `1-8-5`:

{{< text bash >}}
$ istioctl x revision tag set stable --revision 1-8-5
{{< /text >}}

If your 1.8 installation did not have an associated revision, we can create this revision tag with:

{{< text bash >}}
$ istioctl x revision tag set stable --revision default
{{< /text >}}

Now, relabel your namespaces that were previously labeled with `istio-injection=enabled` or `istio.io/rev=<REVISION>` with `istio.io/rev=stable`. Download the Istio 1.10.0 release and install the new control plane with a revision:

{{< text bash >}}
$ istioctl install --revision 1-10-0 -y
{{< /text >}}

Now evaluate that the `1.10` revision has come up correctly and is healthy. Once satisfied with the stability of new revision you can set the revision tag to the new revision:

{{< text bash >}}
$ istioctl x revision tag set stable --revision 1-10-0 --overwrite
{{< /text >}}

Verify that the revision tag `stable` is pointing to the new revision:

{{< text bash >}}
$ istioctl x revision tag list
TAG    REVISION NAMESPACES
stable 1-10-0        ...
{{< /text >}}

Once prepared to move existing workloads over to the new 1.10 revision, the workloads must be restarted so that the sidecar proxies will use the new control plane. We can go through namespaces one by one and roll the workloads over to the new version:

{{< text bash >}}
$ kubectl rollout restart deployments -n …
{{< /text >}}

Notice an issue after rolling out workloads to the new Istio version? No problem! Since you’re using canary upgrades, the old control plane is still running and we can just switch back over.

{{< text bash >}}
$ istioctl x revision tag set prod --revision 1-8-5
{{< /text >}}

Then after triggering another rollout, your workloads will be back on the old version.

We look forward to hearing about your experience with direct upgrades, and look forward to improving and expanding this functionality in the future.
