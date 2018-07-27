---
title: Sidecar injection
description: Describes Istio's use of Kubernetes webhooks for automatic sidecar injection
weight: 10
---

## Overview

Automatic sidecar injection adds the sidecar proxy into user created
pods. It uses a `MutatingWebhook` to append the sidecar’s containers
and volumes to each pod’s template spec during creation
time. Injection can be scoped to particular sets of namespaces using
the webhooks `namespaceSelector` mechanism (see webhook overview below).
Injection can also be enabled and disabled per-pod with an annotation.

## Troubleshooting guide

1. Verify the mutatingwebhookconfiguration exists and is
   correct. Inline _comments_ are added for clarification.

    {{< text bash >}}

    $ kubectl get mutatingwebhookconfiguration -o yaml
    apiVersion: admissionregistration.Kubernetes.io/v1beta1
    kind: MutatingWebhookConfiguration
    metadata:
      labels:
        app: istio-sidecar-injector
      name: istio-sidecar-injector
      webhooks:
      - clientConfig:
          # caBundle should be non-empty. This is periodically (re)patched
          # every second by the webhook service using the ca-cert
          # from the mounted service account secret.
          caBundle: <base64 encoded>
          # service corresponds to the Kubernetes service that implements the
          # webhook, e.g. istio-sidecar-injector.istio-system.svc:443
          service:
            name: istio-sidecar-injector
            namespace: istio-system
            path: /inject
        failurePolicy: Fail
        name: sidecar-injector.istio.io
        # webhook only invoked when objects in namespace matches the selector. In
        # this case, the sidecar injector webhook is invoked for pods created
        # in namespace labeled with `istio-injection=enabled`
        namespaceSelector:
          matchLabels:
            istio-injection: enabled
        # The webhook is invoked when pods are created. Pods are effectively
        # immutable (modifying the pod template requires
        # re-creating the pod).
        Rules:
        - apiGroups:
          - ""
          apiVersions:
          - v1
          operations:
          - CREATE
          resources:
          - pods

    {{< /text >}}

    If the configuration doesn’t exist:

    * If you're using `helm template` or `helm install`, verify the
      `--set sidecarInjectorWebhook.enabled` option is set.

    * If you're using a pre-generated YAML file, verify the
      `istio-sidecar-injector mutatingwebhookconfiguration` resource
      is present. If it isn't, use `helm template` to generate the
      correct install file (see above).

    The sidecar injector configuration is fail closed. If
    configuration exists and is scoped properly, the webhook will be
    invoked. A missing caBundle, bad cert, or network connectivity
    problem will produce an error message when the resource is
    created/updated. If you don’t see any error message and the
    webhook wasn’t invoked and the webhook configuration is valid,
    your cluster is mis-configured.

1. Verify the sidecar injector pod(s) are running

    {{< text bash >}}

    $ kubectl -n istio-system get pod -listio=sidecar-injector
    NAME                                      READY     STATUS    RESTARTS   AGE
    istio-sidecar-injector-5b96dbffdd-wg47d   1/1       Running   0          2d

    {{< /text >}}

1. Verify you’re using Istio version >= 1.0.0. Older version of the
   injector did not properly re-patch the caBundle. This typically
   happened when the istio.yaml was re-applied, overwriting a
   previously patched caBundle.

    {{< text bash >}}

    $ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o jsonpath='{.items[*].metadata.name}'); do \
      kubectl -n istio-system exec ${pod} -it /usr/local/bin/sidecar-injector version| grep ^Version; \
    done
    Version: 1.0.0

    {{< /text>}}

1. Check the sidecar injector pod logs for errors. Failing to patch the caBundle should print an error.

    {{< text bash >}}

    $ for pod in $(kubectl -n istio-system get pod -listio=sidecar-injector -o jsonpath='{.items[*].metadata.name}'); do \
      kubectl -n istio-system logs ${pod} \
    done

    {{< /text >}}

1. If the patching failed, verify the RBAC configuration for the
   sidecar injector. It requires `get`, `list`, `watch`, and `patch`
   VERBs on the mutatingwebhookconfiguration.

    {{< text bash >}}

    $ kubectl get clusterrole istio-sidecar-injector-istio-system -o yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      labels:
        app: istio-sidecar-injector
      name: istio-sidecar-injector-istio-system
    rules:
    - apiGroups:
      - '*'
      resources:
      - configmaps
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - admissionregistration.k8s.io
      resources:
      - mutatingwebhookconfigurations
      verbs:
      - get
      - list
      - watch
      - patch

    {{< /text >}}

