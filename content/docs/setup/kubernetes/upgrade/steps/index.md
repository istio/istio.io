---
title: Upgrade Steps
description: Upgrade the Istio control plane and data plane independently.
weight: 25
keywords: [kubernetes,upgrading]
---

Follow this flow to upgrade an existing Istio deployment, including both the
control plane and the sidecar proxies, to a new release of Istio. The upgrade
process may install new binaries and may change configuration and API schemas.
The upgrade process may result in service downtime. To minimize downtime,
please ensure your Istio control plane components and your applications are
highly available with multiple replicas (as multi-replica Citadel is still
under development, Citadel should be deployed with one replica).

{{< warning >}}
Citadel does not support multiple instances. Running multiple Citadel instances
may introduce race conditions and lead to system outages.
{{< /warning >}}

This flow assumes that the Istio components are installed and upgraded in the
`istio-system` namespace.

{{< warning >}}
Be sure to check out the [upgrade notice](/docs/setup/kubernetes/upgrade/notice) for a concise list of things you should know before
upgrading your deployment to Istio 1.1.
{{< /warning >}}

## Upgrade steps

[Download the new Istio release](/docs/setup/kubernetes/#downloading-the-release)
and change directory to the new release directory.

### Control plane upgrade

{{< warning >}}
Helm has significant problems when upgrading CRDs using Tiller.
We believe we have solved these with the introduction of the `istio-init` chart.
However, because of the wide variety of Helm and Tiller versions used with previous Istio deployments,
ranging from 2.7.2 to 2.12.2, we recommend an abundance of caution by
backing up your custom resource data, before proceeding with the upgrade:

{{< text bash >}}
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | cut -f1-1 -d "." | \
    xargs -n1 -I{} sh -c "kubectl get --all-namespaces -oyaml {}; echo ---" > $HOME/ISTIO_1_0_RESTORE_CRD_DATA.yaml
{{< /text >}}

{{< /warning >}}

The Istio control plane components include: Citadel, Ingress gateway, Egress gateway, Pilot, Galley, Policy, Telemetry and
Sidecar injector.  Choose one of the following two **mutually exclusive** options to update the control plane:

{{< tabset cookie-name="controlplaneupdate" >}}
{{< tab name="Kubernetes rolling update" cookie-value="k8supdate" >}}
You can use Kubernetes’ rolling update mechanism to upgrade the control plane components.
This is suitable for cases where `kubectl apply` was used to deploy the Istio components,
including configurations generated using
[helm template](/docs/setup/kubernetes/install/helm/#option-1-install-with-helm-via-helm-template).

1. Use `kubectl apply` to upgrade all the Istio's CRDs.  Wait a few seconds for the Kubernetes API server to receive the upgraded CRDs:

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. Add Istio's core components to a Kubernetes manifest file, for example.

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio \
      --namespace istio-system > $HOME/istio.yaml
    {{< /text >}}

    If you want to enable [global mutual TLS](/docs/concepts/security/#mutual-tls-authentication), set `global.mtls.enabled` and `global.controlPlaneSecurityEnabled` to `true` for the last command:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --set global.mtls.enabled=true --set global.controlPlaneSecurityEnabled=true > $HOME/istio-auth.yaml
    {{< /text >}}

1. Upgrade the Istio control plane components via the manifest, for example:

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

    or

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-auth.yaml
    {{< /text >}}

The rolling update process will upgrade all deployments and configmaps to the new version. After this process finishes,
your Istio control plane should be updated to the new version. Your existing application should continue to work without
any change. If there is any critical issue with the new control plane, you can rollback the changes by applying the yaml files from the old version.
{{< /tab >}}

{{< tab name="Helm upgrade" cookie-value="helmupgrade" >}}
If you installed Istio using [Helm and Tiller](/docs/setup/kubernetes/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install),
the preferred upgrade option is to let Helm take care of the upgrade.

1. Upgrade the `istio-init` chart to update all the Istio [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) (CRDs).

    {{< text bash >}}
    $ helm upgrade --install --force istio-init install/kubernetes/helm/istio-init --namespace istio-system
    {{< /text >}}

1. Check that all the CRD creation jobs completed successfully to verify that the Kubernetes API server received all the CRDs:

    {{< text bash >}}
    $ kubectl get job --namespace istio-system | grep istio-init-crd
    {{< /text >}}

1. Upgrade the `istio` chart:

    {{< text bash >}}
    $ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
    {{< /text >}}

{{< /tab >}}
{{< /tabset >}}

### Sidecar upgrade

After the control plane upgrade, the applications already running Istio will still be using an older sidecar. To upgrade the sidecar, you will need to re-inject it.

If you're using automatic sidecar injection, you can upgrade the sidecar
by doing a rolling update for all the pods, so that the new version of the
sidecar will be automatically re-injected. There are some tricks to reload
all pods. E.g. There is a sample [bash script](https://gist.github.com/jmound/ff6fa539385d1a057c82fa9fa739492e)
which triggers the rolling update by patching the grace termination period.

If you're using manual injection, you can upgrade the
sidecar by executing:

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
