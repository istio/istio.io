---
title: Text Blocks and Lists
description: Composing text blocks and lists.
skip_sitemap: true
---

1. A bullet

    {{< text plain >}}
    A text block nested in a bullet
    with a second line

    and a third line
    {{< /text >}}

1. Another bullet

    {{< warning >}}
    A nested warning
    {{< /warning >}}

    {{< text plain >}}
    Another nested text block
    with a second line

    and a third line
    {{< /text >}}

1. Yet another bullet

    Second paragraph

1. Still another bullet

    {{< warning >}}
    This is a warning in a bullet.

    {{< text plain >}}
    This is a text block in a warning in a bullet
    with a second line

    and a third line
    {{< /text >}}

    {{< /warning >}}

1.  Deploy your application using the `kubectl` command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    {{< warning >}}
    If you disabled automatic sidecar injection during installation and rely on [manual sidecar injection]
    (/docs/setup/kubernetes/additional-setup/sidecar-injection/#manual-sidecar-injection),
    use the `istioctl kube-inject` command to modify the `bookinfo.yaml`
    file before deploying your application. For more information please
    visit the `istioctl` [reference documentation](/docs/reference/commands/istioctl/#istioctl-kube-inject).

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo.yaml@)
    {{< /text >}}

    {{< /warning >}}

    The command launches all four services shown in the `bookinfo` application architecture diagram.
    All 3 versions of the reviews service, v1, v2, and v3, are started.

    {{< tip >}}
    In a realistic deployment, new versions of a microservice are deployed
    over time instead of deploying all versions simultaneously.
    {{< /tip >}}
