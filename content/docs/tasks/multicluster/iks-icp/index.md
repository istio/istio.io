---
title: IBM Cloud Kubernetes Service & IBM Cloud Private
description: Multicluster mesh between IBM Cloud Kubernetes Service and IBM Cloud Private.
weight: 75
keywords: [kubernetes,multicluster,hybrid]
aliases:
  - /docs/examples/multicluster/iks-icp/
---

This example shows how to set up VPN connectivity between
an [IBM Cloud Private](https://www.ibm.com/cloud/private) cluster and an
[IBM Cloud Kubernetes Service](https://console.bluemix.net/docs/containers/container_index.html) cluster
and then compose them into a multicluster mesh using a
[single control plane topology](/docs/concepts/multicluster-deployments/#single-control-plane-topology).

## Set up two clusters

1.  [Install One IBM Cloud Private cluster](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/installing/installing.html).
    You can configure Pod CIDR ranges and service CIDR ranges by `network_cidr` and
    `service_cluster_ip_range` in `cluster/config.yaml` for IBM Cloud Private.

    {{< text plain >}}
    ## Network in IPv4 CIDR format
    network_cidr: 10.1.0.0/16
    ## Kubernetes Settings
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  [Request One IBM Cloud Kubernetes Service cluster](https://console.bluemix.net/docs/containers/container_index.html).
    By default, when you have provisioned a IBM Cloud Kubernetes Service cluster, the CIDR is as below.

    {{< text plain >}}
    pod subnet CIDR: 172.30.0.0/16.
    service subnet CIDR: 172.21.0.0/16.
    {{< /text >}}

## Configure pod communication across IBM Cloud Kubernetes Service & IBM Cloud Private

Since these two clusters are in isolated network environments we need to set up VPN connection between them.

1.  Set up strongSwan in IBM Cloud Kubernetes Service cluster:

    1.  Set up helm in IBM Cloud Kubernetes Service by following [these instructions](https://console.bluemix.net/docs/containers/cs_integrations.html).

    1.  Install strongSwan using helm chart by following [these instructions](https://console.bluemix.net/docs/containers/cs_vpn.html),Example configuration parameters from `config.yaml`:

        {{< text plain >}}
        ipsec.auto: add
        remote.subnet: 10.0.0.0/24,10.1.0.0/16
        {{< /text >}}

    1.  Get the external IP of the `vpn-strongswan` service:

        {{< text bash >}}
        $ kubectl get svc vpn-strongswan
        {{< /text >}}

1.  Set up strongSwan in IBM Cloud Private:

    1.  Complete the strongSwan workarounds for IBM Cloud Private by following [these instructions](https://www.ibm.com/support/knowledgecenter/SS2L37_2.1.0.3/cam_strongswan.html).

    1.  Install strongSwan from the catalog in the management console by following [these instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/app_center/create_release.html),example configuration parameters:

        {{< text plain >}}
        Namespace: default
        Operation at startup: start
        Local subnets: 10.0.0.0/24,10.1.0.0/16
        Remote gateway: Public IP of IKS vpn-strongswan service that you get earlier
        Remote subnets: 172.30.0.0/16,172.21.0.0/16
        Privileged authority for VPN pod: checked
        {{< /text >}}

    1.  Verify that IBM Cloud Private can connect to IBM Cloud Kubernetes Service by running the following command on the IBM Cloud Kubernetes Service cluster:

        {{< text bash >}}
        $ export STRONGSWAN_POD=$(kubectl get pod -l app=strongswan,release=vpn -o jsonpath='{ .items[0].metadata.name }')
        $ kubectl exec $STRONGSWAN_POD -- ipsec status
        {{< /text >}}

1.  Confirm pods can communicate by pinging pod IP in IBM Cloud Private from IBM Cloud Kubernetes Service.

    {{< text bash >}}
    $ ping 10.1.14.30
    PING 10.1.14.30 (10.1.14.30) 56(84) bytes of data.
    64 bytes from 10.1.14.30: icmp_seq=1 ttl=59 time=51.8 ms
    {{< /text >}}

## Install Istio for multicluster

[Follow the VPN-based multicluster installation steps](/docs/setup/kubernetes/install/multicluster/vpn/) to install and configure
the local Istio control plane and Istio remote on IBM Cloud Private and IBM Cloud Kubernetes Service.

This example uses IBM Cloud Private as the Istio local control plane and IBM Cloud Kubernetes Service as the Istio remote.

Deploy Bookinfo example across clusters by following [these instructions](/docs/tasks/multicluster/icp/).
