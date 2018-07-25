---
title: Kubernetes platform setup
description: Instructions to setup the Kubernetes cluster for Istio.
weight: 10
keywords: [kubernetes]
---

Follow these instructions to setup the Kubernetes cluster for Istio.

## Platform setup

This section describes the setup in different Kubernetes providers.

### Minikube

1. To run Istio locally, install the latest version of
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

You can deploy a Kubernetes cluster to Azure via [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) or [ACS-Engine](https://github.com/azure/acs-engine) which fully supports Istio.

#### Instructions for AKS

You can create an AKS cluster via [the az cli](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough) or [the Azure portal](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal).

For the `az` cli option, complete `az login` authentication OR use cloud shell, then run the following commands below.

1. Determine the desired region name which supports AKS

    {{< text bash >}}
    $ az provider list --query "[?namespace=='Microsoft.ContainerService'].resourceTypes[] | [?resourceType=='managedClusters'].locations[]" -o tsv
    {{< /text >}}

1. Verify the supported Kubernetes versions for the desired region

    Replace `my location` using the desired region value from the above step, and then execute:

    {{< text bash >}}
    $ az aks get-versions --location "my location" --query "orchestrators[].orchestratorVersion"
    {{< /text >}}

    Ensure `1.10.5` is listed or choose a different value greater than or equal to `1.9.6`.

1. Create the resource group and deploy the AKS cluster

    Replace `myResourceGroup` and `myAKSCluster` with desired names, `my location` using the value from step 1, `1.10.5` if not supported in the region, and then execute:

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.10.5 --generate-ssh-keys
    {{< /text >}}

1. Get the AKS `kubeconfig` credentials

    Replace `myResourceGroup` and `myAKSCluster` with the names from the previous step and execute:

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}

#### Instructions for ACS-Engine

1. [Follow the instructions](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#install) to get and install the `acs-engine` binary.

1. Download the `acs-engine` API model definition that supports deploying Istio:

    {{< text bash >}}
    $ wget https://raw.githubusercontent.com/Azure/acs-engine/master/examples/service-mesh/istio.json
    {{< /text >}}

    Note: It is possible to use other api model definitions which will work with Istio.  The MutatingAdmissionWebhook and ValidatingAdmissionWebhook admission control flags and RBAC are enabled by default on 1.9 or later clusters.  See [acs-engine api model default values](https://github.com/Azure/acs-engine/blob/master/docs/clusterdefinition.md) for further information.

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
