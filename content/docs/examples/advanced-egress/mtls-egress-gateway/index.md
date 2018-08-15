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

## Cleanup

1.  Perform the instructions in the [Cleanup](/docs/examples/advanced-egress/egress-gateway/#cleanup)
    section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

1.  Delete the directory of the certificates and the repository used to generate them:

    {{< text bash >}}
    $ rm -rf nginx.example.com mtls-go-example
    {{< /text >}}
