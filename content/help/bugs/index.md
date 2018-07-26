---
title: Reporting Bugs
description: What to do when you find a bug
weight: 35
aliases:
    - /bugs.html
    - /bugs/index.html
---

Oh no! You found a bug?

Search our [issue database](https://github.com/istio/istio/issues/) to see if
we already know about your problem and learn about when we think we can fix
it. If you don't find your problem in the database, please open a [new
issue](https://github.com/istio/istio/issues/new/choose) and let us know
what's going on.

If you're running on Kubernetes, consider including a [cluster state
archive](#generating-a-cluster-state-archive) in your bug report.

## Generating a cluster state archive

For convenience, you can run a dump script to produce an archive containing
all of the needed state from your Kubernetes cluster:

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
  `kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml`
* Secret names in `istio-system`:
  `kubectl --namespace istio-system get secrets`
* Config maps in `istio-system`:
  `kubectl --namespace istio-system get cm -o yaml`
* Current and previous logs from all istio components and sidecar
* Mixer logs:
    * `kubectl logs -n istio-system -l istio=mixer -c mixer`
    * `kubectl logs -n istio-system -l istio=policy -c mixer`
    * `kubectl logs -n istio-system -l istio=telemetry -c mixer`
* Pilot logs:
    * `kubectl logs -n istio-system -l istio=pilot -c discovery`
    * `kubectl logs -n istio-system -l istio=pilot -c istio-proxy`
* All Istio configuration artifacts.
    * `kubectl get $(kubectl get crd  --no-headers | awk '{printf "%s,",$1}END{printf "attributemanifests.config.istio.io\n"}') --all-namespaces`
