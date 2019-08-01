---
title: Setup
weight: 3
---

1. Install [curl](https://curl.haxx.se/download.html)

1. Install [Node.js](https://nodejs.org/en/download/)
    [Docker](https://docs.docker.com/install/) and get access to a [Kubernetes](https://kubernetes.io) cluster.
    For example, you can try [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) or
    [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/container-service).

1.  Create a shell variable to store the name of the namespace you will work with.

    {{< text bash >}}
    $ export NAMESPACE=tutorial
    {{< /text >}}

1.  Create a namespace for the tutorial, e.g.:

    {{< text bash >}}
    $ kubectl create namespace $NAMESPACE
    {{< /text >}}

1. [Install Istio with strict mutual TLS enabled](/docs/setup/kubernetes/install/kubernetes/).
    [these instructions](/docs/setup/kubernetes/install/kubernetes/).

1.  [Enable Envoy's access logging](/docs/tasks/telemetry/logs/access-log/#enable-envoy-s-access-logging).

1.  Download one of the [Istio release archives](https://github.com/istio/istio/releases) and extract
    the `istioctl` command line tool from it. The tool is in the `bin` directory of the archive.

    Verify that you can run `istioctl`:

    {{< text bash >}}
    $ istioctl version
    version.BuildInfo{Version:"release-1.1-20190214-09-16", GitRevision:"6113e155ac85e2485e30dfea2b80fd97afd3130a", User:"root", Host:"4496ae63-3039-11e9-86e9-0a580a2c0304", GolangVersion:"go1.10.4", DockerHub:"gcr.io/istio-release", BuildStatus:"Clean", GitTag:"1.1.0-snapshot.6-6-g6113e15"}
    {{< /text >}}

1.  **For cluster owners**: you may want to allocate a separate namespace per
    different participant. The tutorial supports work in multiple namespaces simultaneously by multiple participants.

1.  Create a Kubernetes Ingress resource for common Istio services:

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

1.  **For cluster owners**: you may want to limit the permissions of each
    participant so they will be able to create resources only in their namespace. Perform the following steps to achieve
    this:

    1.  Create a role to provide read access to `istio-system` namespace:

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

    1.  Create a service account for the user of the namespace and provide access to the namespace's resources to that
    service account:

        {{< text bash >}}
        $ kubectl apply -f - <<EOF
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: ${NAMESPACE}-user
          namespace: $NAMESPACE
        ---
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

    1.  Generate a Kube config file (`./${NAMESPACE}-user-config.yaml`) for the user of the namespace:

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

        You can send this Kube config file to a tutorial's participant. The participant will define the
        `KUBECONFIG` variable to store the location of the file, and as a result will have access to the tutorial's
        namespace only.

        A commnad to set `KUBECONFIG` to point to the generated configuration:

        {{< text bash >}}
        $ export KUBECONFIG=./${NAMESPACE}-user-config.yaml
        {{< /text >}}
