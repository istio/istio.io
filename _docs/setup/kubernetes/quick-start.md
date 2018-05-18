---
title: Quick Start
description: Quick start instructions to setup the Istio service mesh in a Kubernetes cluster.

weight: 10

---

{% include home.html %}

Quick start instructions to install and configure Istio in a Kubernetes cluster.

## Prerequisites

The following instructions recommend you have access to a Kubernetes **1.9 or newer** cluster
with [RBAC (Role-Based Access Control)](https://kubernetes.io/docs/admin/authorization/rbac/) enabled. You will also need `kubectl` **1.9 or newer** installed.

If you wish to enable [automatic sidecar injection]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection) or server-side configuration validation, you must use Kubernetes version 1.9 or greater.

  > If you installed Istio 0.2.x,
  > [uninstall](https://archive.istio.io/v0.2/docs/setup/kubernetes/quick-start#uninstalling)
  > it completely before installing the newer version (including the Istio sidecar
  > for all Istio enabled application pods).

* Install or upgrade the Kubernetes CLI
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to
match the version supported by your cluster (version 1.9 or later for CRD
support).

### [Minikube](https://github.com/kubernetes/minikube/releases)

To install Istio locally, install the latest version of
[Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) (version 0.25.0 or later).

```command
$ minikube start \
    --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.Admission.PluginNames=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
    --kubernetes-version=v1.9.0
```

### [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)

Create a new cluster.

```command
$ gcloud container clusters create <cluster-name> \
    --cluster-version=1.9.4-gke.1 \
    --zone <zone> \
    --project <project-name>
```

Retrieve your credentials for `kubectl`.

```command
$ gcloud container clusters get-credentials <cluster-name> \
    --zone <zone> \
    --project <project-name>
```

Grant cluster admin permissions to the current user (admin permissions are required to create the necessary RBAC rules for Istio).

```command
$ kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)
```

### [IBM Cloud Kubernetes Service (IKS)](https://www.ibm.com/cloud/container-service)

Create a new lite cluster.

```command
$ bx cs cluster-create --name <cluster-name> --kube-version 1.9.7
```

Or create a new paid cluster:

```command
$ bx cs cluster-create --location location --machine-type u2c.2x4 --name <cluster-name> --kube-version 1.9.7
```

Retrieve your credentials for `kubectl` (replace `<cluster-name>` with the name of the cluster you want to use):

```bash
$(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
```

### [IBM Cloud Private](https://www.ibm.com/us-en/marketplace/ibm-cloud-private) (version 2.1 or later)

Configure `kubectl` CLI based on steps [here](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html) for how to access the IBM Cloud Private Cluster.

### [OpenShift Origin](https://www.openshift.org) (version 3.9)

OpenShift by default does not allow containers running with UID 0. Enable containers running
with UID 0 for Istio's service accounts for ingress as well the Prometheus and Grafana addons:

  ```bash
 oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
 oc adm policy add-scc-to-user anyuid -z default -n istio-system 
 oc adm policy add-scc-to-user anyuid -z grafana -n istio-system
 oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
  ```
Service account that runs application pods need privileged security context constraints as part of sidecar injection.

```command
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
```

Note:-  Check for selinux [discussion](https://github.com/istio/issues/issues/34)  with respect to Istio in case you see issues bringing up the Envoy.

### AWS (w/Kops)

When you install a new cluster with Kubernetes version 1.9, prerequisite for `admissionregistration.k8s.io/v1beta1` enabled is covered.

Nevertheless the list of admission controllers needs to be updated.

```command
$ kops edit cluster $YOURCLUSTER
```

Add following in the configuration file just opened:

```yaml
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
```

Perform the update

```command
$ kops update cluster
$ kops update cluster --yes
```

Launch the rolling update

```command
$ kops rolling-update cluster
$ kops rolling-update cluster --yes
```

Validate with `kubectl` client on kube-api pod, you should see new admission controller:

```command
$ for i in `kubectl get pods -nkube-system | grep api | awk '{print $1}'` ; do  kubectl describe pods -nkube-system $i | grep "/usr/local/bin/kube-apiserver"  ; done
```

Output should be:

```plain
[...] --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction,Priority [...]
```

### Azure

You need to use `ACS-Engine` to deploy you cluster. After following [these instructions](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#install) to get and install the `acs-engine` binary, use the following command to download Istio `api model definition`:

```command
$ wget https://raw.githubusercontent.com/Azure/acs-engine/master/examples/service-mesh/istio.json
```

Use the following command to deploy your cluster using the `istio.json` template. You can find references to the parameters in the [official docs](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/deploy.md#step-3-edit-your-cluster-definition).

| Parameter                           | Expected value             |
|-------------------------------------|----------------------------|
| `subscription_id`                     | Azure Subscription Id      |
| `dns_prefix`                          | Cluster DNS Prefix         |
| `location`                            | Cluster Location           |

```command
$ acs-engine deploy --subscription-id <subscription_id> --dns-prefix <dns_prefix> --location <location> --auto-suffix --api-model istio.json
```

After a few minutes you should find your cluster on your Azure subscription in a resource group called `<dns_prefix>-<id>`. Let's say my `dns-prefix` is `myclustername`, a valid resource group and unique cluster id would be `mycluster-5adfba82`. Using this `<dns_prefix>-<id>` cluster id you can copy your `kubeconfig` file to your machine from the `_output` folder generated by `acs-engine`:

```command
$ cp _output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json ~/.kube/config
```

For example:

```command
$ cp _output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json ~/.kube/config
```

To check if the right Istio flags were deployed, use:
```command
$ kubectl describe pod --namespace kube-system $(kubectl get pods --namespace kube-system | grep api | cut -d ' ' -f 1) | grep admission-control
```

You should see `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` flags:

```plain
      --admission-control=...,MutatingAdmissionWebhook,...,ValidatingAdmissionWebhook,...
```

## Download and prepare for the installation

Starting with the 0.2 release, Istio is installed in its own `istio-system`
namespace, and can manage services from all other namespaces.

1.  Go to the [Istio release](https://github.com/istio/istio/releases) page to download the
installation file corresponding to your OS. If you are using a MacOS or Linux system, you can also
run the following command to download and extract the latest release automatically:

    ```command
    $ curl -L https://git.io/getLatestIstio | sh -
    ```

1.  Extract the installation file and change the directory to the file location. The
installation directory contains:

    * Installation `.yaml` files for Kubernetes in `install/`
    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is used when manually injecting Envoy as a sidecar proxy and for creating routing rules and policies.
    * The `istio.VERSION` configuration file

1.  Change directory to istio package. For example, if the package is istio-{{site.data.istio.version}}

    ```command
    $ cd istio-{{site.data.istio.version}}
    ```

1.  Add the `istioctl` client to your PATH.
For example, run the following command on a MacOS or Linux system:

    ```command
    $ export PATH=$PWD/bin:$PATH
    ```


## Installation steps

1.  Install Istio's core components. Choose one of the three _**mutually exclusive**_ options below fo quick install.  However, we recommend you to install with the [Helm Chart]({{home}}/docs/setup/kubernetes/helm-install.html) for production installation of Istio to leverage all the params to config and customize Istio to your need.
 
    a)  Quick install Istio using without enabling [mutual TLS authentication]({{home}}/docs/concepts/security/mutual-tls.html) between sidecars.
    Choose this option for clusters with existing applications, applications where services with an
    Istio sidecar need to be able to communicate with other non-Istio Kubernetes services, and
    applications that use [liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/),
    headless services, or StatefulSets.

    ```command
    $ kubectl apply -f install/kubernetes/istio-demo.yaml
    ```

    _**OR**_

    b)  [Render Kubernetes manifest with Helm and deploy with kubectl]({{home}}/docs/setup/kubernetes/helm-install.html#render-kubernetes-manifest-with-helm-and-deploy-with-kubectl).   

    _**OR**_
    
    c)  [Use Helm and Tiller to manage the Istio deployment]({{home}}/docs/setup/kubernetes/helm-install.html#alternatively-use-helm-and-tiller-to-manage-the-istio-deployment).   
    
1. *Optional:* If your cluster has Kubernetes version 1.9 or greater, and you wish to enable automatic proxy injection,
install the [sidecar injector webhook]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection).

## Verifying the installation

1.  Ensure the following Kubernetes services are deployed: `istio-pilot`, `istio-ingress`,
`istio-policy`, `istio-telemetry`, `prometheus`.

    ```command
    $ kubectl get svc -n istio-system
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                               AGE
    citadel-ilb                LoadBalancer   10.35.251.104   10.138.0.43     8060:32031/TCP                                                        47m
    istio-citadel              ClusterIP      10.35.253.23    <none>          8060/TCP,9093/TCP                                                     47m
    istio-ingress              LoadBalancer   10.35.245.4     35.203.191.37   80:32765/TCP,443:32304/TCP                                            47m
    istio-pilot                ClusterIP      10.35.255.168   <none>          15003/TCP,15005/TCP,15007/TCP,15010/TCP,15011/TCP,8080/TCP,9093/TCP   47m
    istio-pilot-ilb            LoadBalancer   10.35.252.183   10.138.0.40     15005:30035/TCP,8080:30494/TCP                                        47m
    istio-policy               ClusterIP      10.35.247.90    <none>          9091/TCP,15004/TCP,9093/TCP                                           47m
    istio-statsd-prom-bridge   ClusterIP      10.35.243.13    <none>          9102/TCP,9125/UDP                                                     47m
    istio-telemetry            ClusterIP      10.35.248.71    <none>          9091/TCP,15004/TCP,9093/TCP,42422/TCP                                 47m
    mixer-ilb                  LoadBalancer   10.35.240.250   10.138.0.42     15004:30427/TCP                                                       47m
    prometheus                 ClusterIP      10.35.255.10    <none>          9090/TCP                                                              47m
    ```

    > If your cluster is running in an environment that does not support an external load balancer
    (e.g., minikube), the `EXTERNAL-IP` of `istio-ingress` says `<pending>`. You must access the
    application using the service NodePort, or use port-forwarding instead.

1.  Ensure the corresponding Kubernetes pods are deployed and all containers are up and running:
`istio-pilot-*`, `istio-mixer-*`, `istio-ingress-*`, `istio-citadel-*`,
and, optionally, `istio-sidecar-injector-*`.

    ```command
    $ kubectl get pods -n istio-system
    istio-citadel-b454d647d-92jrv               1/1       Running   0          46m
    istio-ingress-768b9fb68b-jdxfk              1/1       Running   0          46m
    istio-pilot-b87b8c56b-kggmk                 2/2       Running   0          46m
    istio-policy-58f9bfc796-8vlq4               2/2       Running   0          46m
    istio-statsd-prom-bridge-6dbb7dcc7f-gzlq7   1/1       Running   0          46m
    istio-telemetry-55b8c8b44f-fwb69            2/2       Running   0          46m
    prometheus-586d95b8d9-grk6j                 1/1       Running   0          46m
    ```

## Deploy your application

You can now deploy your own application or one of the sample applications provided with the
installation like [Bookinfo]({{home}}/docs/guides/bookinfo.html).
Note: the application must use HTTP/1.1 or HTTP/2.0 protocol for all its HTTP traffic because HTTP/1.0 is not supported.

If you started the [Istio-sidecar-injector]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection),
as shown above, you can deploy the application directly using `kubectl create`.

The Istio-Sidecar-injector will automatically inject Envoy containers into your application pods assuming running in namespaces labeled with `istio-injection=enabled`

```command
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
```

If you do not have the Istio-sidecar-injector installed, you must
use [istioctl kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl kube-inject) to
manually inject Envoy containers in your application pods before deploying them:

```command
$ kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## Uninstalling

*   Uninstall Istio sidecar injector:

    If you installed Istio with sidecar injector enabled, uninstall it:

    ```command
    $ kubectl delete -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
    ```

*   Uninstall Istio core components. For the {{site.data.istio.version}} release, the uninstall
deletes the RBAC permissions, the `istio-system` namespace, and hierarchically all resources under it.
It is safe to ignore errors for non-existent resources because they may have been deleted hierarchically.

    a) If you installed Istio with mutual TLS authentication disabled:

    ```command
    $ kubectl delete -f install/kubernetes/istio.yaml
    ```

    _**OR**_

    b) If you installed Istio with mutual TLS authentication enabled:

    ```command
    $ kubectl delete -f install/kubernetes/istio-auth.yaml
    ```

## What's next

* See the sample [Bookinfo]({{home}}/docs/guides/bookinfo.html) application.

* See how to [test mutual TLS authentication]({{home}}/docs/tasks/security/mutual-tls.html).
