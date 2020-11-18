---
title: Istio Operator Install
description: Instructions to install Istio in a Kubernetes cluster using the Istio operator.
weight: 25
keywords: [kubernetes, operator]
aliases:
    - /docs/setup/install/standalone-operator
owner: istio/wg-environments-maintainers
test: no
---

Instead of manually installing, upgrading, and uninstalling Istio in a production environment,
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
With the `istioctl install` command, the operation will run in the admin user’s security context,
whereas with an operator, an in-cluster pod will run the operation in its security context.
To avoid a vulnerability, ensure that the operator deployment is sufficiently secured.
{{< /warning >}}

## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. Install the [{{< istioctl >}} command](/docs/ops/diagnostic-tools/istioctl/).

1. Deploy the Istio operator:

    {{< text bash >}}
    $ istioctl operator init
    {{< /text >}}

    This command runs the operator by creating the following resources in the `istio-operator` namespace:

    - The operator custom resource definition
    - The operator controller deployment
    - A service to access operator metrics
    - Necessary Istio operator RBAC rules

    You can configure which namespace the operator controller is installed in, the namespace(s) the operator watches, the installed Istio image sources and versions, and more. For example, you can pass one or more namespaces to watch using the `--watchedNamespaces` flag:

    {{< text bash >}}
    $ istioctl operator init --watchedNamespaces=istio-namespace1,istio-namespace2
    {{< /text >}}

    See the [`istioctl operator init` command reference](/docs/reference/commands/istioctl/#istioctl-operator-init) for details.

    {{< tip >}}
    You can alternatively deploy the operator using Helm:

    {{< text bash >}}
    $ helm template manifests/charts/istio-operator/ \
      --set hub=docker.io/istio \
      --set tag={{< istio_full_version >}} \
      --set operatorNamespace=istio-operator \
      --set watchedNamespaces=istio-system | kubectl apply -f -
    {{< /text >}}

    Note that you need to [download the Istio release](/docs/setup/getting-started/#download)
    to run the above command.
    {{< /tip >}}

## Install

To install the Istio `demo` [configuration profile](/docs/setup/additional-setup/config-profiles/)
using the operator, run the following command:

{{< text bash >}}
$ kubectl create ns istio-system
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

{{< tip >}}
The Istio operator controller begins the process of installing Istio within 90 seconds of
the creation of the `IstioOperator` resource. The Istio installation completes within 120
seconds.
{{< /tip >}}

You can confirm the Istio control plane services have been deployed with the following commands:

{{< text bash >}}
$ kubectl get svc -n istio-system
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                      AGE
istio-egressgateway         ClusterIP      10.103.243.113   <none>        80/TCP,443/TCP,15443/TCP                                                     17s
istio-ingressgateway        LoadBalancer   10.101.204.227   <pending>     15020:31077/TCP,80:30689/TCP,443:32419/TCP,31400:31411/TCP,15443:30176/TCP   17s
istiod                      ClusterIP      10.96.237.249    <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,53/UDP,853/TCP                         30s                                                              13s
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                   READY   STATUS    RESTARTS   AGE
istio-egressgateway-5444c68db8-9h6dz   1/1     Running   0          87s
istio-ingressgateway-5c68cb968-x7qv9   1/1     Running   0          87s
istiod-598984548d-wjq9j                1/1     Running   0          99s
{{< /text >}}

## Update

Now, with the controller running, you can change the Istio configuration by editing or replacing
the `IstioOperator` resource. The controller will detect the change and respond by updating
the Istio installation correspondingly.

For example, you can switch the installation to the `default`
profile with the following command:

{{< text bash >}}
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

{{< text bash >}}
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

{{< text bash >}}
$ kubectl logs -f -n istio-operator $(kubectl get pods -n istio-operator -lname=istio-operator -o jsonpath='{.items[0].metadata.name}')
{{< /text >}}

Refer to the [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/#IstioOperatorSpec)
for the complete set of configuration settings.

## In-place Upgrade

Download and extract the `istioctl` corresponding to the version of Istio you wish to upgrade to. Reinstall the operator
at the target Istio version:

{{< text bash >}}
$ <extracted-dir>/bin/istioctl operator init
{{< /text >}}

You should see that the `istio-operator` pod has restarted and its version has changed to the target version:

{{< text bash >}}
$ kubectl get pods --namespace istio-operator \
  -o=jsonpath='{range .items[*'{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}'
{{< /text >}}

After a minute or two, the Istio control plane components should also be restarted at the new version:

{{< text bash >}}
$ kubectl get pods --namespace istio-system \
  -o=jsonpath='{range .items[*'{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}'
{{< /text >}}

## Canary Upgrade

The process for canary upgrade is similar to the [canary upgrade with `istioctl`](/docs/setup/upgrade/#canary-upgrades).

For example, to upgrade the revision of Istio installed in the previous section, first verify that the `IstioOperator` CR named `example-istiocontrolplane` exists in your cluster:

{{< text bash >}}
$ kubectl get iop --all-namespaces
NAMESPACE      NAME                        REVISION   STATUS    AGE
istio-system   example-istiocontrolplane              HEALTHY   11m
{{< /text >}}

Download and extract the `istioctl` corresponding to the version of Istio you wish to upgrade to.
Then, run the following command to install the new target revision of the Istio control plane based on the in-cluster
`IstioOperator` CR (here, we assume the target revision is 1.8.1):

{{< text bash >}}
$ istio-1.8.1/bin/istioctl operator init --revision 1-8-1
{{< /text >}}

{{< tip >}}
You can alternatively use Helm to deploy another operator with a different revision setting:

{{< text bash >}}
$ helm template manifests/charts/istio-operator/ \
  --set hub=docker.io/istio \
  --set tag={{< istio_full_version >}} \
  --set operatorNamespace=istio-operator \
  --set revision=1-7-0 \
  --set watchedNamespaces=istio-system | kubectl apply -f -
{{< /text >}}

Note that you need to [download the Istio release](/docs/setup/getting-started/#download)
to run the above command.
{{< /tip >}}

After running the command, you will have two control plane deployments and services running side-by-side:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-5f4f9dd5fc-4xc8p          1/1     Running   0          10m
istiod-1-8-1-55887f699c-t8bh8    1/1     Running   0          8m13s
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get svc -l app=istiod
NAME            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                                         AGE
istiod          ClusterIP   10.87.7.69   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP   10m
istiod-1-8-1    ClusterIP   10.87.4.92   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP   7m55s
{{< /text >}}

To complete the upgrade, label the workload namespaces with `istio.io/rev=1-8-1` and restart the workloads, as
explained in the [Data plane upgrade](/docs/setup/upgrade/canary/#data-plane) documentation.

## Uninstall

If you used the operator to perform a canary upgrade of the control plane, you can uninstall the old control plane and keep the new one by running the following command:

{{< text bash >}}
$ istioctl operator remove --revision <revision>
{{< /text >}}

Otherwise, delete the in-cluster `IstioOperator` CR, which will uninstall all revisions of Istio that may be running:

{{< text bash >}}
$ kubectl delete istiooperators.install.istio.io -n istio-system example-istiocontrolplane
{{< /text >}}

Wait until Istio is uninstalled - this may take some time.
Delete the Istio operator:

{{< text bash >}}
$ istioctl operator remove
{{< /text >}}

Or:

{{< text bash >}}
$ kubectl delete ns istio-operator --grace-period=0 --force
{{< /text >}}

Note that deleting the operator before Istio is fully removed may result in leftover Istio resources.
To clean up anything not removed by the operator:

{{< text bash >}}
$ istioctl manifest generate | kubectl delete -f -
$ kubectl delete ns istio-system --grace-period=0 --force
 {{< /text >}}
