---
title: Reporting Bugs
description: What to do if you find a bug.
weight: 34
aliases:
    - /bugs.html
    - /bugs/index.html
    - /help/bugs/
icon: bugs
---

Oh no! You found a bug? We'd love to hear about it.

## Product bugs

Search our [issue database](https://github.com/istio/istio/issues/) to see if
we already know about your problem and learn about when we think we can fix
it. If you don't find your problem in the database, please open a [new
issue](https://github.com/istio/istio/issues/new/choose) and let us know
what's going on.

If you think a bug is in fact a security vulnerability, please visit [Reporting Security Vulnerabilities](/pt-br/about/security-vulnerabilities/)
to learn what to do.

### Kubernetes cluster state archives

If you're running on Kubernetes, consider including a cluster state
archive with your bug report.
For convenience, you can run a dump script to produce an archive containing
all of the relevant state from your Kubernetes cluster:

* Run via `curl`:

    {{< text bash >}}
    $ curl {{< github_file >}}/tools/dump_kubernetes.sh | sh -s -- -z
    {{< /text >}}

* Run locally, from the release directory's root:

    {{< text bash >}}
    $ @tools/dump_kubernetes.sh@ -z
    {{< /text >}}

Then attach the produced `istio-dump.tar.gz` with your reported problem.

If you are unable to use the dump script, please attach your own archive
containing:

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

* Current and previous logs from all Istio components and sidecar

* Mixer logs:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=mixer -c mixer
    $ kubectl logs -n istio-system -l istio=policy -c mixer
    $ kubectl logs -n istio-system -l istio=telemetry -c mixer
    {{< /text >}}

* Pilot logs:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=pilot -c discovery
    $ kubectl logs -n istio-system -l istio=pilot -c istio-proxy
    {{< /text >}}

* All Istio configuration artifacts:

    {{< text bash >}}
    $ kubectl get $(kubectl get crd  --no-headers | awk '{printf "%s,",$1}END{printf "attributemanifests.config.istio.io\n"}') --all-namespaces
    {{< /text >}}

## Documentation bugs

Search our [documentation issue database](https://github.com/istio/istio.io/issues/) to see if
we already know about your problem and learn about when we think we can fix
it. If you don't find your problem in the database, please navigate to the page
with the problem, then select the gear menu at the
top right of this page, and finally chose *Report a Site Bug*.
