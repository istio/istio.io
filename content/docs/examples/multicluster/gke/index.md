---
title: Google Kubernetes Engine
description: Set up a multicluster mesh over two GKE clusters.
weight: 65
keywords: [kubernetes,multicluster]
---

This example shows how to configure a multicluster mesh with a
[single control plane topology](/docs/concepts/multicluster-deployments/#single-control-plane-topology)
over 2 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) clusters.

## Before you begin

In addition to the prerequisites for installing Istio the following setup is required for this example:

* This sample requires a valid Google Cloud Platform project with billing enabled. If you are
  not an existing GCP user, you may be able to enroll for a $300 US [Free Trial](https://cloud.google.com/free/) credit.

    * [Create a Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) to
      host your GKE clusters.

* Install and initialize the [Google Cloud SDK](https://cloud.google.com/sdk/install)

## Create the GKE Clusters

1.  Set the default project for `gcloud` to perform actions on:

    {{< text bash >}}
    $ gcloud config set project myProject
    $ proj=$(gcloud config list --format='value(core.project)')
    {{< /text >}}

1.  Create 2 GKE clusters for use with the multicluster feature.  _Note:_ `--enable-ip-alias` is required to
    allow inter-cluster direct pod-to-pod communication.  The `zone` value must be one of the
    [GCP zones](https://cloud.google.com/compute/docs/regions-zones/).

    {{< text bash >}}
    $ zone="us-east1-b"
    $ cluster="cluster-1"
    $ gcloud container clusters create $cluster --zone $zone --username "admin" \
      --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
      --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
    "https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
    "https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
    "https://www.googleapis.com/auth/trace.append" \
    --num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async
    $ cluster="cluster-2"
    $ gcloud container clusters create $cluster --zone $zone --username "admin" \
      --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
      --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
    "https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
    "https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
    "https://www.googleapis.com/auth/trace.append" \
    --num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async
    {{< /text >}}

1.  Wait for clusters to transition to the `RUNNING` state by polling their statuses via the following command:

    {{< text bash >}}
    $ gcloud container clusters list
    {{< /text >}}

1.  Get the clusters' credentials ([command details](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)):

    {{< text bash >}}
    $ gcloud container clusters get-credentials cluster-1 --zone $zone
    $ gcloud container clusters get-credentials cluster-2 --zone $zone
    {{< /text >}}

1.  Validate `kubectl` access to each cluster and create a `cluster-admin` cluster role binding tied to the Kubernetes credentials associated with your GCP user.

    1.  For cluster-1:

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
        $ kubectl get pods --all-namespaces
        $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
        {{< /text >}}

    1.  For cluster-2:

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
        $ kubectl get pods --all-namespaces
        $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
        {{< /text >}}

## Create a Google Cloud firewall rule

To allow the pods on each cluster to directly communicate, create the following rule:

{{< text bash >}}
$ function join_by { local IFS="$1"; shift; echo "$*"; }
$ ALL_CLUSTER_CIDRS=$(gcloud container clusters list --format='value(clusterIpv4Cidr)' | sort | uniq)
$ ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}"))
$ ALL_CLUSTER_NETTAGS=$(gcloud compute instances list --format='value(tags.items.[0])' | sort | uniq)
$ ALL_CLUSTER_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))
$ gcloud compute firewall-rules create istio-multicluster-test-pods \
  --allow=tcp,udp,icmp,esp,ah,sctp \
  --direction=INGRESS \
  --priority=900 \
  --source-ranges="${ALL_CLUSTER_CIDRS}" \
  --target-tags="${ALL_CLUSTER_NETTAGS}" --quiet
{{< /text >}}

## Install the Istio control plane

The following generates an Istio installation manifest, installs it, and enables automatic sidecar injection in
the `default` namespace:

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ cat install/kubernetes/helm/istio-init/files/crd-* > $HOME/istio_master.yaml
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system >> $HOME/istio_master.yaml
$ kubectl create ns istio-system
$ kubectl apply -f $HOME/istio_master.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

Wait for pods to come up by polling their statuses via the following command:

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

## Generate remote cluster manifest

1.  Get the IPs of the control plane pods:

    {{< text bash >}}
    $ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
    $ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
    $ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
    {{< /text >}}

1.  Generate remote cluster manifest:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio \
      --namespace istio-system --name istio-remote \
      --values @install/kubernetes/helm/istio/values-istio-remote.yaml@ \
      --set global.remotePilotAddress=${PILOT_POD_IP} \
      --set global.remotePolicyAddress=${POLICY_POD_IP} \
      --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

## Install remote cluster manifest

