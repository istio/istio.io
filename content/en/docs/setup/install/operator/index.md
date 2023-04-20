---
title: Istio Operator Install
description: Instructions to install Istio in a Kubernetes cluster using the Istio operator.
weight: 99
keywords: [kubernetes, operator]
aliases:
    - /docs/setup/install/standalone-operator
owner: istio/wg-environments-maintainers
test: yes
status: Beta
---

{{< warning >}}
Use of the operator for new Istio installations is discouraged in favor of the [Istioctl](/docs/setup/install/istioctl)
and [Helm](/docs/setup/install/helm) installation methods. While the operator will continue to be supported,
new feature requests will not be prioritized.
{{< /warning >}}

Instead of manually installing, upgrading, and uninstalling Istio,
you can instead let the Istio [operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
manage the installation for you.
This relieves you of the burden of managing different `istioctl` versions.
Simply update the operator {{<gloss CRDs>}}custom resource (CR){{</gloss>}} and the
operator controller will apply the corresponding configuration changes for you.

The same [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/) is used
to install Istio with the operator as when using the [istioctl install instructions](/docs/setup/install/istioctl).
In both cases, configuration is validated against a schema and the same correctness
checks are performed.

{{< warning >}}
Using an operator does have a security implication.
With the `istioctl install` command, the operation will run in the admin user’s security context,
whereas with an operator, an in-cluster pod will run the operation in its security context.
To avoid a vulnerability, ensure that the operator deployment is sufficiently secured.
{{< /warning >}}

## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. Install the [{{< istioctl >}} command](/docs/ops/diagnostic-tools/istioctl/).

## Install

### Deploy the Istio operator

The `istioctl` command can be used to automatically deploy the Istio operator:

{{< text syntax=bash snip_id=deploy_istio_operator >}}
$ istioctl operator init
{{< /text >}}

This command runs the operator by creating the following resources in the `istio-operator` namespace:

- The operator custom resource definition
- The operator controller deployment
- A service to access operator metrics
- Necessary Istio operator RBAC rules

You can configure which namespace the operator controller is installed in, the namespace(s) the operator watches, the installed Istio image sources and versions, and more. For example, you can pass one or more namespaces to watch using the `--watchedNamespaces` flag:

{{< text syntax=bash snip_id=deploy_istio_operator_watch_ns >}}
$ istioctl operator init --watchedNamespaces=istio-namespace1,istio-namespace2
{{< /text >}}

See the [`istioctl operator init` command reference](/docs/reference/commands/istioctl/#istioctl-operator-init) for details.

{{< tip >}}
You can alternatively deploy the operator using Helm:

1. Create a namespace `istio-operator`.

    {{< text syntax=bash snip_id=create_ns_istio_operator >}}
    $ kubectl create namespace istio-operator
    {{< /text >}}

1. Install operator using Helm.

    {{< text syntax=bash snip_id=deploy_istio_operator_helm >}}
    $ helm install istio-operator manifests/charts/istio-operator \
        --set watchedNamespaces="istio-namespace1\,istio-namespace2" \
        -n istio-operator
    {{< /text >}}

Note that you need to [download the Istio release](/docs/setup/getting-started/#download)
to run the above command.
{{< /tip >}}

{{< warning >}}
Prior to Istio 1.10.0, the namespace `istio-system` needed to be created before installing the operator. As of Istio 1.10.0, the `istioctl operator init` will create the `istio-system` namespace.

If you use something other than `istioctl operator init`, then the `istio-system` namespace needs to be created manually.
{{< /warning >}}

### Install Istio with the operator

With the operator installed, you can now create a mesh by deploying an `IstioOperator` resource.
To install the Istio `demo` [configuration profile](/docs/setup/additional-setup/config-profiles/)
using the operator, run the following command:

{{< text syntax=bash snip_id=install_istio_demo_profile >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
{{< /text >}}

The controller will detect the `IstioOperator` resource and then install the Istio
components corresponding to the specified (`demo`) configuration.

{{< warning >}}
If you used `--watchedNamespaces` when you initialized the Istio operator, apply the `IstioOperator` resource in one of the watched namespaces, instead of in `istio-system`.
{{< /warning >}}

The Istio control plane (istiod) will be installed in the `istio-system` namespace by default. To install it in a different location, specify the namespace using the `values.global.istioNamespace` field as follows:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
...
spec:
  profile: demo
  values:
    global:
      istioNamespace: istio-namespace1
{{< /text >}}

{{< tip >}}
The Istio operator controller begins the process of installing Istio within 90 seconds of
the creation of the `IstioOperator` resource. The Istio installation completes within 120
seconds.
{{< /tip >}}

You can confirm the Istio control plane services have been deployed with the following commands:

{{< text syntax=bash snip_id=kubectl_get_svc >}}
$ kubectl get services -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)   AGE
istio-egressgateway    ClusterIP      10.96.65.145    <none>           ...       30s
istio-ingressgateway   LoadBalancer   10.96.189.244   192.168.11.156   ...       30s
istiod                 ClusterIP      10.96.189.20    <none>           ...       37s
{{< /text >}}

{{< text syntax=bash snip_id=kubectl_get_pods >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-696cccb5-m8ndk      1/1     Running   0          68s
istio-ingressgateway-86cb4b6795-9jlrk   1/1     Running   0          68s
istiod-b47586647-sf6sw                  1/1     Running   0          74s
{{< /text >}}

## Update

Now, with the controller running, you can change the Istio configuration by editing or replacing
the `IstioOperator` resource. The controller will detect the change and respond by updating
the Istio installation correspondingly.

For example, you can switch the installation to the `default`
profile with the following command:

{{< text syntax=bash snip_id=update_to_default_profile >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
EOF
{{< /text >}}

You can also enable or disable components and modify resource settings.
For example, to enable the `istio-egressgateway` component and increase pilot memory requests:

{{< text syntax=bash snip_id=update_to_default_profile_egress >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
  components:
    pilot:
      k8s:
        resources:
          requests:
            memory: 3072Mi
    egressGateways:
    - name: istio-egressgateway
      enabled: true
EOF
{{< /text >}}

You can observe the changes that the controller makes in the cluster in response to `IstioOperator` CR updates by
checking the operator controller logs:

{{< text syntax=bash snip_id=operator_logs >}}
$ kubectl logs -f -n istio-operator "$(kubectl get pods -n istio-operator -lname=istio-operator -o jsonpath='{.items[0].metadata.name}')"
{{< /text >}}

Refer to the [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/#IstioOperatorSpec)
for the complete set of configuration settings.

## In-place Upgrade

Download and extract the `istioctl` corresponding to the version of Istio you wish to upgrade to. Reinstall the operator
at the target Istio version:

{{< text syntax=bash snip_id=inplace_upgrade >}}
$ <extracted-dir>/bin/istioctl operator init
{{< /text >}}

You should see that the `istio-operator` pod has restarted and its version has changed to the target version:

{{< text syntax=bash snip_id=inplace_upgrade_get_pods_istio_operator >}}
$ kubectl get pods --namespace istio-operator \
  -o=jsonpath='{range .items[*]}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

After a minute or two, the Istio control plane components should also be restarted at the new version:

{{< text syntax=bash snip_id=inplace_upgrade_get_pods_istio_system >}}
$ kubectl get pods --namespace istio-system \
  -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

## Canary Upgrade

The process for canary upgrade is similar to the [canary upgrade with `istioctl`](/docs/setup/upgrade/canary/).

For example, to upgrade Istio {{< istio_previous_version >}}.0 to {{< istio_full_version >}}, first install {{< istio_previous_version >}}.0 :

{{< text syntax=bash snip_id=download_istio_previous_version >}}
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_previous_version >}}.0 sh -
{{< /text >}}

Deploy the operator using Istio version {{< istio_previous_version >}}.0:

{{< text syntax=bash snip_id=deploy_operator_previous_version >}}
$ istio-{{< istio_previous_version >}}.0/bin/istioctl operator init
{{< /text >}}

Install Istio control plane demo profile:

{{< text syntax=bash snip_id=install_istio_previous_version >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane-{{< istio_previous_version_revision >}}-0
spec:
  profile: default
EOF
{{< /text >}}

Verify that the `IstioOperator` CR named `example-istiocontrolplane` exists in your cluster:

{{< text syntax=bash snip_id=verify_operator_cr >}}
$ kubectl get iop --all-namespaces
NAMESPACE      NAME                              REVISION   STATUS    AGE
istio-system   example-istiocontrolplane{{< istio_previous_version_revision >}}-0              HEALTHY   11m
{{< /text >}}

Download and extract the `istioctl` corresponding to the version of Istio you wish to upgrade to.
Then, run the following command to install the new target revision of the Istio control plane based on the in-cluster
`IstioOperator` CR (here, we assume the target revision is {{< istio_full_version_revision >}}):

{{< text syntax=bash snip_id=canary_upgrade_init >}}
$ istio-{{< istio_full_version >}}/bin/istioctl operator init --revision {{< istio_full_version_revision >}}
{{< /text >}}

{{< tip >}}
You can alternatively use Helm to deploy another operator with a different revision setting:

{{< text syntax=bash snip_id=none >}}
$ helm install istio-operator manifests/charts/istio-operator \
  --set watchedNamespaces=istio-system \
  -n istio-operator \
  --set revision={{< istio_full_version_revision >}}
{{< /text >}}

Note that you need to [download the Istio release](/docs/setup/getting-started/#download)
to run the above command.
{{< /tip >}}

Make a copy of the `example-istiocontrolplane` CR and save it in a file named `example-istiocontrolplane-{{< istio_full_version_revision >}}.yaml`.
Change the name to `example-istiocontrolplane-{{< istio_full_version_revision >}}` and add `revision: {{< istio_full_version_revision >}}` to the CR.
Your updated `IstioOperator` CR should look something like this:

{{< text syntax=bash snip_id=cat_operator_yaml >}}
$ cat example-istiocontrolplane-{{< istio_full_version_revision >}}.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane-{{< istio_full_version_revision >}}
spec:
  revision: {{< istio_full_version_revision >}}
  profile: default
{{< /text >}}

Apply the updated `IstioOperator` CR to the cluster. After that, you will have two control plane deployments and services running side-by-side:

{{< text syntax=bash snip_id=get_pods_istio_system >}}
$ kubectl get pod -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-{{< istio_full_version_revision >}}-597475f4f6-bgtcz   1/1     Running   0          64s
istiod-6ffcc65b96-bxzv5          1/1     Running   0          2m11s
{{< /text >}}

{{< text syntax=bash snip_id=get_svc_istio_system >}}
$ kubectl get services -n istio-system -l app=istiod
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                         AGE
istiod          ClusterIP   10.104.129.150   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP   2m35s
istiod-{{< istio_full_version_revision >}}   ClusterIP   10.111.17.49     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP           88s
{{< /text >}}

To complete the upgrade, label the workload namespaces with `istio.io/rev={{< istio_full_version_revision >}}` and restart the workloads, as
explained in the [Data plane upgrade](/docs/setup/upgrade/canary/#data-plane) documentation.

## Uninstall

If you used the operator to perform a canary upgrade of the control plane, you can uninstall the old control plane and keep the new one by deleting the old in-cluster `IstioOperator` CR, which will uninstall the old revision of Istio:

{{< text syntax=bash snip_id=delete_example_istiocontrolplane >}}
$ kubectl delete istiooperators.install.istio.io -n istio-system example-istiocontrolplane
{{< /text >}}

Wait until Istio is uninstalled - this may take some time.

Then you can remove the Istio operator for the old revision by running the following command:

{{< text syntax=bash snip_id=none >}}
$ istioctl operator remove --revision <revision>
{{< /text >}}

If you omit the `revision` flag, then all revisions of Istio operator will be removed.

Note that deleting the operator before the `IstioOperator` CR and corresponding Istio revision are fully removed may result in leftover Istio resources.
To clean up anything not removed by the operator:

{{< text syntax=bash snip_id=cleanup >}}
$ istioctl uninstall -y --purge
$ kubectl delete ns istio-system istio-operator
 {{< /text >}}
