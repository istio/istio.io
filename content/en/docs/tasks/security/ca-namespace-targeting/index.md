---
title: Configure Citadel Service Account Secret Generation
description: Configure which namespaces Citadel should generate service account secrets for.
weight: 80
---

For various reasons, a cluster operator might decide not to generate `Service Account` secrets for some subset of namespaces, or to make `Service Account` secret generation opt-in per namespace. This task describes how an operator can configure their cluster for these situations. Full documentation of the Citadel namespace targeting mechanism can be found [here](/docs/concepts/security/#how-citadel-determines-whether-to-create-service-account-secrets).

## Before you begin

To complete this task, you should first take the following actions:

* Read the [security concept](/docs/concepts/security/#how-citadel-determines-whether-to-create-service-account-secrets).

* Follow the [Kubernetes quick start](/docs/setup/install/kubernetes/) to install Istio using the **strict mutual TLS profile**.

### Deactivating Service Account secret generation for a single namespace

For this example, let's create a new sample namespace `foo`

{{< text bash >}}
$ kubectl create ns foo
{{< /text >}}

Since service account secrets are created as the default behavior, Citadel should have generated a key/cert secret for the default service account in the `foo` namespace. Let's verify this with

{{< text bash >}}
$ kubectl get secrets -n foo | grep istio.io
NAME                    TYPE                           DATA      AGE
istio.default           istio.io/key-and-cert          3         13s
{{< /text >}}

Suppose we'd like to prevent Citadel from creating `ServiceAccount` secrets in target namespace `foo`. This can be done through labeling the namespace with

{{< text bash >}}
$ kubectl label ns foo ca.istio.io/override=false
{{< /text >}}

Now, if we create a new `ServiceAccount` in this namespace with

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sample-service-account
  namespace: foo
EOF
{{< /text >}}

and then check the namespace secrets again

{{< text bash >}}
$ kubectl get secrets -n foo | grep istio.io
NAME                    TYPE                           DATA      AGE
istio.default           istio.io/key-and-cert          3         11m
{{< /text >}}

We can observe that no new `istio.io/key-and-cert` secret was generated for the `sample-service-account` service account.

### Opt-in Service Account secret generation

Let's suppose that as an operator, we would like to make `ServiceAcount` secret generation opt-in (i.e. don't generate secrets unless otherwise specified). In this case we should set the following in our helm chart configuration

{{< text yaml >}}
...
security:
    enableNamespacesByDefault: false
...
{{< /text >}}

Once this mesh configuration is applied, create a namespace `foo`, and check the secrets present in that namespace

{{< text bash >}}
$ kubectl create ns foo
$ kubectl get secrets -n foo | grep istio.io
{{< /text >}}

There should be no output from `kubectl get secrets -n foo`, as we configured the cluster not to generate `istio.io/key-and-cert` secrets by default. Now, to override this value on the `foo` namespace, label it with

{{< text bash >}}
$ kubectl label ns foo ca.istio.io/override=true
{{< /text >}}

and then create a new service account in the `foo` namespace with

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sample-service-account
  namespace: foo
EOF
{{< /text >}}

Now, let's examine the secrets in the `foo` namespace again

{{< text bash >}}
$ kubectl get secrets -n foo | grep istio.io
NAME                                 TYPE                                  DATA   AGE
istio.default                        istio.io/key-and-cert                 3      47s
istio.sample-service-account         istio.io/key-and-cert                 3      6s
{{< /text >}}

Notice that despite only having created the `sample-service-account` service account after activating the namespace, there is an `istio.io/key-and-cert` secret for the `default` namespace as well. This is due to the retroactive secret generation feature, which will create secrets for all service accounts in a namespace once it transitions from `inactive` to `active`.

## Cleanup

{{< text bash >}}
$ kubectl delete ns foo
{{< /text >}}