The following installs the minimal Istio components and enables automatic sidecar injection on
the namespace `default` in the remote cluster:

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
$ kubectl create ns istio-system
$ kubectl apply -f $HOME/istio-remote.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

## Create remote cluster's kubeconfig for Istio Pilot

The `istio-remote` Helm chart creates a service account with minimal access for use by Istio Pilot
discovery.

1.  Prepare environment variables for building the `kubeconfig` file for the service account `istio-multi`:

    {{< text bash >}}
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o "jsonpath={.clusters[].name}")
    $ CLUSTER_NAME="${CLUSTER_NAME##*_}"
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ NAMESPACE=istio-system
    $ SERVICE_ACCOUNT=istio-multi
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< tip >}}
    An alternative to `base64 --decode` is `openssl enc -d -base64 -A` on many systems.
    {{< /tip >}}

1.  Create a `kubeconfig` file in the working directory for the service account `istio-multi`:

    {{< text bash >}}
    $ cat <<EOF > ${KUBECFG_FILE}
    apiVersion: v1
    clusters:
       - cluster:
           certificate-authority-data: ${CA_DATA}
           server: ${SERVER}
         name: ${CLUSTER_NAME}
    contexts:
       - context:
           cluster: ${CLUSTER_NAME}
           user: ${CLUSTER_NAME}
         name: ${CLUSTER_NAME}
    current-context: ${CLUSTER_NAME}
    kind: Config
    preferences: {}
    users:
       - name: ${CLUSTER_NAME}
         user:
           token: ${TOKEN}
    EOF
    {{< /text >}}

At this point, the remote clusters' `kubeconfig` files have been created in the `${WORK_DIR}` directory.
The filename for a cluster is the same as the original `kubeconfig` cluster name.

## Configure Istio control plane to discover the remote cluster

Create a secret and label it properly for each remote cluster:

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

## Deploy Bookinfo Example Across Clusters

1.  Install Bookinfo on the first cluster.  Remove the `reviews-v3` deployment to deploy on remote:

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1.  Create the `reviews-v3.yaml` manifest for deployment on the remote:

    {{< text syntax="yaml" downloadas="reviews-v3.yaml" >}}
    ---
    ##################################################################################################
    # Ratings service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: ratings
      labels:
        app: ratings
    spec:
      ports:
      - port: 9080
        name: http
    ---
    ##################################################################################################
    # Reviews service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: reviews
      labels:
        app: reviews
    spec:
      ports:
      - port: 9080
        name: http
      selector:
        app: reviews
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: reviews-v3
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: reviews
            version: v3
        spec:
          containers:
          - name: reviews
            image: istio/examples-bookinfo-reviews-v3:1.5.0
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    {{< /text >}}

    _Note:_ The `ratings` service definition is added to the remote cluster because `reviews-v3` is a
    client of `ratings` and creating the service object creates a DNS entry.  The Istio sidecar in the
    `reviews-v3` pod will determine the proper `ratings` endpoint after the DNS lookup is resolved to a
    service address.  This would not be necessary if a multicluster DNS solution were additionally set up, e.g. as
    in a federated Kubernetes environment.

1.  Install the `reviews-v3` deployment on the remote.

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
    $ kubectl apply -f $HOME/reviews-v3.yaml
    {{< /text >}}

1.  Get the `istio-ingressgateway` service's external IP to access the `bookinfo` page to validate that Istio
    is including the remote's `reviews-v3` instance in the load balancing of reviews versions:

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
    $ kubectl get svc istio-ingressgateway -n istio-system
    {{< /text >}}

    Access `http://<GATEWAY_IP>/productpage` repeatedly and each version of reviews should be equally loadbalanced,
    including `reviews-v3` in the remote cluster (red stars).  It may take several accesses (dozens) to demonstrate
    the equal loadbalancing between `reviews` versions.

## Uninstalling

The following should be done in addition to the uninstall of Istio as described in the
[VPN-based multicluster uninstall section](/docs/setup/kubernetes/install/multicluster/vpn/):

1.  Delete the Google Cloud firewall rule:

    {{< text bash >}}
    $ gcloud compute firewall-rules delete istio-multicluster-test-pods --quiet
    {{< /text >}}

1.  Delete the `cluster-admin` cluster role binding from each cluster no longer being used for Istio:

    {{< text bash >}}
    $ kubectl delete clusterrolebinding gke-cluster-admin-binding
    {{< /text >}}

1.  Delete any GKE clusters no longer in use.  The following is an example delete command for the remote cluster, `cluster-2`:

    {{< text bash >}}
    $ gcloud container clusters delete cluster-2 --zone $zone
    {{< /text >}}
