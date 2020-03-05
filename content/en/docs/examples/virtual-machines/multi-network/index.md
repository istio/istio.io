---
title: Virtual Machines in Multi-Network Meshes
description: Learn how to add a service running on a virtual machine to your multi-network
  Istio mesh.
weight: 30
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
aliases:
- /docs/examples/mesh-expansion/multi-network
- /docs/tasks/virtual-machines/multi-network
---

This example provides instructions to integrate a VM or a bare metal host into a
multi-network Istio mesh deployed on Kubernetes using gateways. This approach
doesn't require VPN connectivity or direct network access between the VM, the
bare metal and the clusters.

## Prerequisites

- One or more Kubernetes clusters with versions: {{< supported_kubernetes_versions >}}.

- Virtual machines (VMs) must have IP connectivity to the Ingress gateways in the mesh.

- Services in the cluster must be accessible through the Ingress gateway.

### Preparing the Kubernetes cluster for VMs

The first step when adding non-Kubernetes services to an Istio mesh is to
configure the Istio installation itself, and generate the configuration files
that let VMs connect to the mesh. Prepare the cluster for the VM with the
following commands on a machine with cluster admin privileges:

1. Create a Kubernetes secret for your generated CA certificates using a command similar to the following. See [Certificate Authority (CA) certificates](/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key) for more details.

    {{< warning >}}
    The root and intermediate certificate from the samples directory are widely
    distributed and known.  Do **not** use these certificates in production as
    your clusters would then be open to security vulnerabilities and compromise.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=@samples/certs/ca-cert.pem@ \
        --from-file=@samples/certs/ca-key.pem@ \
        --from-file=@samples/certs/root-cert.pem@ \
        --from-file=@samples/certs/cert-chain.pem@
    {{< /text >}}

1. For a simple setup, deploy Istio control plane into the cluster

        {{< text bash >}}
        $ istioctl manifest apply \
            -f install/kubernetes/operator/examples/vm/values-istio-meshexpansion.yaml
        {{< /text >}}

    For further details and customization options, refer to the
    [installation instructions](/docs/setup/install/istioctl/).
   
   
   Alternatively, the user can create an explicit Service of type LoadBalancer and use
    [Internal Load Balancer](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer) 
    type. User can also deploy a separate ingress Gateway, with internal load balancer type for both mesh expansion and 
    multicluster.  The main requirement is for the exposed address to do TCP load balancing to the Istiod deployment, 
     and for the DNS name associated with the assigned load balancer address to match the certificate provisioned 
     into istiod deployment, defaulting to 'istiod.istio-system.svc'
   

   
1. Define the namespace the VM joins. This example uses the `SERVICE_NAMESPACE`
   environment variable to store the namespace. The value of this variable must
   match the namespace you use in the configuration files later on, and the identity encoded in the certificates.

    {{< text bash >}}
    $ export SERVICE_NAMESPACE="vm"
    {{< /text >}}

1. Determine and store the IP address of the Istio ingress gateway since the VMs
   access [Istiod](/docs/ops/deployment/architecture/#pilot) through this IP address.

    {{< text bash >}}
    $ export GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158
    {{< /text >}}
    

1. Generate a `cluster.env` configuration to deploy in the VMs. This file contains the Kubernetes cluster IP address ranges
    to intercept and redirect via Envoy. You specify the CIDR range when you install Kubernetes as `servicesIpv4Cidr`.
    Replace `$MY_ZONE` and `$MY_PROJECT` in the following example commands with the appropriate values to obtain the CIDR
    after installation:

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $K8S_CLUSTER --zone $MY_ZONE --project $MY_PROJECT --format "value(servicesIpv4Cidr)")
    $ echo -e "ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
    {{< /text >}}
    
    It is also possible to intercept all traffic, as is done for pods. Depending on vendor and installation mechanism
    you may use different commands to determine the IP range used for services and pods. Multiple ranges can be 
    specified if the VM is making requests to multiple K8S clusters.

1. Check the contents of the generated `cluster.env` file. It should be similar to the following example:

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_SERVICE_CIDR=10.55.240.0/20
    {{< /text >}}

1. If the VM only calls services in the mesh, you can skip this step. Otherwise, add the ports the VM exposes
    to the `cluster.env` file with the following command. You can change the ports later if necessary.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> cluster.env
    {{< /text >}}

1. In order to use mesh expansion, the VM must be provisioned with certificates signed by the same root CA as 
    the rest of the mesh. 

    It is recommended to follow the instructions for "Plugging in External CA Key and Certificates", and use a 
     separate intermediary CA for provisioning the VM. There are many tools and procedures for managing 
     certificates for VMs - Istio requirement is that the VM will get a certificate with a Istio-compatible 
     Spifee SAN, with the correct trust domain, namespace and service account the VM will uperate as.

    As an example, for very simple demo setups, you can also use:   
  
    {{< text bash >}}
    $ go run istio.io/istio/security/tools/generate_cert \
          -client -host spiffee://cluster.local/vm/vmname --out-priv key.pem --out-cert cert-chain.pem  -mode citadel
    $ kubectl -n istio-system get cm istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' > root-cert.pem 
    {{< /text >}}

