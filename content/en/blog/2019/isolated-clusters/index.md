---
title: Multi-mesh deployments for isolation and boundary protection
subtitle: Separate applications that require isolation into multiple meshes using mesh federation to enable inter-mesh communication
description: Deploy environments that require isolation into separate meshes and enable inter-mesh communication by mesh federation.
publishdate: 2019-09-26
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,multicluster,security,gateway,tls]
---
Various compliance standards require protection of sensitive data environments. Some of the important standards and the
types of sensitive data they protect appear in the following table:

|Standard|Sensitive data|
| --- | --- |
|[PCI DSS](https://www.pcisecuritystandards.org/pci_security)|payment card data|
|[FedRAMP](https://www.fedramp.gov)|federal information, data and metadata|
|[HIPAA](http://www.gpo.gov/fdsys/search/pagedetails.action?granuleId=CRPT-104hrpt736&packageId=CRPT-104hrpt736)|personal health data|
|[GDPR](https://gdpr-info.eu)| personal data|

[PCI DSS](https://www.pcisecuritystandards.org/pci_security), for example, recommends putting cardholder data
environment on a network, separate from the rest of the system. It also requires using a [DMZ](https://en.wikipedia.org/wiki/DMZ_(computing)),
and setting firewalls between the public Internet and the DMZ, and between the DMZ and the internal network.

Isolation of sensitive data environments from other information systems can reduce the scope of the compliance checks
and improve the security of the sensitive data. Reducing the scope reduces the risks of failing a compliance check and
reduces the costs of compliance since there are less components to check and secure, according to compliance
requirements.

You can achieve isolation of sensitive data by separating the parts of the application that process that data
into a separate service mesh, preferably on a separate network, and then connect the meshes with different
compliance requirements together in a {{< gloss >}}multi-mesh{{< /gloss >}} deployment.
The process of connecting inter-mesh
applications is called {{< gloss >}}mesh federation{{< /gloss >}}.

Note that using mesh federation to create a multi-mesh deployment is very different than creating a
{{< gloss >}}multi-cluster{{< /gloss >}} deployment, which defines a single service mesh composed from services spanning more than one cluster. Unlike multi-mesh, a multi-cluster deployment is not suitable for
applications that require isolation and boundary protection.

In this blog post I describe the requirements for isolation and boundary protection, and outline the principles of
multi-mesh deployments. Finally, I touch on the current state of mesh-federation support and automation work under way for
Istio.

## Isolation and boundary protection

Isolation and boundary protection mechanisms are explained in the
[NIST Special Publication 800-53, Revision 4, Security and Privacy Controls for Federal Information Systems and Organizations](http://dx.doi.org/10.6028/NIST.SP.800-53r4),
_Appendix F, Security Control Catalog, SC-7 Boundary Protection_.

In particular, the _Boundary protection, isolation of information system components_ control enhancement:

{{< quote >}}
Organizations can isolate information system components performing different missions and/or business functions.
Such isolation limits unauthorized information flows among system components and also provides the opportunity to deploy
greater levels of protection for selected components. Separating system components with boundary protection mechanisms
provides the capability for increased protection of individual components and to more effectively control information
flows between those components. This type of enhanced protection limits the potential harm from cyber attacks and
errors. The degree of separation provided varies depending upon the mechanisms chosen. Boundary protection mechanisms
include, for example, routers, gateways, and firewalls separating system components into physically separate networks or
subnetworks, cross-domain devices separating subnetworks, virtualization techniques, and encrypting information flows
among system components using distinct encryption keys.
{{< /quote >}}

Various compliance standards recommend isolating environments that process sensitive data from the rest of the
organization.
The [Payment Card Industry (PCI) Data Security Standard](https://www.pcisecuritystandards.org/pci_security/)
recommends implementing network isolation for _cardholder data_ environment and requires isolating this environment from
the [DMZ](https://en.wikipedia.org/wiki/DMZ_(computing)).
[FedRAMP Authorization Boundary Guidance](https://www.fedramp.gov/assets/resources/documents/CSP_A_FedRAMP_Authorization_Boundary_Guidance.pdf)
describes _authorization boundary_ for federal information and data, while
[NIST Special Publication 800-37, Revision 2, Risk Management Framework for Information Systems and Organizations: A System Life Cycle Approach for Security and Privacy](https://doi.org/10.6028/NIST.SP.800-37r2)
recommends protecting of such a boundary in _Appendix G, Authorization Boundary Considerations_:

{{< quote >}}
Dividing a system into subsystems (i.e., divide and conquer) facilitates a targeted application of controls to achieve
adequate security, protection of individual privacy, and a cost-effective risk management process. Dividing complex
systems into subsystems also supports the important security concepts of domain separation and network segmentation,
which can be significant when dealing with high value assets. When systems are divided into subsystems, organizations
may choose to develop individual subsystem security and privacy plans or address the system and subsystems in the same
security and privacy plans.
Information security and privacy architectures play a key part in the process of dividing complex systems into
subsystems. This includes monitoring and controlling communications at internal boundaries among subsystems and
selecting, allocating, and implementing controls that meet or exceed the security and privacy requirements of the
constituent subsystems.
{{< /quote >}}

Boundary protection, in particular, means:

- put an access control mechanism at the boundary (firewall, gateway, etc.)
- monitor the incoming/outgoing traffic at the boundary
- all the access control mechanisms must be _deny-all_ by default
- do not expose private IP addresses from the boundary
- do not let components from outside the boundary to impact security inside the boundary

Multi-mesh deployments facilitate division of a system into subsystems with different
security and compliance requirements, and facilitate the boundary protection.
You put each subsystem into a separate service mesh, preferably on a separate network.
You connect the Istio meshes using gateways. The gateways monitor and control cross-mesh traffic at the boundary of
each mesh.

## Features of multi-mesh deployments

- **non-uniform naming**. The `withdraw` service in the `accounts` namespace in one mesh might have
different functionality and API than the `withdraw` services in the `accounts` namespace in other meshes.
Such situation could happen in an organization where there is no uniform policy on naming of namespaces and services, or
when the meshes belong to different organizations.
- **expose-nothing by default**. None of the services in a mesh are exposed by default, the mesh owners must
explicitly specify which services are exposed.
- **boundary protection**. The access control of the traffic must be enforced at the ingress gateway, which stops
forbidden traffic from entering the mesh. This requirement implements
[Defense-in-depth principle](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) and is part of some compliance
standards, such as the
[Payment Card Industry (PCI) Data Security Standard](https://www.pcisecuritystandards.org/pci_security/).
- **common trust may not exist**. The Istio sidecars in one mesh may not trust the Citadel certificates in other
meshes, due to some security requirement or due to the fact that the mesh owners did not initially plan to federate
the meshes.

While **expose-nothing by default** and **boundary protection** are required to facilitate compliance and improve
security, **non-uniform naming** and **common trust may not exist** are required when connecting
meshes of different organizations, or of an organization that cannot enforce uniform naming or cannot or may not
establish common trust between the meshes.

An optional feature that you may want to use is **service location transparency**: consuming services send requests
to the exposed services in remote meshes using local service names. The consuming services are oblivious to the fact
that some of the destinations are in remote meshes and some are local services. The access is uniform, using the local
service names, for example, in Kubernetes, `reviews.default.svc.cluster.local`.
**Service location transparency** is useful in the cases when you want to be able to change the location of the
consumed services, for example when some service is migrated from private cloud to public cloud, without changing the
code of your applications.

## The current mesh-federation work

While you can perform mesh federation using standard Istio configurations already today,
it would require writing a lot of boiler-plate YAML files and could be error-prone. There is an effort under way to
automate the mesh federation process.
Before the automation of mesh federation is released, and if you are curious, you
can check [multi-mesh deployment examples](https://github.com/istio-ecosystem/multi-mesh-examples) in
[Istio ecosystem](https://github.com/istio-ecosystem).

## Summary

In this blog post I described the requirements for isolation and boundary protection of sensitive data environments by
using Istio multi-mesh deployments. I outlined the principles of Istio
multi-mesh deployments and reported the current work on
mesh federation in Istio.

I will be happy to hear your opinion about {{< gloss >}}multi-mesh{{< /gloss >}} and
{{< gloss >}}multi-cluster{{< /gloss >}} at [discuss.istio.io](https://discuss.istio.io).
