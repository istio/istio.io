---
title: Istio Workload Minimum TLS Version Configuration
description: Shows how to configure the minimum TLS version for Istio workloads.
weight: 90
keywords: [security,TLS]
aliases:
- /docs/tasks/security/workload-min-tls-version/
owner: istio/wg-security-maintainers
test: yes
---

This task shows how to configure the minimum TLS version for Istio workloads.
The maximum TLS version for Istio workloads is 1.3.

## Configuration of minimum TLS version for Istio workloads

* Install Istio through `istioctl` with the minimum TLS version configured.
  The `IstioOperator` custom resource used to configure Istio in the `istioctl install` command
  contains a field for the minimum TLS version for Istio workloads.
  The `minProtocolVersion` field specifies the minimum TLS version for the TLS connections
  among Istio workloads. In the following example,
  the minimum TLS version for Istio workloads is configured to be 1.3.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        meshMTLS:
          minProtocolVersion: TLSV1_3
    EOF
    $ istioctl install -f ./istio.yaml
    {{< /text >}}

## Check the TLS configuration of Istio workloads

After configuring the minimum TLS version of Istio workloads,
you can verify that the minimum TLS version was configured and works as expected.

* Deploy two workloads: `httpbin` and `sleep`. Deploy these into a single namespace,
  for example `foo`. Both workloads run with an Envoy proxy in front of each.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* Verify that `sleep` successfully communicates with `httpbin` using this command:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
If you don’t see the expected output, retry after a few seconds.
Caching and propagation can cause a delay.
{{< /warning >}}

In the example, the minimum TLS version was configured to be 1.3.
To check that TLS 1.3 is allowed, you can run the following command:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_3 -connect httpbin.foo:8000 | grep "TLSv1.3"
{{< /text >}}

The text output should include:

{{< text plain >}}
TLSv1.3
{{< /text >}}

To check that TLS 1.2 is not allowed, you can run the following command:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_2 -connect httpbin.foo:8000 | grep "Cipher is (NONE)"
{{< /text >}}

The text output should include:

{{< text plain >}}
Cipher is (NONE)
{{< /text >}}

## Cleanup

Delete sample applications `sleep` and `httpbin` from the `foo` namespace:

{{< text bash >}}
$ kubectl delete -f samples/httpbin/httpbin.yaml -n foo
$ kubectl delete -f samples/sleep/sleep.yaml -n foo
{{< /text >}}

Uninstall Istio from the cluster:

{{< text bash >}}
$ istioctl uninstall --purge -y
{{< /text >}}

To remove the `foo` and `istio-system` namespaces:

{{< text bash >}}
$ kubectl delete ns foo istio-system
{{< /text >}}
