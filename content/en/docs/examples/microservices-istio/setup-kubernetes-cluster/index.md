---
title: Setup a Kubernetes Cluster
overview: Set up your Kubernetes cluster for the tutorial.
weight: 2
---

{{< boilerplate work-in-progress >}}

In this module, you set up a Kubernetes cluster that has Istio installed and a
namespace to use throughout the tutorial.

{{< warning >}}
If you are in a workshop and the instructors provide a cluster for you,
proceed to [setting up your local computer](/docs/examples/microservices-istio/setup-local-computer).
{{</ warning >}}

1.  Ensure you have access to a [Kubernetes cluster](https://kubernetes.io/docs/tutorials/kubernetes-basics/).
    You can use the [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/quickstart) or the
    [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started).

1.  Connect to your cluster and create an environment variable to store the name
    of a namespace that you will use when you run the tutorial commands.
    You can use any name, for example `tutorial`.

    {{< text bash >}}
    $ export NAMESPACE=tutorial
    {{< /text >}}

1.  Create the namespace:

    {{< text bash >}}
    $ kubectl create namespace $NAMESPACE
    {{< /text >}}

    {{< tip >}}
    If you are an instructor, you should allocate a separate namespace per each
    participant. The tutorial supports work in multiple namespaces
    simultaneously by multiple participants.
    {{< /tip >}}

1.  Install Istio with strict mutual TLS enabled by selecting the `strict mutual
    TLS` tab when you follow [the Kubernetes installation steps](/docs/setup/install/kubernetes/#installation-steps).

1.  [Enable Envoy's access logging](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging).

1.  Create a Kubernetes Ingress resource for these common Istio services using
    the `kubectl` command shown. It is not necessary to be familiar with each of
    these services at this point in the tutorial.

    - [Grafana](https://grafana.com/docs/guides/getting_started/)
    - [Jaeger](https://www.jaegertracing.io/docs/1.13/getting-started/)
    - [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
    - [Kiali](https://www.kiali.io/documentation/getting-started/)

    The `kubectl` command can accept an in-line configuration to create the
    Ingress resources for each service:

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

1.  Create a role to provide read access to the `istio-system` namespace. This
    role is required to limit permissions of the participants in the steps
    below.

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

1.  Create a service account for each participant:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    EOF
    {{< /text >}}

1.  Limit each participant's permissions. During the tutorial, participants only
    need to create resources in their namespace and to read resources from
    `istio-system` namespace. It is a good practice, even if using your own
    cluster, to avoid interfering with other namespaces in
    your cluster.

    Create a role to allow read-write access to each participant's namespace.
    Bind the participant's service account to this role and to the role for
    reading resources from `istio-system`:

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

1.  If you are setting up the cluster for yourself, copy the
    `${NAMESPACE}-user-config.yaml` file mentioned in the previous steps to your
    local computer, where `${NAMESPACE}` is the name of the namespace you
    provided in the previous steps. For example, `tutorial-user-config.yaml`.
    You will need this file later in the tutorial.

    If you are an instructor, send the generated configuration files to each
    participant who should copy it to their local computer.

Congratulations, you configured your cluster for the tutorials!

You are ready to [setup a local computer](/docs/examples/microservices-istio/setup-local-computer).
