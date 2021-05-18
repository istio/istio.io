---
title: "Istio control plane canary with revisions and tags"
description: Learn how to take more control over your Istio control-plane upgrades.
publishdate: 2021-05-20
attribution: "Christian Posta (Solo.io), Lin Sun (Solo.io), Sam Naser (Google)"
keywords: [upgrades,revisions,operations,canary]
---

The Istio community [releases new versions of Istio](https://istio.io/latest/about/supported-releases/) every quarter and sometimes between the normal release cadence for bug fixes [or CVE patches](https://istio.io/latest/about/security-vulnerabilities/). The operator of an Istio service mesh needs to upgrade the control plane and data plane components during the life of the service mesh. You must take care when upgrading a service mesh as a mistake could take down the entire mesh and affect your business traffic. Istio has a couple mechanisms to make it safe to perform upgrades in a controlled manner, and in Istio 1.10 we further improve this operational experience.

## Background

In Istio 1.6, [we added basic support for upgrading the service mesh](https://istio.io/latest/news/releases/1.6.x/announcing-1.6/change-notes/) following a [canary pattern using revisions](https://istio.io/latest/blog/2020/multiple-control-planes/). Using this approach, you can run multiple control planes side-by-side without impacting an existing deployment and slowly migrate workloads from an old control plane to the new control plane.

To support this revision-based upgrade, Istio introduced the `istio.io/rev` label for namespaces which indicates to which control plane the workload data-plane proxies in that namespace should connect. For example, a label of `istio.io/rev=1-9-3` indicates the control plane revision `1-9-3` should inject the data plane for workloads in that namespace.

If you wanted to upgrade the data-plane proxies for a particular namespace, you would update the `istio.io/rev` label to point to a new version such as `istio.io/rev=1-10-0`. Across many namespaces, updating labels one at a time could be tedious and error prone. Let's see how Istio can improve your experience doing upgrades.

## Introducing Revision Tags

[In Istio 1.10](https://istio.io/latest/news/releases/1.10.x/announcing-1.10/), we've improved the revision feature [with a new feature called _revision tags_](https://istio.io/latest/docs/setup/upgrade/canary/#stable-revision-labels-experimental). A revision `tag` reduces the number of changes an operator has to make to use revisions and safely upgrade an Istio control plane. With a `tag`, you can point to a revision and use the `tag` as the label for your namespaces. That way you don't have to change the labels on a namespace and minimize the number of manual steps and configuration changes upgrading. Manually changing (or even trying to orchestrate) changes of labels across a large number of namespaces can be error-prone and lead to unintended downtime.

For example, you can define a `tag` named `prod-stable` and point it to the `1-9-3` revision of a control plane. You can also define another `tag` named `prod-canary` and also point it to a new `1-10-0` revision. You may have a lot of important namespaces in your cluster and can label those namespaces with `istio.io/rev=prod-stable`. You may have other namespaces where you are willing to canary control plane changes and can label that `istio.io/rev=prod-canary`. In both of these scenarios, the tag will indirectly associate those namespaces with the `1-9-3` revision for `prod-stable` and `1-10-0` for `prod-canary` respectively.

{{< image link="./tags.png" caption="Stable revision tags" >}}

Once you've determined the new control plane is suitable for the rest of the `prod-stable` namespaces, you can change the tag to point to the new revision. This will enable you to update the namespaces labeled `prod-stable` to the new `1-10-0` revision without making any changes to the labels on the namespace.

{{< image link="./tags-updated.png" caption="Updated revision tags" >}}

## Stable revision tags in action

For example, to create a new `prod-stable` tag for a revision `1-9-3`, you would run the following command:

{{< text bash >}}
$ istioctl x revision tag set prod-stable --revision 1-9-3
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
prod-stable 1-9-3
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
$  istioctl install -y --set profile=minimal --revision 1-10-0
{{< /text >}}

You can create a new tag called `prod-canary` and point that to your `1-10-0` revision:

{{< text bash >}}
$  istioctl x revision tag set prod-canary --revision 1-10-0
{{< /text >}}

Then label your namespaces accordingly:

{{< text bash >}}
$ kubectl label ns istioinaction-canary istio.io/rev=prod-canary
{{< /text >}}

If you list out the tags in our system, you should see two stable tags pointing to different revisions:

{{< text bash >}}
$ istioctl x revision tag list

TAG         REVISION NAMESPACES
prod-stable 1-9-3
prod-canary 1-10-0
{{< /text >}}

Any of the namespaces that you have labeled with `istio.io/rev=prod-canary` will be injected by the control plane that corresponds to the `prod-canary` stable tag name (which in this example points to the `1-10-0` revision). When you're ready, you can switch the `prod-stable` tag to the new control plane with:

{{< text bash >}}
$  istioctl x revision tag set prod-stable --revision 1-10-0 --overwrite
{{< /text >}}

When both the `prod-stable` and `prod-canary` tags both point to the same new revision, it may be safe to remove the old revision.

## Wrapping up

Using revisions makes it safe to canary changes to an Istio control plane. In large environments with lots of namespaces, you may prefer to use stable tags as we've introduced in this blog to remove the number of moving pieces and simplify any automation you may build around updating an Istio control plane. [Check out the Istio 1.10 release](https://istio.io/latest/news/releases/1.10.x/announcing-1.10/) [and the new `tag` feature](https://istio.io/latest/docs/setup/upgrade/canary/#stable-revision-labels-experimental) and give us feedback!