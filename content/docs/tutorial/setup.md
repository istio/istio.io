---
title: Setup
weight: 2
---

1.  Install [curl](https://curl.haxx.se/download.html), [node.js](https://nodejs.org/en/download/), [Docker](https://docs.docker.com/install/)
and get access to a [Kubernetes](https://kubernetes.io) cluster.
For example, you can try [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) or [IBM Cloud Container Service](https://console.bluemix.net/docs/containers/container_index.html#container_index).

1.  Create a namespace for the tutorial, e.g.:

    {{< text bash >}}
    $ kubectl create namespace tutorial
    {{< /text >}}

1.  Create a shell variable to store the name of the namespace. All the commands in this tutorial will use this variable
    so only the tutorial's namespace will be affected.

    {{< text bash >}}
    $ export NAMESPACE=tutorial
    {{< /text >}}

1.  If you do not have Istio installed in your cluster, install it with mutual TLS enabled, following
    [these instructions](/docs/setup/kubernetes/helm-install/).

1.  **For instructors**: you may want to allocate a separate namespace per different participant. The tutorial supports
    work in multiple namespaces simultaneously by multiple participants.

1.  **For instructors**: you may want to limit the permissions of each participant so they will be able to create
    resources only in their namespace. Perform the following steps to achieve this:

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
        - apiGroups: ["", "extensions", "apps"]
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
            server: $(kubectl config view -o jsonpath={.clusters..server})
          name: ${NAMESPACE}-cluster

        users:
        - name: ${NAMESPACE}-user
          user:
            as-user-extra: {}
            client-key-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
            token: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath={.data.token} | base64 -D)

        contexts:
        - context:
            cluster: ${NAMESPACE}-cluster
            namespace: ${NAMESPACE}
            user: ${NAMESPACE}-user
          name: ${NAMESPACE}

        current-context: ${NAMESPACE}
        EOF
        {{< /text >}}

        You can send this Kube config file to the tutorial's participant. The participant will define the
        `KUBECONFIG` variable to store the location of the file, and as a result will have access to the tutorial's
        namespace only.