### Setting up the VM

Next, run the following commands on each machine that you want to add to the mesh:

1.  Copy the previously created `cluster.env` and `*.pem` files to the VM. For example:

    {{< text bash >}}
    $ export GCE_NAME="your-gce-instance"
    $ gcloud compute scp --project=${MY_PROJECT} --zone=${MY_ZONE} {key.pem,cert-chain.pem,cluster.env,root-cert.pem} ${GCE_NAME}:~
    {{< /text >}}

1.  Install the Debian package with the Envoy sidecar.

    {{< text bash >}}
    $ gcloud compute ssh --project=${MY_PROJECT} --zone=${MY_ZONE} "${GCE_NAME}"
    $ curl -L https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb > istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1.  Add the IP address of Istio gateway to `/etc/hosts`. Revisit the [preparing the cluster](#preparing-the-kubernetes-cluster-for-vms) section to learn how to obtain the IP address.
The following example updates the `/etc/hosts` file with the Istiod address:

    {{< text bash >}}
    $ echo "${GWIP} istiod.istio-system.svc" | sudo tee -a /etc/hosts
    {{< /text >}}

   A better options is to configure the DNS resolver of the VM to resolve the address, using a split-DNS server. Using 
   /etc/hosts is an easy to use example. It is also possible to use a real DNS and certificate for Istiod, this is beyond
   the scope of this document.

1.  Install `root-cert.pem`, `key.pem` and `cert-chain.pem` under `/etc/certs/`.

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1.  Install `cluster.env` under `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1.  Transfer ownership of the files in `/etc/certs/` and `/var/lib/istio/envoy/` to the Istio proxy.

    {{< text bash >}}
    $ sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy
    {{< /text >}}

1.  Start Istio using `systemctl`.

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}

## Send requests from VM workloads to Kubernetes services

After setup, the machine can access services running in the Kubernetes cluster
or on other VMs.

The following example shows accessing a service running in the Kubernetes cluster from a VM using
`/etc/hosts/`, in this case using a service from the [Bookinfo example](/docs/examples/bookinfo/).


1.  On the added VM connect to the productpage service as in the
    example below:

    {{< text bash >}}
$ curl -v ${GWIP}/productpage
< HTTP/1.1 200 OK
< content-type: text/html; charset=utf-8
< content-length: 1836
< server: envoy
... html content ...
    {{< /text >}}

The `server: istio-envoy` header indicates that the sidecar intercepted the traffic.

## Running services on the added VM

1. Setup an HTTP server on the VM instance to serve HTTP traffic on port 8080:

    {{< text bash >}}
    $ gcloud compute ssh ${GCE_NAME}
    $ python -m SimpleHTTPServer 8080
    {{< /text >}}

1. Determine the VM instance's IP address. For example, find the IP address
    of the GCE instance with the following commands:

    {{< text bash >}}
    $ export GCE_IP=$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances describe ${GCE_NAME})
    $ echo ${GCE_IP}
    {{< /text >}}

1. Add VM services to the mesh

    {{< text bash >}}
    $ istioctl experimental add-to-mesh external-service vmhttp ${VM_IP} http:8080 -n ${SERVICE_NAMESPACE}
    {{< /text >}}

    {{< tip >}}
    Ensure you have added the `istioctl` client to your path, as described in the [download page](/docs/setup/getting-started/#download).
    {{< /tip >}}

1. Deploy a pod running the `sleep` service in the Kubernetes cluster, and wait until it is ready:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. Send a request from the `sleep` service on the pod to the VM's HTTP service:

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local:8080
    {{< /text >}}

    You should see something similar to the output below.

    {{< text html >}}
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
    <title>Directory listing for /</title>
    <body>
    <h2>Directory listing for /</h2>
    <hr>
    <ul>
    <li><a href=".bashrc">.bashrc</a></li>
    <li><a href=".ssh/">.ssh/</a></li>
    ...
    </body>
    {{< /text >}}

**Congratulations!** You successfully configured a service running in a pod within the cluster to
send traffic to a service running on a VM outside of the cluster and tested that
the configuration worked.

## Cleanup

Run the following commands to remove the expansion VM from the mesh's abstract
model.

{{< text bash >}}
$ istioctl experimental remove-from-mesh -n ${SERVICE_NAMESPACE} vmhttp
Kubernetes Service "vmhttp.vm" has been deleted for external service "vmhttp"
Service Entry "mesh-expansion-vmhttp" has been deleted for external service "vmhttp"
{{< /text >}}

