---
title: Istio Setup in Kubernetes
description: Instructions to setup the Istio service mesh in a Kubernetes cluster.
weight: 10
keywords: [kubernetes]
---

Follow these instructions to install and configure Istio in a Kubernetes
cluster.

## Prerequisites

The following instructions require:

* Access to a Kubernetes **1.9 or newer** cluster with
  [RBAC (Role-Based Access Control)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
  enabled.
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) **1.9 or
  newer** installed. Version **1.10** is recommended.

  > If you installed Istio 0.2.x,
  > [uninstall](https://archive.istio.io/v0.2/docs/setup/kubernetes/quick-start#uninstalling)
  > it completely before installing the newer version. Remember to uninstall
  > the Istio sidecar for all Istio enabled application pods too.

## Platform setup

This section describes the setup in different platforms.

### Setup Minikube

1. To install Istio locally, install the latest version of
   [Minikube](https://kubernetes.io/docs/setup/minikube/), version **0.28.0 or
   later**.

1. Select a
   [VM driver](https://kubernetes.io/docs/setup/minikube/#quickstart)
   and substitute `your_vm_driver_choice` below with the installed virtual
   machine (VM) driver.

    On Kubernetes **1.9**:

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.9.4 \
    --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

    On Kubernetes **1.10**:

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.10.0 \
    --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

### Google Kubernetes Engine

1. Create a new cluster.

    {{< text bash >}}
    $ gcloud container clusters create <cluster-name> \
      --cluster-version=1.10.5-gke.0 \
      --zone <zone> \
      --project <project-id>
    {{< /text >}}

1. Retrieve your credentials for `kubectl`.

    {{< text bash >}}
    $ gcloud container clusters get-credentials <cluster-name> \
        --zone <zone> \
        --project <project-id>
    {{< /text >}}

1. Grant cluster administrator (admin) permissions to the current user. To
   create the necessary RBAC rules for Istio, the current user requires admin
   permissions.

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}

### IBM Cloud Kubernetes Service (IKS)

1. Create a new lite cluster.

    {{< text bash >}}
    $ bx cs cluster-create --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

    Alternatively, you can create a new paid cluster:

    {{< text bash >}}
    $ bx cs cluster-create --location location --machine-type u2c.2x4 \
      --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

1. Retrieve your credentials for `kubectl`. Replace `<cluster-name>` with the
   name of the cluster you want to use:

    {{< text bash >}}
    $(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
    {{< /text >}}

### IBM Cloud Private

[Configure the kubectl CLI](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html)
to access the IBM Cloud Private Cluster.

### OpenShift Origin

By default, OpenShift doesn't allow containers running with user ID (UID) 0.

Enable containers running with UID 0 for Istio's service accounts:

{{< text bash >}}
$ oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid -z default -n istio-system
$ oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-egressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-ingressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-cleanup-old-ca-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-sidecar-injector-service-account -n istio-system
{{< /text >}}

The list above accounts for the default Istio service accounts. If you enabled
other Istio services, like _Grafana_ for example, you need to enable its
service account with a similar command.

A service account that runs application pods needs privileged security context
constraints as part of sidecar injection.

{{< text bash >}}
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
{{< /text >}}

> Check for `SELINUX` in this [discussion](https://github.com/istio/issues/issues/34)
> with respect to Istio in case you see issues bringing up the Envoy.

### AWS with Kops

When you install a new cluster with Kubernetes version 1.9, the prerequisite to
enable `admissionregistration.k8s.io/v1beta1` is covered.

Nevertheless, you must update the list of admission controllers.

1. Open the configuration file:

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. Add the following in the configuration file:

    {{< text yaml >}}
    kubeAPIServer:
        admissionControl:
        - NamespaceLifecycle
        - LimitRanger
        - ServiceAccount
        - PersistentVolumeLabel
        - DefaultStorageClass
        - DefaultTolerationSeconds
        - MutatingAdmissionWebhook
        - ValidatingAdmissionWebhook
        - ResourceQuota
        - NodeRestriction
        - Priority
    {{< /text >}}

1. Perform the update:

    {{< text bash >}}
    $ kops update cluster
    $ kops update cluster --yes
    {{< /text >}}

1. Launch the rolling update:

    {{< text bash >}}
    $ kops rolling-update cluster
    $ kops rolling-update cluster --yes
    {{< /text >}}

1. Validate the update with the `kubectl` client on the `kube-api` pod, you
   should see new admission controller:

    {{< text bash >}}
    $ for i in `kubectl \
      get pods -nkube-system | grep api | awk '{print $1}'` ; \
      do  kubectl describe pods -nkube-system \
      $i | grep "/usr/local/bin/kube-apiserver"  ; done
    {{< /text >}}

1. Review the output:

    {{< text plain >}}
    [...]
    --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,
    PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,
    MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,
    NodeRestriction,Priority
    [...]
    {{< /text >}}

### Azure

You must use `ACS-Engine` to deploy your cluster.

1. Follow the instructions to get and install the `acs-engine` binary with
   [their instructions](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#install).

1. Download Istio's `api model definition`:

    {{< text bash >}}
    $ wget https://raw.githubusercontent.com/Azure/acs-engine/master/examples/service-mesh/istio.json
    {{< /text >}}

1. Deploy your cluster using the `istio.json` template. You can find references
   to the parameters in the
   [official docs](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/deploy.md#step-3-edit-your-cluster-definition).

    | Parameter                             | Expected value             |
    |---------------------------------------|----------------------------|
    | `subscription_id`                     | Azure Subscription Id      |
    | `dns_prefix`                          | Cluster DNS Prefix         |
    | `location`                            | Cluster Location           |

    {{< text bash >}}
    $ acs-engine deploy --subscription-id <subscription_id> \
      --dns-prefix <dns_prefix> --location <location> --auto-suffix \
      --api-model istio.json
    {{< /text >}}

    > After a few minutes, you can find your cluster on your Azure subscription
    > in a resource group called `<dns_prefix>-<id>`. Assuming `dns_prefix` has
    > the value `myclustername`, a valid resource group with a unique cluster
    > ID is `mycluster-5adfba82`. The `acs-engine` generates your `kubeconfig`
    > file in the `_output` folder.

1. Use the `<dns_prefix>-<id>` cluster ID, to copy your `kubeconfig` to your
   machine from the `_output` folder:

    {{< text bash >}}
    $ cp _output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json \
        ~/.kube/config
    {{< /text >}}

    For example:

    {{< text bash >}}
    $ cp _output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json \
      ~/.kube/config
    {{< /text >}}

1. Check if the right Istio flags were deployed:

    {{< text bash >}}
    $ kubectl describe pod --namespace kube-system
    $(kubectl get pods --namespace kube-system | grep api | cut -d ' ' -f 1) \
      | grep admission-control
    {{< /text >}}

1. Confirm the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook`
   flags are present:

    {{< text plain >}}
    --admission-control=...,MutatingAdmissionWebhook,...,
    ValidatingAdmissionWebhook,...
    {{< /text >}}

## Download and prepare for the installation

Istio is installed in its own `istio-system` namespace and can manage
services from all other namespaces.

1.  Go to the [Istio release](https://github.com/istio/istio/releases) page to
    download the installation file corresponding to your OS. On a macOS or
    Linux system, you can run the following command to download and
    extract the latest release automatically:

    {{< text bash >}}
    $ curl -L https://git.io/getLatestIstio | sh -
    {{< /text >}}

1.  Move to the Istio package directory . For example, if the package is
    istio-{{< istio_version >}}.0:

    {{< text bash >}}
    $ cd istio-{{< istio_version >}}.0
    {{< /text >}}

    The installation directory contains:

    * Installation `.yaml` files for Kubernetes in `install/`
    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is
      used when manually injecting Envoy as a sidecar proxy and for creating
      routing rules and policies.
    * The `istio.VERSION` configuration file

1.  Add the `istioctl` client to your PATH environment variable, on a macOS or
    Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Installation steps

To install Istio's core components you can choose one of the following four
**mutually exclusive** options.

However, we recommend you to install with the
[Helm Chart](/docs/setup/kubernetes/helm-install/) for production
installations of Istio. With this installation, you can leverage all the
options to configure and customize Istio to your needs.

### Option 1: Install Istio without mutual TLS authentication between sidecars

Visit our
[mutual TLS authentication between sidecars concept page](/docs/concepts/security/#mutual-tls-authentication)
for more information.

Choose this option for:

* Clusters with existing applications,
* Applications where services with an Istio sidecar need to be able to
  communicate with other non-Istio Kubernetes services,
* Applications that use
  [liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/),
* Headless services, or
* StatefulSets.

To install Istio without mutual TLS authentication between sidecars:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo.yaml
{{< /text >}}

### Option 2: Install Istio with default mutual TLS authentication

Use this option only on a fresh kubernetes cluster where newly deployed
workloads are guaranteed to have Istio sidecars installed.

To Install Istio and enforce mutual TLS authentication between sidecars by
default:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

### Option 3: Render Kubernetes manifest with Helm and deploy with kubectl

Follow our setup instructions to
[render the Kubernetes manifest with Helm and deploy with kubectl](/docs/setup/kubernetes/helm-install/#option-1-install-with-helm-via-helm-template).

### Option 4: Use Helm and Tiller to manage the Istio deployment

Follow our instructions on how to
[use Helm and Tiller to manage the Istio deployment](/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install).

## Verifying the installation

1.  Ensure the following Kubernetes services are deployed: `istio-pilot`,
    `istio-ingressgateway`, `istio-policy`, `istio-telemetry`, `prometheus`,
    `istio-galley`, and, optionally, `istio-sidecar-injector`.

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                                                               AGE
    istio-citadel              ClusterIP      10.47.247.12    <none>            8060/TCP,9093/TCP                                                     7m
    istio-egressgateway        ClusterIP      10.47.243.117   <none>            80/TCP,443/TCP                                                        7m
    istio-galley               ClusterIP      10.47.254.90    <none>            443/TCP                                                               7m
    istio-ingress              LoadBalancer   10.47.244.111   35.194.55.10      80:32000/TCP,443:30814/TCP                                            7m
    istio-ingressgateway       LoadBalancer   10.47.241.20    130.211.167.230   80:31380/TCP,443:31390/TCP,31400:31400/TCP                            7m
    istio-pilot                ClusterIP      10.47.250.56    <none>            15003/TCP,15005/TCP,15007/TCP,15010/TCP,15011/TCP,8080/TCP,9093/TCP   7m
    istio-policy               ClusterIP      10.47.245.228   <none>            9091/TCP,15004/TCP,9093/TCP                                           7m
    istio-sidecar-injector     ClusterIP      10.47.245.22    <none>            443/TCP                                                               7m
    istio-statsd-prom-bridge   ClusterIP      10.47.252.184   <none>            9102/TCP,9125/UDP                                                     7m
    istio-telemetry            ClusterIP      10.47.250.107   <none>            9091/TCP,15004/TCP,9093/TCP,42422/TCP                                 7m
    prometheus                 ClusterIP      10.47.253.148   <none>            9090/TCP                                                              7m
    {{< /text >}}

    > If your cluster is running in an environment that does not
    > support an external load balancer (e.g., minikube), the
    > `EXTERNAL-IP` of `istio-ingress` and `istio-ingressgateway` will
    > say `<pending>`. You will need to access it using the service
    > NodePort, or use port-forwarding instead.

1.  Ensure the corresponding Kubernetes pods are deployed and all containers
    are up and running: `istio-pilot-*`, `istio-ingressgateway-*`,
    `istio-egressgateway-*`, `istio-policy-*`, `istio-telemetry-*`,
    `istio-citadel-*`, `prometheus-*`, `istio-galley-*`, and, optionally,
    `istio-sidecar-injector-*`.

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                       READY     STATUS        RESTARTS   AGE
    istio-citadel-75c88f897f-zfw8b             1/1       Running       0          1m
    istio-egressgateway-7d8479c7-khjvk         1/1       Running       0          1m
    istio-galley-6c749ff56d-k97n2              1/1       Running       0          1m
    istio-ingress-7f5898d74d-t8wrr             1/1       Running       0          1m
    istio-ingressgateway-7754ff47dc-qkrch      1/1       Running       0          1m
    istio-policy-74df458f5b-jrz9q              2/2       Running       0          1m
    istio-sidecar-injector-645c89bc64-v5n4l    1/1       Running       0          1m
    istio-statsd-prom-bridge-949999c4c-xjz25   1/1       Running       0          1m
    istio-telemetry-676f9b55b-k9nkl            2/2       Running       0          1m
    prometheus-86cb6dd77c-hwvqd                1/1       Running       0          1m
    {{< /text >}}

## Deploy your application

You can now deploy your own application or one of the sample applications
provided with the installation like [Bookinfo](/docs/examples/bookinfo/).

> Note: The application must use HTTP/1.1 or HTTP/2.0 protocol for all its HTTP
> traffic because HTTP/1.0 is not supported.

If you started the
[Istio-sidecar-injector](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection),
you can deploy the application directly using `kubectl apply`.

The Istio-Sidecar-injector will automatically inject Envoy containers into your
application pods. The injector assumes the application pods are running in
namespaces labeled with `istio-injection=enabled`

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

If you don't have the Istio-sidecar-injector installed, you must use
[istioctl kube-inject](/docs/reference/commands/istioctl/#istioctl-kube-inject)
to manually inject Envoy containers in your application pods before deploying
them:

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

## Uninstall Istio core components

The uninstall deletes the RBAC permissions, the `istio-system` namespace, and
all resources hierarchically under it. It is safe to ignore errors for
non-existent resources because they may have been deleted hierarchically.

If you installed Istio with `istio-demo.yaml`:

{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo.yaml
{{< /text >}}

If you didn't install Istio with `istio.yaml`, follow the [uninstall Istio with
Helm](/docs/setup/kubernetes/helm-install/#uninstall) steps.
