---
title: Quick Start
description: Quick start instructions to setup the Istio service mesh in a Kubernetes cluster.
weight: 10
---

Quick start instructions to install and configure Istio in a Kubernetes cluster.

## Prerequisites

The following instructions recommend you have access to a Kubernetes **1.9 or newer** cluster
with [RBAC (Role-Based Access Control)](https://kubernetes.io/docs/admin/authorization/rbac/) enabled. You will also need `kubectl` **1.9 or newer** installed.

If you wish to enable [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection) or server-side configuration validation, you must use Kubernetes version 1.9 or greater.

  > If you installed Istio 0.2.x,
  > [uninstall](https://archive.istio.io/v0.2/docs/setup/kubernetes/quick-start#uninstalling)
  > it completely before installing the newer version (including the Istio sidecar
  > for all Istio enabled application pods).

* Install or upgrade the Kubernetes CLI
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to
match the version supported by your cluster (version 1.9 or later for CRD
support).

### Minikube

To install Istio locally, install the latest version of
[Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) (version 0.25.0 or later).

For kubernetes 1.9

```command
$ minikube start \
    --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.Admission.PluginNames=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
    --kubernetes-version=v1.9.0
```

For kubernetes 1.10

```command
$ minikube start \
    --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota" \
    --kubernetes-version=v1.10.0
```

### Google Kubernetes Engine

Create a new cluster.

```command
$ gcloud container clusters create <cluster-name> \
    --cluster-version=1.9.7-gke.1 \
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

### IBM Cloud Kubernetes Service (IKS)

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

### IBM Cloud Private

Configure `kubectl` CLI based on steps [here](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html) for how to access the IBM Cloud Private Cluster.

### OpenShift Origin

OpenShift by default does not allow containers running with UID 0. Enable containers running
with UID 0 for Istio's service accounts for ingress as well the Prometheus and Grafana addons:

```command
$ oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z default -n istio-system
$ oc adm policy add-scc-to-user anyuid -z grafana -n istio-system
$ oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
```

Service account that runs application pods need privileged security context constraints as part of sidecar injection.

```command
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
```

> Check for `SELINUX` in this [discussion](https://github.com/istio/issues/issues/34)  with respect to Istio in case you see issues bringing up the Envoy.

### AWS (w/Kops)

When you install a new cluster with Kubernetes version 1.9, prerequisite for `admissionregistration.k8s.io/v1beta1` enabled is covered.

Nevertheless the list of admission controllers needs to be updated.

```command
$ kops edit cluster $YOURCLUSTER
```

Add the following in the configuration file:

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

1.  Change directory to istio package. For example, if the package is istio-{{< istio_version >}}

    ```command
    $ cd istio-{{< istio_version >}}
    ```

1.  Add the `istioctl` client to your PATH.
For example, run the following command on a MacOS or Linux system:

    ```command
    $ export PATH=$PWD/bin:$PATH
    ```

## Installation steps

Install Istio's core components. Choose one of the four _**mutually exclusive**_ options below fo quick installation.  However, we recommend you to install with the [Helm Chart](/docs/setup/kubernetes/helm-install/) for production installations of Istio to leverage all the options to configure and customize Istio to your needs.

*  Install Istio without enabling [mutual TLS authentication](/docs/concepts/security/mutual-tls/) between sidecars. Choose this option for clusters with existing applications, applications where services with an Istio sidecar need to be able to communicate with other non-Istio Kubernetes services, and applications that use [liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), headless services, or StatefulSets.

    ```command
    $ kubectl apply -f install/kubernetes/istio-demo.yaml
    ```

OR

*  Install Istio and enforce mutual TLS authentication between sidecars by default. Use this option only on a fresh kubernetes cluster where newly deployed workloads are guaranteed to have Istio sidecars installed.

    ```command
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    ```

OR

*  [Render Kubernetes manifest with Helm and deploy with kubectl](/docs/setup/kubernetes/helm-install/#option-1-install-with-helm-via-helm-template).

OR

*  [Use Helm and Tiller to manage the Istio deployment](/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install).

## Verifying the installation

1.  Ensure the following Kubernetes services are deployed: `istio-pilot`, `istio-ingressgateway`, `istio-egressgateway`,
 `istio-telemetry`, `istio-policy`, `istio-citadel`, `prometheus` and, optionally, `istio-sidecar-injector`.

    ```command
    $ kubectl get svc -n istio-system
    NAME                       TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)                                                               AGE
    istio-citadel              ClusterIP      30.0.0.119   <none>          8060/TCP,9093/TCP                                                     7h
    istio-egressgateway        ClusterIP      30.0.0.11    <none>          80/TCP,443/TCP                                                        7h
    istio-ingressgateway       LoadBalancer   30.0.0.39    9.111.255.245   80:31380/TCP,443:31390/TCP,31400:31400/TCP                            7h
    istio-pilot                ClusterIP      30.0.0.136   <none>          15003/TCP,15005/TCP,15007/TCP,15010/TCP,15011/TCP,8080/TCP,9093/TCP   7h
    istio-policy               ClusterIP      30.0.0.242   <none>          9091/TCP,15004/TCP,9093/TCP                                           7h
    istio-statsd-prom-bridge   ClusterIP      30.0.0.111   <none>          9102/TCP,9125/UDP                                                     7h
    istio-telemetry            ClusterIP      30.0.0.246   <none>          9091/TCP,15004/TCP,9093/TCP,42422/TCP                                 7h
    prometheus                 ClusterIP      30.0.0.253   <none>          9090/TCP                                                              7h
    ```

    > If your cluster is running in an environment that does not support an external load balancer
    (e.g., minikube), the `EXTERNAL-IP` of `istio-ingress` says `<pending>`. You must access the
    application using the service NodePort, or use port-forwarding instead.

1.  Ensure the corresponding Kubernetes pods are deployed and all containers are up and running:
`istio-pilot-*`, `istio-ingressgateway-*`, `istio-egressgateway-*`, `istio-policy-*`, `istio-telemtry-*`, `istio-citadel-*`, `prometheus-*` and, optionally, `istio-sidecar-injector-*`.

    ```command
    $ kubectl get pods -n istio-system
    NAME                                       READY     STATUS      RESTARTS   AGE
    istio-citadel-dcb7955f6-vdcjk              1/1       Running     0          11h
    istio-egressgateway-56b7758b44-l5fm5       1/1       Running     0          11h
    istio-ingressgateway-56cfddbd5b-xbdcx      1/1       Running     0          11h
    istio-pilot-cbd6bfd97-wgw9b                2/2       Running     0          11h
    istio-policy-699fbb45cf-bc44r              2/2       Running     0          11h
    istio-statsd-prom-bridge-949999c4c-nws5j   1/1       Running     0          11h
    istio-telemetry-55b675d8c-kfvvj            2/2       Running     0          11h
    prometheus-86cb6dd77c-5j48h                1/1       Running     0          11h
    ```

## Deploy your application

You can now deploy your own application or one of the sample applications provided with the
installation like [Bookinfo](/docs/guides/bookinfo/).
Note: the application must use HTTP/1.1 or HTTP/2.0 protocol for all its HTTP traffic because HTTP/1.0 is not supported.

If you started the [Istio-sidecar-injector](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection),
as shown above, you can deploy the application directly using `kubectl create`.

The Istio-Sidecar-injector will automatically inject Envoy containers into your application pods assuming running in namespaces labeled with `istio-injection=enabled`

```command
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
```

If you do not have the Istio-sidecar-injector installed, you must
use [istioctl kube-inject](/docs/reference/commands/istioctl/#istioctl kube-inject) to
manually inject Envoy containers in your application pods before deploying them:

```command
$ kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## Uninstalling

*   Uninstall Istio core components. For this release, the uninstall
deletes the RBAC permissions, the `istio-system` namespace, and hierarchically all resources under it.
It is safe to ignore errors for non-existent resources because they may have been deleted hierarchically.

If you installed Istio with `istio-demo.yaml`:

```command
$ kubectl delete -f install/kubernetes/istio-demo.yaml
```

otherwise [uninstall Istio with Helm](/docs/setup/kubernetes/helm-install/#uninstall).

## What's next

* See the sample [Bookinfo](/docs/guides/bookinfo/) application.

* See how to [test mutual TLS authentication](/docs/tasks/security/mutual-tls/).
