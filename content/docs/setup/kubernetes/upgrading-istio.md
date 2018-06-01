---
title: Upgrading Istio
description: This guide demonstrates how to upgrade the Istio control plane and data plane independently.
weight: 70
---

This guide demonstrates how to upgrade the Istio control plane and data plane
for the Kubernetes environment.

## Overview

This guide describes how to upgrade an existing Istio deployment (including both control plane and sidecar proxy) to a new release of Istio. The upgrade process could involve new binaries as well as other changes like configuration and API schemas. The upgrade process may involve some service downtime. To minimize the service downtime, please ensure your istio control plane components and your application are highly available with multiple replicas.

## Application setup

In the following steps, we assume that the Istio components are installed and upgraded in the the `istio-system` namespace.

## Tasks

### Control plane upgrade

The Istio control plane components include: Citadel, Ingress gateway, Egress gateway, Pilot, Policy, Telemetry and
Sidecar injector. We can use Kubernetes’ rolling update mechanism to upgrade the
control plane components.

First, generate the desired istio control plane yaml file, e.g.

```command
helm template --namespace istio-system --set global.proxy.image=proxy \
  --values install/kubernetes/helm/istio/values-istio.yaml \
  install/kubernetes/helm/istio >> install/kubernetes/istio.yaml
```

or

```command
helm template --namespace istio-system --set global.proxy.image=proxy \
  --values install/kubernetes/helm/istio/values-istio-auth.yaml \
  install/kubernetes/helm/istio >> install/kubernetes/istio-auth.yaml
```

If using Kubernetes earlier than 1.9, you should add ```--set sidecarInjectorWebhook.enabled=false```.

Second, simply apply the new version of the desired istio control plane yaml file directly, e.g.

```command
$ kubectl apply -f install/kubernetes/istio.yaml
```

or

```command
$ kubectl apply -f install/kubernetes/istio-auth.yaml
```

The rolling update process will upgrade all deployments and configmaps to the new version. After this process finishes, your Istio control plane should be updated to the new version. Your existing application should continue to work without any change, using the Envoy v1 proxy and the v1alpha1 route rules. If there is any critical issue with the new control plane, you can rollback the changes by applying the yaml files from the old version.

### Sidecar upgrade

The applications already running istio will still using the sidecar from 0.7.1 and will continue to work. After the control plane is upgraded, you will need to re-inject so they run with the new version of sidecar proxy. There are two cases: Manual injection and Automatic injection.

1.  Manual injection:

    If automatic sidecar injection is not enabled, you can upgrade the
    sidecar manually by running the following command:

    ```command
    $ kubectl replace -f <(istioctl kube-inject -f $ORIGINAL_DEPLOYMENT_YAML)
    ```

    If the sidecar was previously injected with some customized inject config
    files, you will need to change the version tag in the config files to the new
    version and reinject the sidecar as follows:

    ```command
    $ kubectl replace -f <(istioctl kube-inject \
         --injectConfigFile inject-config.yaml \
         --filename $ORIGINAL_DEPLOYMENT_YAML)
    ```

1.  Automatic injection:

    If automatic sidecar injection is enabled, you can upgrade the sidecar
    by doing a rolling update for all the pods, so that the new version of
    sidecar will be automatically re-injected

    There are some tricks to reload all pods. E.g. There is a [bash script](https://gist.github.com/jmound/ff6fa539385d1a057c82fa9fa739492e)
    which triggers the rolling update by patching the grace termination period.

### Migrating to the new networking APIs

1.  Once you upgrade the control plane, you can gradually update your deployment to use the new Envoy side car.  You can do this by using one of the options below:

    i. Add the following to your pod annotation for your deployment:

    ```yaml

    kind: Deployment
    ...
    spec:
      template:
        annotations:
           sidecar.istio.io/proxyImage: docker.io/istio/proxyv2:0.8.0

    ```

    Then replace your deployment with your updated application yaml file:
    ```command
    $ kubectl replace -f $UPDATED_DEPLOYMENT_YAML
    ```

    *OR*

    ii. Use an `injectConfigFile` that has `docker.io/istio/proxyv2:0.8.0` as the proxyImage.  If you don't have an injectConfigFile, you can [generate one](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection).   `injectConfigFile` is recommended if you need to add the `sidecar.istio.io/proxyImage` annotations in multiple deployment definitions.

    ```command
    $ kubectl replace -f <(istioctl kube-inject --injectConfigFile inject-config.yaml -f $ORIGINAL_DEPLOYMENT_YAML)
    ```

2.  Use `istioctl experimental convert-networking-config` to convert your existing ingress or route rules.  

    i. If your yaml file contains more than the ingress definition such as deployment or service definition, move the ingress defintion out to a separate yaml file for the `istioctl experimental convert-networking-config` tool to process.

    ii. Execute the following to generate the new network config file, where replacing FILE*.yaml with your ingress file or deprecated route rule files.  *Tip: Make sure to feed all the files using `-f` for 1 or more deployments.*

    ```command
    $ istioctl experimental convert-networking-config -f FILE1.yaml -f FILE2.yaml -f FILE3.yaml > UPDATED_NETWORK_CONFIG.yaml
    ```

    iii. Open up UPDATED_NETWORK_CONFIG.yaml with your favorite editor, and update all namespace references to your desired namespace.   There is a known issue with the `convert-networking-config` tool where the `istio-system` namespace is used incorrectly.  Further, ensure the `hosts` value is the desired `hosts` value.

    iiii. Deploy the updated network config file.

    ```command
    $ kubectl replace -f UPDATED_NETWORK_CONFIG.yaml
    ```

When all your applications have been migrated and tested, you can repeat the istio upgrade process, removing the `--set global.proxy.image=proxy` option.  This will set the default proxy to `docker.io/istio/proxyv2` for all future to be injected sidecars.

