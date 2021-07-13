---
title: "Announcing the results of Istio’s first security assessment"
description: Results of a third-party security review by NCC Group.
publishdate: 2021-07-13
attribution: "Neeraj Poddar (Aspen Mesh), on behalf of Istio Product Security Working Group"
keywords: [istio,security,audit,ncc,assessment]
---

The Istio service mesh has gained wide production adoption across a wide variety of
industries. The success of the project, and its critical usage for enforcing key
security policies in infrastructure warranted an open and neutral assessment of
the security risks associated with the project.

To achieve this goal, the Istio community contracted the
[NCC Group](https://www.nccgroup.com/) last year to
conduct a third-party security assessment of the project. The goal of the review
was "to identify security issues related to the Istio code base, highlight
high-risk configurations commonly used by administrators, and provide
perspective on whether security features sufficiently address the concerns they
are designed to provide".

NCC Group carried out the review over a period of five weeks with collaboration
from subject matter experts across the Istio community. In this blog, we will
examine the key findings of the report, actions taken to implement various fixes
and recommendations, and our plan of action for continuous security evaluation
and improvement of the Istio project. You can download and read the
unabridged version of the
[security assessment report](./NCC_Group_Google_GOIST2005_Report_2020-08-06_v1.1.pdf).

## Scope and Key Findings

The assessment evaluated Istio’s architecture as a whole for security related
issues with focus on key components like istiod (Pilot), Ingress/Egress
gateways, and Istio’s overall Envoy usage as its data plane proxy. Additionally,
Istio documentation, including security guides, were audited for correctness and
clarity. The report was compiled against Istio version 1.6.5, and since then the
Product Security Working Group has issued several security releases as new
vulnerabilities were disclosed, along with fixes to address concerns raised in
the new report.

An important conclusion from the report is that the auditors found no "Critical"
issues within the Istio project. This finding validates the continuous and
proactive security review and vulnerability management process implemented by
Istio’s Product Security Working Group (PSWG). For the remaining issues surfaced
by the report, the PSWG went to work on addressing them, and we are glad to
report that all issues marked "High", and several marked "Medium/Low", have been
resolved in the releases following the report.

The report also makes strategic recommendations around creating a hardening
guide which is now available in our
[Security Best Practices](/docs/ops/best-practices/security/)
guide. This is a comprehensive document which pulls together recommendations
from security experts within the Istio community, and industry leaders running
Istio in production. Work is underway to create an opinionated and hardened
security profile for installing Istio in secure environments, but in the interim
we recommend users follow the Security Best Practices guide and configure Istio
to meet their security requirements. With that, let’s look at the analysis and
resolution for various issues raised in the report.

## Resolution and learnings

### Inability to secure control plane network communications

The report flags configuration options that were available in older versions of
Istio to control how communication is secured to the control plane. Since 1.7,
Istio by default secures all control plane communication and many configuration
options mentioned in the report to manage control plane encryption are no longer
required.

The debug endpoint mentioned in the report is enabled by default (as of Istio
1.10) to allow users to debug their Istio service mesh using the `istioctl` tool.
It can be disabled by setting the environment variable `ENABLE_DEBUG_ON_HTTP` to
false as mentioned in the [Security Best
Practices](/docs/ops/best-practices/security/#control-plane)
guide. Additionally, in an upcoming version (1.11), this debug endpoint will
be secured by default and a valid Kubernetes service account token will be
required to gain access.

### Lack of security related documentation

The report points out gaps in the security related documentation published with
Istio 1.6. Since then, we have created a detailed [Security Best Practices](/docs/ops/best-practices/security/)
guide with recommendations to ensure users can deploy Istio securely to meet
their requirements.  Moving forward, we will continue to augment this
documentation with more hardening recommendations. We advise users to monitor
the guide for updates.

### Lack of VirtualService Gateway field validation enables request hijacking

For this issue, the report uses a valid but permissive Gateway configuration
that can cause requests to be routed incorrectly. Similar to the Kubernetes
RBAC, Istio APIs, including Gateways, can be tuned to be permissive or
restrictive depending upon your requirements.  However, the report surfaced
missing links in our documentation related to best practices and guiding our
users to secure their environments. To address them, we have added a section to
our Security Best Practices guide with steps for running
[Gateways](/docs/ops/best-practices/security/#gateways) securely.
In particular, the section describing [using namespace prefixes in hosts
specification](/docs/ops/best-practices/security/#avoid-overly-broad-hosts-configurations)
on Gateway resources is strongly recommended to harden your
configuration and prevent this type of request hijacking.

### Ingress Gateway configuration generation enables request hijacking

The report raises possible request hijacking when using the default mechanism of
selecting gateway workloads by labels across namespaces in a Gateway resource.
This behavior was chosen by default as it allows delegation of managing Gateway
and VirtualService resources to the applications team while allowing operations
teams to centrally manage the ingress gateway workloads for meeting their unique
security requirements like running on dedicated nodes for instance. As
highlighted in the report, if this deployment topology is not a requirement in
your environment it is strongly recommended to co-locate Gateway resources with
your gateway workloads and set the environment variable
`PILOT_SCOPE_GATEWAY_TO_NAMESPACE` to true.

Please refer to the [gateway deployment topologies guide](/docs/setup/additional-setup/gateway/#gateway-deployment-topologies)
to understand the various recommended deployment models by the
Istio community. Additionally, as mentioned in the
[Security Best Practices](/docs/ops/best-practices/security/#restrict-gateway-creation-privileges)
guide, Gateway resource creation should be access controlled using Kubernetes
RBAC or other policy enforcement mechanisms to ensure only authorized entities
can create them.

### Other Medium and Low Severity Issues

There are two medium severity issues reported related to debug information
exposed at various levels within the project which can be used to gain access to
sensitive information or orchestrate Denial of Service (DOS) attacks. While
Istio by default enables these debug interfaces for profiling or enabling tools
like "istioctl", they can be disabled by setting the environment variable
`ENABLE_DEBUG_ON_HTTP` to false as discussed above.

The report correctly points out that various utilities like `sudo`, `tcpdump`, etc.
installed in the default images shipped by Istio can lead to privilege
escalation attacks. These utilities are  provided to aid runtime debugging of
packets flowing through the mesh, and users are recommended to use
[hardened versions](/docs/ops/configuration/security/harden-docker-images/)
of these images in production.

The report also surfaces a known architectural limitation with any sidecar
proxy-based service mesh implementation which uses `iptables` for intercepting
traffic. This mechanism is susceptible to
[sidecar proxy bypass](/docs/ops/best-practices/security/#understand-traffic-capture-limitations),
which is a valid concern for secure environments. It can be addressed by following the
[defense-in-depth](/docs/ops/best-practices/security/#defense-in-depth-with-networkpolicy)
recommendation of the Security Best Practices guide. We are
also investigating more secure options in collaboration with the Kubernetes
community.

## The tradeoff between useful and secure

You may have noticed a trend in the findings of the assessment and the
recommendations made to address them. Istio provides various configuration
options to create a more secure installation based on your requirement, and we
have introduced a comprehensive [Security Best Practices](/docs/ops/best-practices/security)
guide for our users to follow. As Istio is widely adopted in production, it is
a tradeoff for us between switching to secure defaults and possible migration
issues for our existing users on upgrades. The Istio Product Security Working
Group evaluates each of these issues and creates a plan of action to enable
secure default on a case-by-case basis after giving our users a number of
releases to opt-in the secure configuration and migrate their workloads.

Lastly, there were several lessons for us during and after undergoing a neutral
security assessment. The primary one was to ensure our security practices are
robust to quickly respond to the findings, and more importantly making security
enhancements while maintaining our standards for upgrades without disruption.

To continue this endeavor, we are always looking for feedback and participation
in the Istio Product Security Working Group, so
[join our public meetings](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)
to raise issues or learn about what we are doing to keep Istio secure!
