---
title: ISTIO-SECURITY-2023-005
subtitle: Security Bulletin
description: Changes to Istio CNI RBAC permissions.
cves: []
cvss: N/A
vector: N/A
releases: ["All releases prior to 1.18.0", "1.18.0 to 1.18.5", "1.19.0 to 1.19.4", "1.20.0"]
publishdate: 2023-12-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

The Istio Security Committee were recently made aware of a potential scenario where the Istio CNI could be used as an attack vector on an already compromised node due to its high level of permissions.  The vector involves abusing the `istio-cni-repair-role` `ClusterRole` on a compromised node to expand the scope of the compromise from local to the node to a cluster-wide compromise.

The Istio maintainers are, therefore, gradually rolling out a change to the above `ClusterRole` that reduces the permissions to close this potential attack vector. In the patched versions, roles are limited to the bare minimum requirements based on the [repair mode selected](/docs/setup/additional-setup/cni/#race-condition--mitigation). Previously, regardless of the configuration all roles were granted, and the roles that were granted were excessive.

An additional option can further mitigate any potential attacks, by completely removing the need for Istio CNI to have custom RBAC permissions; due to the possible risks associated with this new method, it is only enabled by default on Istio 1.21+. See below for the configuration options available, and roles required:

|Configuration                    | Roles       | Behavior on Error                                                                                                                           | Notes
|---------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-------
|`values.cni.repair.deletePods`   | DELETE pods | Pods are deleted, when rescheduled they will have the correct configuration.                                                                  | Default in 1.20 and older
|`values.cni.repair.labelPods`    | UPDATE pods | Pods are only labeled.  User will need to take manual action to resolve.                                                                      |
|`values.cni.repair.repairPods`   | None        | Pods are dynamically reconfigured to have appropriate configuration. When the container restarts, the pod will continue normal execution.     | Default in 1.21 and newer

The Istio Security Committee would like to thank `Yuval Avrahami` for disclosing this issue and working with us on the resolution.
