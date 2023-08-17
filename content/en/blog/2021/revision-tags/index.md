---
title: "Safely upgrade the Istio control plane with revisions and tags"
description: Learn how to perform canary upgrades of your mesh control plane.
publishdate: 2021-05-26
attribution: "Christian Posta (Solo.io), Lin Sun (Solo.io), Sam Naser (Google)"
keywords: [upgrades,revisions,operations,canary]
---

Like all security software, your service mesh should be kept up-to-date. The Istio community [releases new versions every quarter](/docs/releases/supported-releases/), with regular patch releases for bug fixes [and security vulnerabilities](/blog/2021/patch-tuesdays/). The operator of a service mesh will need to upgrade the control plane and data plane components many times. You must take care when upgrading, as a mistake could affect your business traffic. Istio has many mechanisms to make it safe to perform upgrades in a controlled manner, and in Istio 1.10 we further improve this operational experience.

## Background

[In Istio 1.6](/news/releases/1.6.x/announcing-1.6/change-notes/), we added [basic support for upgrading the service mesh following a canary pattern using revisions](/blog/2020/multiple-control-planes/). Using this approach, you can run multiple control planes side-by-side without impacting an existing deployment and slowly migrate workloads from the old control plane to the new.

To support this revision-based upgrade, Istio introduced a `istio.io/rev` label for namespaces. This indicates which control plane revision should inject sidecar proxies for the workloads in the respective namespace. For example, a label of `istio.io/rev=1-9-5` indicates the control plane revision `1-9-5` should inject the data plane using proxies for `1-9-5` for workloads in that namespace.

If you wanted to upgrade the data-plane proxies for a particular namespace, you would update the `istio.io/rev` label to point to a new version, such as `istio.io/rev=1-10-0`. Manually changing (or even trying to orchestrate) changes of labels across a large number of namespaces can be error-prone and lead to unintended downtime.

## Introducing Revision Tags

[In Istio 1.10](/news/releases/1.10.x/announcing-1.10/), we've improved revision-based upgrades with a new feature called _[revision tags](/docs/setup/upgrade/canary/#stable-revision-labels-experimental)_. A revision tag reduces the number of changes an operator has to make to use revisions, and safely upgrade an Istio control plane. You use the tag as the label for your namespaces, and assign a revision to that tag. This means you don't have to change the labels on a namespace while upgrading, and minimizes the number of manual steps and configuration changes.

For example, you can define a tag named `prod-stable` and point it to the `1-9-5` revision of a control plane. You can also define another tag named `prod-canary` which points to the `1-10-0` revision. You may have a lot of important namespaces in your cluster, and you can label those namespaces with `istio.io/rev=prod-stable`. In other namespaces you may be willing to test the new version of Istio, and you can label that namespace `istio.io/rev=prod-canary`. The tag will indirectly associate those namespaces with the `1-9-5` revision for `prod-stable` and `1-10-0` for `prod-canary` respectively.

{{< image link="./tags.png" caption="Stable revision tags" >}}

Once you've determined the new control plane is suitable for the rest of the `prod-stable` namespaces, you can change the tag to point to the new revision. This enables you to update all the namespaces labeled `prod-stable` to the new `1-10-0` revision without making any changes to the labels on the namespaces. You will need to restart the workloads in a namespace once you've changed the tag to point to a different revision.

{{< image link="./tags-updated.png" caption="Updated revision tags" >}}

Once you're satisfied with the upgrade to the new control-plane revision, you can remove the old control plane.

## Stable revision tags in action

To create a new `prod-stable` tag for a revision `1-9-5`, run the following command:

{{< text bash >}}
$ istioctl x revision tag set prod-stable --revision 1-9-5
{{< /text >}}

You can then label your namespaces with the `istio.io/rev=prod-stable` label. Note, if you installed a `default` revision (i.e., no revision) of Istio, you will first have to remove the standard injection label:

{{< text bash >}}
$ kubectl label ns istioinaction istio-injection-
$ kubectl label ns istioinaction istio.io/rev=prod-stable
{{< /text >}}

You can list the tags in your mesh with the following:

{{< text bash >}}
$ istioctl x revision tag list

TAG         REVISION NAMESPACES
prod-stable 1-9-5    istioinaction
{{< /text >}}

A tag is implemented with a `MutatingWebhookConfiguration`. You can verify a corresponding `MutatingWebhookConfiguration` has been created:

{{< text bash >}}
$ kubectl get MutatingWebhookConfiguration

NAME                             WEBHOOKS   AGE
istio-revision-tag-prod-stable   2          75s
istio-sidecar-injector           1          5m32s
{{< /text >}}

Let's say you are trying to canary a new revision of the control plane based on 1.10.0. First you would install the new version using a revision:

{{< text bash >}}
$ istioctl install -y --set profile=minimal --revision 1-10-0
{{< /text >}}

You can create a new tag called `prod-canary` and point that to your `1-10-0` revision:

{{< text bash >}}
$ istioctl x revision tag set prod-canary --revision 1-10-0
{{< /text >}}

Then label your namespaces accordingly:

{{< text bash >}}
$ kubectl label ns istioinaction-canary istio.io/rev=prod-canary
{{< /text >}}

If you list out the tags in your mesh, you will see two stable tags pointing to two different revisions:

{{< text bash >}}
$ istioctl x revision tag list

TAG         REVISION NAMESPACES
prod-stable 1-9-5    istioinaction
prod-canary 1-10-0   istioinaction-canary
{{< /text >}}

Any of the namespaces that you have labeled with `istio.io/rev=prod-canary` will be injected by the control plane that corresponds to the `prod-canary` stable tag name (which in this example points to the `1-10-0` revision). When you're ready, you can switch the `prod-stable` tag to the new control plane with:

{{< text bash >}}
$ istioctl x revision tag set prod-stable --revision 1-10-0 --overwrite
{{< /text >}}

Any time you switch a tag to point to a new revision, you will need to restart the workloads in any respective namespace to pick up the new revision's proxy.

When both the `prod-stable` and `prod-canary` no longer point to the old revision, it may be safe to remove the old revision as follows:

{{< text bash >}}
$ istioctl x uninstall --revision 1-9-5
{{< /text >}}

## Wrapping up

Using revisions makes it safer to canary changes to an Istio control plane. In large environments with lots of namespaces, you may prefer to use stable tags, as we've introduced in this blog, to remove the number of moving pieces and simplify any automation you may build around updating an Istio control plane. Please check out the [1.10 release](/news/releases/1.10.x/announcing-1.10/) [and the new tag feature](/docs/setup/upgrade/canary/#stable-revision-labels) and give us your feedback!
