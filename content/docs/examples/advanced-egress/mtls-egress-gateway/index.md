---
title: Configure an Egress Gateway with mutual TLS
description: Describes how to configure an Egress Gateway to perform mutual TLS to external services
weight: 45
keywords: [traffic-management,egress]
---

The [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example describes how to configure
Istio to direct the egress traffic through a dedicated service called _Egress Gateway_. This examples shows how to
configure an Egress Gateway to perform mutual TLS to external services.
You will deploy an [NGINX](https://www.nginx.com/) server in your Kubernetes cluster without injecting Istio sidecar
proxy into it.
This server will exemplify a server outside the Istio service mesh. Then you will confifure the Egress Gateway to
perform mutual TLS with this server.
Finally, you will direct the traffic from the application pods inside the mesh to the server outside the mesh through
the Egress Gateway.

## Before you begin

This examples assumes you deployed Istio with [mutual TLS Authentication](/docs/tasks/security/mutual-tls/)
enabled. Follow the steps in the [Before you begin](/docs/examples/advanced-egress/egress-gateway/#before-you-begin)
section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

## Generate client and server certificates and keys

Generate the certificates and keys in the same way as in the [Securing Gateways with HTTPS](docs/tasks/traffic-management/secure-ingress/#generate-client-and-server-certificates-and-keys).

1.  Clone the <https://github.com/nicholasjackson/mtls-go-example> repository:

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  Change directory to the cloned repository:

    {{< text bash >}}
    $ pushd mtls-go-example
    {{< /text >}}

1.  Generate the certificates for `nginx.example.com`. Use any password with the following command:

    {{< text bash >}}
    $ ./generate.sh nginx.example.com <password>
    {{< /text >}}

    When prompted, select `y` for all the questions.

1.  Move the certificates into `nginx.example.com` directory:

    {{< text bash >}}
    $ mkdir ~+1/nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ~+1/nginx.example.com
    {{< /text >}}

1.  Change directory back:

    {{< text bash >}}
    $ popd
    {{< /text >}}

## Deploy an Nginx server

1.  Create a namespace `mesh-external` to represent services outside the Istio mesh. Note that the sidecar proxy will
    not be automatically injected into the pods in this namespace since the automatic sidecar injection was not
    [enabled](/docs/setup/kubernetes/sidecar-injection/#deploying-an-app) on it.

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the server's and
   client's certificates and private keys.

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
    $ kubectl create -n istio-system secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1.  Create a configuration file for the NGINX server:

    {{< text bash >}}
    $ cat <<EOF > ./nginx.conf
    events {
    }

    stream {
      log_format log_stream '\$remote_addr [\$time_local] \$protocol'
      '\$status \$bytes_sent \$bytes_received \$session_time';

      access_log /var/log/nginx/access.log log_stream;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name localhost;
        ssl_certificate /etc/nginx-server-certificates/tls.crt;
        ssl_certificate_key /etc/nginx-server-certificates/tls.key;
        ssl_client_certificate /etc/nginx-client-certificates/ca-chain.cert.pem;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}


## Cleanup

1.  Perform the instructions in the [Cleanup](/docs/examples/advanced-egress/egress-gateway/#cleanup)
    section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

1.  Remove created Kubernetes resources:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret nginx-client-certs -n istio-system
    $ kubectl delete namespace mesh-external
    {{< /text >}}

1.  Delete the directory of the certificates and the repository used to generate them:

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}

1.  Delete the generated configuration files used in this example:

    {{< text bash >}}
    $ rm -f ./nginx.conf
    {{< /text >}}
