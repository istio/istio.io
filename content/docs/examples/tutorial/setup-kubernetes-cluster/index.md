---
title: Setup Kubernetes cluster
overview: Set up your Kubernetes cluster for the tutorial.
weight: 2
---

{{< boilerplate work-in-progress >}}

Complete this module to set up a Kubernetes cluster that has Istio installed and a namespace for you to use throughout the tutorial.

{{< warning >}}
If you are participating in a workshop and the instructors provide a cluster for you,
go to [setting up your local computer](/docs/examples/tutorial/setup-local-computer).
{{</ warning >}}

1.  Ensure you have access to a [Kubernetes cluster](https://kubernetes.io/docs/tutorials/kubernetes-basics/).
    You can try using the [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/quickstart) or the
    [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started).

1.  Create an environment variable to store the name of a namespace to perform the commands of the tutorial on.
    You can use any name, for example `tutorial`, but `coolstuff` would do as well.

    {{< text bash >}}
    $ export NAMESPACE=tutorial
    {{< /text >}}

1.  Create the namespace:

    {{< text bash >}}
    $ kubectl create namespace $NAMESPACE
    {{< /text >}}

    {{< tip >}}
    If you run the tutorial for multiple participants (you are an instructor in a class or you want to complete this
    tutorial with your friends using your cluster), you may want to allocate a separate namespace per each
    participant. The tutorial supports work in multiple namespaces simultaneously by multiple participants.
    {{< /tip >}}

1.  Install Istio with strict mutual TLS enabled. Just remember to select the `strict mutual TLS` tab when you follow
    [the Kubernetes installation steps](/docs/setup/kubernetes/install/kubernetes/#installation-steps).

1.  [Enable Envoy's access logging](/docs/tasks/telemetry/logs/access-log/#enable-envoy-s-access-logging).

1.  Create a Kubernetes Ingress resource for the following common Istio services:

    - [Grafana](https://grafana.com/docs/guides/getting_started/)
    - [Jaeger](https://www.jaegertracing.io/docs/1.13/getting-started/)
    - [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
    - [Kiali](https://www.kiali.io/documentation/getting-started/)

    Have no clue what are the services above? Worry not! This tutorial has modules teaching you about each of them.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: istio-system
      namespace: istio-system
    spec:
      rules:
      - host: my-istio-dashboard.io
        http:
          paths:
          - path: /
            backend:
              serviceName: grafana
              servicePort: 3000
      - host: my-istio-tracing.io
        http:
          paths:
          - path: /
            backend:
              serviceName: tracing
              servicePort: 80
      - host: my-istio-logs-database.io
        http:
          paths:
          - path: /
            backend:
              serviceName: prometheus
              servicePort: 9090
      - host: my-kiali.io
        http:
          paths:
          - path: /
            backend:
              serviceName: kiali
              servicePort: 20001
    EOF
    {{< /text >}}

1.  Create a role to provide read access to the `istio-system` namespace. This role is required to limit permissions of
    the participants in the steps below.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1beta1
    metadata:
      name: istio-system-access
      namespace: istio-system
    rules:
    - apiGroups: ["", "extensions", "apps"]
      resources: ["*"]
      verbs: ["get", "list"]
    EOF
    {{< /text >}}

1.  Each participant needs a service account to represent their identity. Create a service account for each participant:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    EOF
    {{< /text >}}

1.  Limit each participant's permissions. During the tutorial, participants only need to create resources in their
    namespace and to read resources from `istio-system` namespace.
    It is a good practice even if using your own cluster to prevent your learning from interfering with other
    namespaces in your cluster.

    Create a role to allow read-write access to each participant's namespace and bind participant's service account
    to this role and to the role for reading resources from `istio-system`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1beta1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    rules:
    - apiGroups: ["", "extensions", "apps", "networking.k8s.io", "networking.istio.io", "authentication.istio.io",
                  "rbac.istio.io", "config.istio.io"]
      resources: ["*"]
      verbs: ["*"]
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1beta1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: ${NAMESPACE}-access
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1beta1
    metadata:
      name: ${NAMESPACE}-istio-system-access
      namespace: istio-system
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: istio-system-access
    EOF
    {{< /text >}}

1.  Each participant needs to use their own Kubernetes configuration file. This configuration file specifies
    the cluster details, the service account, the credentials and the namespace of the participant.
    The `kubectl` command uses the configuration file to operate on the cluster.

    Generate a Kubernetes configuration file for each participant:

    {{< text bash >}}
    $ cat <<EOF > ./${NAMESPACE}-user-config.yaml
    apiVersion: v1
    kind: Config
    preferences: {}

    clusters:
    - cluster:
        certificate-authority-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        server: $(kubectl config view -o jsonpath="{.clusters[?(.name==\"$(kubectl config view -o jsonpath="{.contexts[?(.name==\"$(kubectl config current-context)\")].context.cluster}")\")].cluster.server}")
      name: ${NAMESPACE}-cluster

    users:
    - name: ${NAMESPACE}-user
      user:
        as-user-extra: {}
        client-key-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        token: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath={.data.token} | base64 --decode)

    contexts:
    - context:
        cluster: ${NAMESPACE}-cluster
        namespace: ${NAMESPACE}
        user: ${NAMESPACE}-user
      name: ${NAMESPACE}

    current-context: ${NAMESPACE}
    EOF
    {{< /text >}}

1.  If you are an instructor, send the generated configuration file to each participant. If you are setting up the
    cluster for yourself, use the configuration file as described in the
    [local computer setup module](/docs/examples/tutorial/setup-local-computer) for more details.

You completed the setup of your cluster and can start the [setup of your local computer](/docs/examples/tutorial/setup-local-computer).
Once your local computer is set, you can [run your first service](/docs/examples/tutorial/single/)!