1. Verify the istio-sidecar-injector ConfigMap

    {{< text bash >}}

    $ kubectl -n istio-system get configmap istio-sidecar-injector -o jsonpath='{.data.config}'|head
    policy: enabled
    template: |-
      initContainers:
      - name: istio-init
        image: "docker.io/jasonayoung/proxy_init:89601486a2d3c78766ca15e05c4288110666bd2a"
        args:
        - "-p"
        - [[ .MeshConfig.ProxyListenPort ]]
        - "-u"
        - 1337
        (... snip ...)

    {{< /text >}}

    The sidecar injector ConfigMap contains two fields:

    * **_policy_**: The default policy for whether a sidecar should be injected by
      default. Allowed values are `disabled` and `enabled`. The
      default policy only applies if the webhook’s `namespaceSelector`
      matches the target namespace.

      The policy can be overwritten with the `sidecar.istio.io/inject`
      annotation in the pod template spec’s metadata. Annotation value
      of `true` forces the sidecar to be injected while a value of
      `false` forces the sidecar to _not_ be injected. The
      deployment’s metadata is ignored.

    * **_template_**: The sidecar injection template. The template uses
      [https://golang.org/pkg/text/template](https://golang.org/pkg/text/template)
      to represent a list of resources that are injected into the
      user’s pod. The template is applied to the SidecarTemplateData
      define below which is derived from the user’s pod and `istio`
      ConfigMap:

    {{< text golang >}}

    type SidecarTemplateData struct {
        ObjectMeta  *metav1.ObjectMeta
        Spec        *v1.PodSpec
        ProxyConfig *meshconfig.ProxyConfig  // https://istio.io/docs/reference/config/service-mesh.html#proxyconfig
        MeshConfig  *meshconfig.MeshConfig   // https://istio.io/docs/reference/config/service-mesh.html#meshconfig
    }

    {{< /text >}}

    The executed template results in a string which is decoded to the
    following data structure. These containers, volumes, and
    imagePullSecrets are appended to the user’s pod.

    {{< text golang >}}

    type SidecarInjectionSpec struct {
        InitContainers   []v1.Container            `yaml:"initContainers"`
        Containers       []v1.Container            `yaml:"containers"`
        Volumes          []v1.Volume               `yaml:"volumes"`
        ImagePullSecrets []v1.LocalObjectReference `yaml:"imagePullSecrets"`
    }

    {{< /text >}}

1. Verify the sidecar injector pod has loaded the injection configuration

    {{< text bash >}}

    $ kubectl -n istio-system logs istio-sidecar-injector-645c89bc64-99gq7
    2018-07-10T20:09:52.916875Z     info    version <... binary image ...>
    2018-07-10T20:09:52.925384Z     info    New configuration: sha256sum <.. hash of file contents ..>
    2018-07-10T20:09:52.925423Z     info    Policy: enabled
    2018-07-10T20:09:52.925456Z     info    Template: |

     initContainers:
      - name: istio-init
        image: docker.io/istio/proxy_init:0.8.0
        args:
        - "-p"
        <... snip ...>

    {{< /text >}}

The sidecar-injector will automatically re-load the
istio-sidecar-injector configmap when it changes. A sha256 sum hash of
the file contents are logged along with the policy and template.

### Common automatic sidecar injection errors

1. Pods cannot be created at all with automatic injection

    A) x509 certificate related errors

    Run `kubectl describe -n <namespace> deployment <name> on the
    failing pod's deployment. Failure to invoke the injection webhook
    will typically will be captured in the event log, e.g.

    ```

    Warning  FailedCreate  3m (x17 over 8m)  replicaset-controller  Error creating: Internal error occurred: \
        failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: \
        x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying \
        to verify candidate authority certificate "Kubernetes.cluster.local")

    ```

    `x509: certificate signed by unknown authority` related errors are
    typically caused by an empty caBundle in the webhook
    configuration. Verify that it is non-empty (see "verify webhook
    configuration" above).

    In theory, the caBundle could be out of date with what the
    injector is used if multiple webhook replicas are in use. This
    should be a transient error state if the CA cert is rotated or
    install is re-installed.

    B) `no such hosts` and `no endpoints available` for webhook service.

    The sidecar injector is fail close. If the injector pod is not
    ready, pods cannot be created.  In such cases you’ll see an error
    about `no such host` (Kubernetes 1.9) or `no endpoints available`
    (>=1.10) in the deployment event log  if no webhook pods are ready / healthy.

    * Kubernetes 1.9

    ```

    Internal error occurred: failed calling admission webhook "sidecar-injector.istio.io": \
        Post https://istio-sidecar-injector.istio-system.svc:443/inject: dial tcp: lookup \
        istio-sidecar-injector.istio-system.svc on 169.254.169.254:53: no such host

    ```

    * Kubernetes 1.10

    ```

    Internal error occurred: failed calling admission webhook "sidecar-injector.istio.io": \
        Post https://istio-sidecar-injector.istio-system.svc:443/inject?timeout=30s: \
        no endpoints available for service "istio-sidecar-injector"

    ```

    * Verify one or more webhook pods and endpoints exist

        {{< text bash >}}

        $ kubectl -n istio-system get endpoints istio-sidecar-injector
        NAME                     ENDPOINTS         AGE
        istio-sidecar-injector   10.48.7.124:443   3d

        {{< /text >}}

    * Verify the pods are healthy

        {{< text bash >}}

        $ kubectl -n istio-system get pod -listio=sidecar-injector
        NAME                                      READY     STATUS    RESTARTS   AGE
        istio-sidecar-injector-5b96dbffdd-wg47d   1/1       Running   0          2d

        {{< /text >}}

1. Pods are created successfully without sidecar proxy.

    * Verify the webhook configuration exists (see above)

    * Verify the namespace is labeled correctly per the webhook
      configuration’s namespaceSelector.

    {{< text bash >}}

    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d       enabled
    istio-system   Active    3d        disabled
    kube-public    Active    18d
    kube-system    Active    18d

    {{< /text >}}

    * Verify the pod doesn’t have the `sidecar.istio.io/inject` annotation with value of `false`.

    {{< text bash >}}

    $ kubectl get pod <pod-name> -o jsonpath='{.metadata.annotations.sidecar\.istio\.io\/inject}'

    {{< /text >}}
