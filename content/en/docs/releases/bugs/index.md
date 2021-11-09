---
title: Reporting Bugs
description: What to do if you find a bug.
weight: 34
aliases:
    - /bugs.html
    - /bugs/index.html
    - /help/bugs/
    - /about/bugs
    - /latest/about/bugs
owner: istio/wg-docs-maintainers
test: n/a
---

Oh no! You found a bug? We'd love to hear about it.

## Product bugs

Search our [issue database](https://github.com/istio/istio/issues/) to see if
we already know about your problem and learn about when we think we can fix
it. If you don't find your problem in the database, please open a [new
issue](https://github.com/istio/istio/issues/new/choose) and let us know
what's going on.

If you think a bug is in fact a security vulnerability, please visit [Reporting Security Vulnerabilities](/docs/releases/security-vulnerabilities/)
to learn what to do.

### Kubernetes cluster state archives

If you're running on Kubernetes, consider including a cluster state
archive with your bug report.
For convenience, you can run the `istioctl bug-report` command to produce an archive containing
all of the relevant state from your Kubernetes cluster:

    {{< text bash >}}
    $ istioctl bug-report
    {{< /text >}}

Then attach the produced `bug-report.tgz` with your reported problem.

If your mesh spans multiple clusters, run `istioctl bug-report` against each cluster, specifying the `--context`
or `--kubeconfig` flags.

{{< tip >}}
The `istioctl bug-report` command is only available with `istioctl` version `1.8.0` and higher but it can be used to also collect the information from an older Istio version installed in your cluster.
{{< /tip >}}

{{< tip >}}
If you are running `bug-report` on a large cluster, it might fail to complete.
Please use the `--include ns1,ns2` option to target the collection of proxy
commands and logs only for the relevant namespaces. For more bug-report options,
please visit [the istioctl bug-report
reference](/docs/reference/commands/istioctl/#istioctl-bug-report).
{{< /tip >}}

If you are unable to use the `bug-report` command, please attach your own archive
containing:

* Output of istioctl analyze:

    {{< text bash >}}
    $ istioctl analyze --all-namespaces
    {{< /text >}}

* Pods, services, deployments, and endpoints across all namespaces:

    {{< text bash >}}
    $ kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml
    {{< /text >}}

* Secret names in `istio-system`:

    {{< text bash >}}
    $ kubectl --namespace istio-system get secrets
    {{< /text >}}

* configmaps in the `istio-system` namespace:

    {{< text bash >}}
    $ kubectl --namespace istio-system get cm -o yaml
    {{< /text >}}

* Current and previous logs from all Istio components and sidecars. Here some examples on how to obtain those, please adapt for your environment:

    * Istiod logs:

        {{< text bash >}}
        $ kubectl logs -n istio-system -l app=istiod
        {{< /text >}}

    * Ingress Gateway logs:

        {{< text bash >}}
        $ kubectl logs -l istio=ingressgateway -n istio-system
        {{< /text >}}

    * Egress Gateway logs:

        {{< text bash >}}
        $ kubectl logs -l istio=egressgateway -n istio-system
        {{< /text >}}

    * Sidecar logs:

        {{< text bash >}}
        $ for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}') ; do kubectl logs -l service.istio.io/canonical-revision -c istio-proxy -n $ns ; done
        {{< /text >}}

* All Istio configuration artifacts:

    {{< text bash >}}
    $ kubectl get istio-io --all-namespaces -o yaml
    {{< /text >}}

## Documentation bugs

Search our [documentation issue database](https://github.com/istio/istio.io/issues/) to see if
we already know about your problem and learn about when we think we can fix it. If you don't
find your problem in the database, please [report the issue there](https://github.com/istio/istio.io/issues/new).
If you want to submit a proposed edit to a page, you will find an "Edit this Page on GitHub"
link at the bottom right of every page.
