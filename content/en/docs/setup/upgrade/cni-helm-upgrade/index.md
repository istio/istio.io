---
title: Upgrade using Helm
description: Upgrade the Istio control plane, and optionally, the CNI plug-in using Helm.
weight: 30
aliases:
    - /docs/setup/kubernetes/upgrade/steps/
    - /docs/setup/upgrade/steps
    - /docs/setup/upgrade
keywords: [kubernetes,upgrading]
---

Follow this flow to upgrade an existing Istio deployment, including both the
control plane and the sidecar proxies, to a new release of Istio. The upgrade
process may install new binaries and may change configuration and API schemas.
The upgrade process may result in service downtime. To minimize downtime,
please ensure your Istio control plane components and your applications are
highly available with multiple replicas.

{{< warning >}}
Be sure to check out the [upgrade notes](/news/{{< istio_full_version_release_year >}}/announcing-{{< istio_version >}}/upgrade-notes)
for a concise list of things you should know before upgrading your deployment to Istio {{< istio_version >}}.
{{< /warning >}}

{{< tip >}}
Istio does **NOT** support skip level upgrades. Only upgrades from {{< istio_previous_version >}} to {{< istio_version >}}
are supported. If you are on an older version, please upgrade to {{< istio_previous_version >}} first.
{{< /tip >}}

## Upgrade steps

[Download the new Istio release](/docs/setup/#downloading-the-release)
and change directory to the new release directory.

### Istio CNI upgrade

If you have installed or are planning to install [Istio CNI](/docs/setup/additional-setup/cni/),
choose one of the following **mutually exclusive** options to check whether
Istio CNI is already installed and to upgrade it:

{{< tabset cookie-name="controlplaneupdate" >}}
{{< tab name="Kubernetes rolling update" cookie-value="k8supdate" >}}

You can use Kubernetes’ rolling update mechanism to upgrade the Istio CNI components.
This is suitable for cases where `kubectl apply` was used to deploy Istio CNI.

1. To check whether `istio-cni` is installed, search for `istio-cni-node` pods
   and in which namespace they are running (typically, `kube-system` or `istio-system`):

    {{< text bash >}}
    $ kubectl get pods -l k8s-app=istio-cni-node --all-namespaces
    $ NAMESPACE=$(kubectl get pods -l k8s-app=istio-cni-node --all-namespaces --output='jsonpath={.items[0].metadata.namespace}')
    {{< /text >}}

1. If `istio-cni` is currently installed in a namespace other than `kube-system`
   (for example, `istio-system`), delete `istio-cni`:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=$NAMESPACE | kubectl delete -f -
    {{< /text >}}

1. Install or upgrade `istio-cni` in the `kube-system` namespace:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=kube-system | kubectl apply -f -
    {{< /text >}}

{{< /tab >}}

{{< tab name="Helm upgrade" cookie-value="helmupgrade" >}}

If you installed Istio CNI using [Helm and Tiller](/docs/setup/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install),
the preferred upgrade option is to let Helm take care of the upgrade.

1. Check whether `istio-cni` is installed, and in which namespace:

    {{< text bash >}}
    $ helm status istio-cni
    {{< /text >}}

1. (Re-)install or upgrade `istio-cni` depending on the status:

    * If `istio-cni` is not currently installed and you decide to install it:

        {{< text bash >}}
        $ helm install install/kubernetes/helm/istio-cni --name istio-cni --namespace kube-system
        {{< /text >}}

    * If `istio-cni` is currently installed in a namespace other than `kube-system`
      (for example, `istio-system`), delete it:

        {{< text bash >}}
        $ helm delete --purge istio-cni
        {{< /text >}}

        Then install it again in the `kube-system` namespace:

        {{< text bash >}}
        $ helm install install/kubernetes/helm/istio-cni --name istio-cni --namespace kube-system
        {{< /text >}}

    * If `istio-cni` is currently installed in the `kube-system` namespace, upgrade it:

        {{< text bash >}}
        $ helm upgrade istio-cni install/kubernetes/helm/istio-cni --namespace kube-system
        {{< /text >}}

{{< /tab >}}
{{< /tabset >}}

### Control plane upgrade

Pilot, Galley, Policy, Telemetry and Sidecar injector.
Choose one of the following **mutually exclusive** options
to update the control plane:

{{< tabset cookie-name="controlplaneupdate" >}}
{{< tab name="Kubernetes rolling update" cookie-value="k8supdate" >}}
You can use Kubernetes’ rolling update mechanism to upgrade the control plane components.
This is suitable for cases where `kubectl apply` was used to deploy the Istio components,
including configurations generated using
[helm template](/docs/setup/install/helm/#option-1-install-with-helm-via-helm-template).

1. Use `kubectl apply` to upgrade all of Istio's CRDs.  Wait a few seconds for the Kubernetes
   API server to commit the upgraded CRDs:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio-init/files/
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. Apply the update templates:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio \
      --namespace istio-system | kubectl apply -f -
    {{< /text >}}

    You must pass the same settings as when you first [installed Istio](/docs/setup/install/helm).

The rolling update process will upgrade all deployments and configmaps to the new version.
After this process finishes, your Istio control plane should be updated to the new version.
Your existing application should continue to work without any change. If there is any
critical issue with the new control plane, you can rollback the changes by applying the
yaml files from the old version.
{{< /tab >}}

{{< tab name="Helm upgrade" cookie-value="helmupgrade" >}}
If you installed Istio using [Helm and Tiller](/docs/setup/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install),
the preferred upgrade option is to let Helm take care of the upgrade.

1. Upgrade the `istio-init` chart to update all the Istio [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) (CRDs).

    {{< text bash >}}
    $ helm upgrade --install istio-init install/kubernetes/helm/istio-init --namespace istio-system
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. Upgrade the `istio` chart:

    {{< text bash >}}
    $ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
    {{< /text >}}

    If Istio CNI is installed, enable it by adding the `--set istio_cni.enabled=true` setting.

{{< /tab >}}
{{< /tabset >}}

### Sidecar upgrade

After the control plane upgrade, the applications already running Istio will
still be using an older sidecar. To upgrade the sidecar, you will need to re-inject it.

If you're using automatic sidecar injection, you can upgrade the sidecar
by doing a rolling update for all the pods, so that the new version of the
sidecar will be automatically re-injected.

{{< warning >}}
Your `kubectl` version must be >= 1.15 to run the following command. Upgrade if necessary.
{{< /warning >}}

{{< text bash >}}
$ kubectl rollout restart deployment --namespace default
{{< /text >}}

If you're using manual injection, you can upgrade the sidecar by executing:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

If the sidecar was previously injected with some customized inject configuration
files, you will need to change the version tag in the configuration files to the new
version and re-inject the sidecar as follows:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject \
     --injectConfigFile inject-config.yaml \
     --filename $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}
