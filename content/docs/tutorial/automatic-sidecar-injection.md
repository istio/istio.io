---
title: Automatic sidecar injection
overview: Enable Istio sidecar injection automatically.

weight: 77

---

In this module you enable
[automatic sidecar injection](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection)
of Istio on your current namespace, so you would not need to use `istioctl` command and use the standard
Kubernetes CLI, `kubectl`. Once you enable automatic sidecar injection on your namespace, any newly deployed pod will
have Istio sidecar injected automatically.

1.  Label your current namespace to enable automatic sidecar injection:

    {{< text bash >}}
    $ kubectl label namespace $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}") istio-injection=enabled
    $ kubectl get namespace $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}") --show-labels
    NAME       STATUS    AGE       LABELS
    tutorial   Active    3d        istio-injection=enabled
    {{< /text >}}

1.  Test the automatic sidecar injection by redeploying your testing pod:

    {{< text bash >}}
    $ kubectl delete -f {{< github_file >}}/samples/sleep/sleep.yaml
    $ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
    serviceaccount "sleep" deleted
    service "sleep" deleted
    deployment "sleep" deleted
    serviceaccount "sleep" created
    service "sleep" created
    deployment "sleep" created
    {{< /text >}}

1.  Check the sleep pod and see that now it has two containers. Wait for the old pods to terminate:

    {{< text bash >}}
    $ kubectl get pods -l app=sleep
    NAME                    READY     STATUS    RESTARTS   AGE
    sleep-ccb8594c9-8pmz5   2/2       Running   0          2m
    {{< /text >}}

1.  Resend the request to `ratings` from your testing pod:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl http://ratings:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

    This time the request succeeds, since your testing pod now has an Istio sidecar that encrypts outgoing traffic for
    it.

From now on, all the new versions of your microservices will have Istio sidecars injected automatically.
