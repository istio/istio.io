---
title: "Customizing Istio DNS stub names"
subtitle: Changing or adding stub domains to make ServiceEntry hostnames routable
description: Customizing global or region hostnames as declared in ServiceEntry(s) for routability.
publishdate: 2020-05-05
attribution: "Christian Posta (Solo.io)"
keywords: [istio, dns, mTLS, coredns]
---

Istio can be run across multiple clusters and has the necessary configuration APIs to support [shared control plane](/docs/setup/install/multicluster/shared/) or a non-shared, [replicated control model](/docs/setup/install/multicluster/gateways). The motivation for deploying across multiple clusters has been covered excellently by fellow Istio contributor [Vadim Eisenberg](https://twitter.com/vadimeisenberg) in the [Multi-Mesh Deployments for Isolation and Boundary Protection](/blog/2019/isolated-clusters/) blog.

One aspect of multi-cluster functionality enabling services to communicate with each other is service discovery. In an Istio replicated control-plane multi-cluster setup, you create [ServiceEntry](/docs/reference/config/networking/service-entry/)s in one cluster to point to services running in another cluster. For example:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-bar
    spec:
      hosts:
      # must be of form name.namespace.global
      - httpbin.bar.global
      # Treat remote cluster services as part of the service mesh
      # as all clusters in the service mesh share the same root of trust.
      location: MESH_INTERNAL
      ports:
      - name: http1
        number: 8000
        protocol: http
      resolution: DNS
      addresses:
      - 240.0.0.2
      endpoints:
      - address: ${CLUSTER2_GW_ADDR}
        ports:
          http1: 15443 # Do not change this port value
    EOF
    {{< /text >}}

This `ServiceEntry` creates an entry in the Istio service-discovery registry for `httpbin.bar.global` with endpoints that point to a different cluster's gateway. Without any other configuration changes, this hostname, `httpbin.bar.global` is not routable. In the docs for setting up multi-cluster replicated control plane, however, there is a [section for configuring the DNS stubbing](/docs/setup/install/multicluster/gateways/#setup-dns) for your Kubernetes cluster. When we set up the DNS stubbing, we tell `kube-dns` to delegate queries for `.global` to the Istio coredns component.

But what if you don't want to use `.global` as the suffix? What if you have to keep some backward compatibility and the root domain name needs to be something custom? Or what if you want to be able to support multiple root domain suffixes? In the open-source project [Service Mesh Hub](https://github.com/solo-io/service-mesh-hub) that I work on, we had this exact scenario. Service Mesh Hub is used to [automate multi-cluster Istio service mesh deployments](https://docs.solo.io/service-mesh-hub/latest/getting_started/), and routing between clusters is a use case our users have. Here's how to configure it in Istio.

## Istio CoreDNS

Istio's operator allows you to deploy the Istio `coredns` addon component.  For example, you can specify the following in the operator config:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istiocontrolplane-default
  namespace: istio-operator
spec:
  addonComponents:
    istiocoredns:
      enabled: true
{{< /text >}}

When this deploys, we have the `istiocoredns` component that has `coredns` installed as well as the `istio-coredns-plugin` which is used to read `ServiceEntry`s and serve DNS queries for their hostname with IP addresses. The interesting bit is how it's configured out of the box. The default out of the box config is in the `coredns` configmap:

{{< text bash >}}
$ kubectl get cm coredns -n istio-system
{{< /text >}}

Looking into that configmap, we see the following configuration for Istio's `coredns`:

{{< text json >}}
.:53 {
      errors
      health

      # Removed support for the proxy plugin: https://coredns.io/2019/03/03/coredns-1.4.0-release/
      grpc global 127.0.0.1:8053
      forward . /etc/resolv.conf {
        except global
      }

      prometheus :9153
      cache 30
      reload
    }
{{< /text >}}

Understanding how [coredns plugins work](https://coredns.io/plugins/grpc/) is helpful here. We see with the `grpc` statement that we're forwarding `global` domains to `127.0.0.1:8053`, and we're forwarding everything else to `/etc/resolv.conf`. The `istio-coredns-plugin` plugin is another container co-deployed with the `coredns` server and is listening on that `127.0.0.1:8053` port within the pod. If we want to change or add domains that can resolve based on what `ServiceEntry`s are created, we need to modify this file.

For example, to add a `region` domain, we could do something like this:

{{< text yaml>}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: istio-system
  labels:
    app: istiocoredns
    release: istio
data:
  Corefile: |
    region {
             grpc . 127.0.0.1:8053
          }
    .:53 {
          errors
          health
          grpc global 127.0.0.1:8053
          forward . /etc/resolv.conf {
            except global
          }
          prometheus :9153
          cache 30
          reload
        }
{{< /text >}}

With this configuration of Istio's `coredns` component, we could have `ServiceEntry`s that have either hostnames of `foo.bar.region` or `foo.bar.global` resolvable by this DNS server.

## Enable stubs for kube-dns

The last step is to add this new `region` domain stub to the `kube-dns` entries. This is covered in the [replicated control-plane docs](/docs/setup/install/multicluster/gateways/#setup-dns).

## Next steps

In this blog post we saw how to customize the domain name used in global service discovery and routing within Istio. There may be other usecases for customizing this DNS resolution behavior, so hopefully this is helpful for others. We encourage you to try out [Istio multi-cluster](/docs/setup/install/multicluster/gateways).