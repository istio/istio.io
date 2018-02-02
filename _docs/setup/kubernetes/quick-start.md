---
title: Quick Start
overview: Quick Start instructions to setup the Istio service mesh in a Kubernetes cluster.

order: 10

layout: docs
type: markdown
---

{% include home.html %}

Quick Start instructions to install and configure Istio in a Kubernetes cluster.


## Prerequisites

The following instructions require you have access to a Kubernetes **1.7.3 or newer** cluster
with [RBAC (Role-Based Access Control)](https://kubernetes.io/docs/admin/authorization/rbac/) enabled. You will also need `kubectl` **1.7.3 or newer** installed.  If you wish to enable [automatic sidecar injection]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection), you need Kubernetes version 1.9 or greater.

  > Note: If you installed Istio 0.1.x,
  > [uninstall](https://archive.istio.io/v0.1/docs/tasks/installing-istio.html#uninstalling)
  > it completely before installing the newer version (including the Istio sidecar
  > for all Istio enabled application pods).

* Install or upgrade the Kubernetes CLI
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to
match the version supported by your cluster (version 1.7 or later for CRD
support).

* Depending on your Kubernetes provider:

  * To install Istio locally, install the latest version of
[Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) (version 0.22.1 or later).

  * [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)

    * Retrieve your credentials for kubectl (replace `<cluster-name>` with the name of the cluster you want to use,
    and `<zone>` with the zone where that cluster is located):
  ```bash
  gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-name>
  ```

    * Grant cluster admin permissions to the current user (admin permissions are required to create the necessary RBAC rules for Istio):
  ```bash
  kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
  ```

  * [IBM Cloud Container Service](https://www.ibm.com/cloud-computing/bluemix/containers)

    * Retrieve your credentials for kubectl (replace `<cluster-name>` with the name of the cluster you want to use):
  ```bash
  $(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
  ```

  * [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) version 2.1 or later

    * Config `kubectl` CLI based on steps [here](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html) for how to access the IBM Cloud Private Cluster.

  * [Openshift Origin](https://www.openshift.org) version 3.7 or later

    * Openshift by default does not allow containers running with UID 0. Enable containers running
with UID 0 for Istio's service accounts for ingress as well the Prometheus and Grafana addons:
  ```bash
  oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-grafana-service-account -n istio-system
  oc adm policy add-scc-to-user anyuid -z istio-prometheus-service-account -n istio-system
  ```

    * Service account that runs application pods need privileged security context constraints as part of sidecar injection.
  ```bash
  oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
  ```

## Installation steps

Starting with the 0.2 release, Istio is installed in its own `istio-system`
namespace, and can manage micro-services from all other namespaces.

1. Go to the [Istio release](https://github.com/istio/istio/releases) page to download the
installation file corresponding to your OS. If you are using a MacOS or Linux system, you can also
run the following command to download and extract the latest release automatically:
```bash
curl -L https://git.io/getLatestIstio | sh -
```

1. Extract the installation file and change the directory to the file location. The
   installation directory contains:
    * Installation `.yaml` files for Kubernetes in `install/`
    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is used when manually injecting Envoy as a sidecar proxy and for creating routing rules and policies.
    * The `istio.VERSION` configuration file

1. Change directory to istio package. For example, if the package is istio-{{ site.data.istio.version }}
```bash
cd istio-{{ site.data.istio.version }}
```

1. Add the `istioctl` client to your PATH.
   For example, run the following command on a MacOS or Linux system:
```bash
export PATH=$PWD/bin:$PATH
```

1. Install Istio's core components. Choose one of the two _**mutually exclusive**_ options below:

  a) Install Istio without enabling [mutual TLS authentication]({{home}}/docs/concepts/security/mutual-tls.html) between sidecars.
       Choose this option for clusters with existing applications, applications where services with an
       Istio sidecar need to be able to communicate with other non-Istio Kubernetes services, and
       applications that use [liveliness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/),
       headless services, or StatefulSets.
```bash
kubectl apply -f install/kubernetes/istio.yaml
```

  _**OR**_

  b) Install Istio and enable [mutual TLS authentication]({{home}}/docs/concepts/security/mutual-tls.html) between sidecars.:
```bash
kubectl apply -f install/kubernetes/istio-auth.yaml
```

  Both options create the `istio-system` namespace along with the required RBAC permissions,
  and deploy Istio-Pilot, Istio-Mixer, Istio-Ingress, and Istio-CA (Certificate Authority).

1. *Optional:* If your cluster has Kubernetes version 1.9 or greater, and you wish to enable automatic proxy injection, install the sidecar injector webhook using the instructions at ({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection).

## Verifying the installation

1. Ensure the following Kubernetes services are deployed: `istio-pilot`, `istio-mixer`,
   `istio-ingress`.
```bash
kubectl get svc -n istio-system
```
```bash
NAME            CLUSTER-IP      EXTERNAL-IP       PORT(S)                       AGE
istio-ingress   10.83.245.171   35.184.245.62     80:32730/TCP,443:30574/TCP    5h
istio-pilot     10.83.251.173   <none>            8080/TCP,8081/TCP             5h
istio-mixer     10.83.244.253   <none>            9091/TCP,9094/TCP,42422/TCP   5h
```

   Note: If your cluster is running in an environment that does not support an external load balancer
   (e.g., minikube), the `EXTERNAL-IP` of `istio-ingress` says `<pending>`. You must access the
   application using the service NodePort, or use port-forwarding instead.

2. Ensure the corresponding Kubernetes pods are deployed and all containers are up and running:
   `istio-pilot-*`, `istio-mixer-*`, `istio-ingress-*`, `istio-ca-*`,
   and, optionally, `istio-sidecar-injector-*`.
```bash
kubectl get pods -n istio-system
```
```bash
istio-ca-3657790228-j21b9                1/1       Running   0          5h
istio-ingress-1842462111-j3vcs           1/1       Running   0          5h
istio-sidecar-injector-184129454-zdgf5   1/1       Running   0          5h
istio-pilot-2275554717-93c43             1/1       Running   0          5h
istio-mixer-2104784889-20rm8             2/2       Running   0          5h
```

## Deploy your application

You can now deploy your own application or one of the sample applications provided with the
installation like [BookInfo]({{home}}/docs/guides/bookinfo.html).
Note: the application must use HTTP/1.1 or HTTP/2.0 protocol for all its HTTP traffic because HTTP/1.0 is not supported.

If you started the [Istio-sidecar-injector]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection),
as shown above, you can deploy the application directly using `kubectl create`. 

The Istio-Sidecar-injector will automatically inject Envoy containers into your application pods assuming running in namespaces labeled with `istio-injection=enabled`

```bash
kubectl label namespace <namespace> istio-injection=enabled
kubectl create -n <namspace> -f <your-app-spec>.yaml
```

If you do not have the Istio-sidecar-injector installed, you must
use [istioctl kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl kube-inject) to
manuallly inject Envoy containers in your application pods before deploying them:
```bash
kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## Uninstalling

* Uninstall Istio sidecar injector:

  If you installed Istio with sidecar injector enabled, uninstall it:
```bash
kubectl delete -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
```

* Uninstall Istio core components. For the {{ site.data.istio.version }} release, the uninstall
   deletes the RBAC permissions, the `istio-system` namespace, and hierarchically all resources under it.
   It is safe to ignore errors for non-existent resources because they may have been deleted hierarchically.

    a) If you installed Istio with mutual TLS authentication disabled:
```bash
kubectl delete -f install/kubernetes/istio.yaml
```

  _**OR**_

    b) If you installed Istio with mutual TLS authentication enabled:
```bash
kubectl delete -f install/kubernetes/istio-auth.yaml
```

## What's next

* See the sample [BookInfo]({{home}}/docs/guides/bookinfo.html) application.

* See how to [test Istio mutual TLS Authentication]({{home}}/docs/tasks/security/mutual-tls.html).
