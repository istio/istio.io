---
title: Identity
---

Identity is a fundamental security infrastructure concept. The Istio identity
model is based on a first-class workload identity. At the beginning of
service-to-service communication, the two parties exchange credentials with
their identity information for mutual authentication purposes.

Clients check the server’s identity against their secure naming information to
determine if the server is authorized to run the service.

Servers check the client's identity to determine what information the client can
access. Servers base that determination on the configured authorization
policies.

Using identity, servers can audit the time information was accessed and what
information was accessed by a specific client. They can also charge clients
based on the services they use and reject any clients that failed to pay their
bill from accessing the services.

The Istio identity model is flexible and granular enough to represent a human
user, an individual service, or a group of services. On platforms without
first-class service identity, Istio can use other identities that can group
service instances, such as service names.

Istio supports the following service identities on different platforms:

- Kubernetes: Kubernetes service account

- GKE/GCE: GCP service account

- GCP: GCP service account

- AWS: AWS IAM user/role account

- On-premises (non-Kubernetes): user account, custom service account, service
  name, Istio service account, or GCP service account. The custom service
  account refers to the existing service account just like the identities that
  the customer’s Identity Directory manages.

Typically, the [trust domain](/docs/reference/glossary/#trust-domain) specifies
the mesh the identity belongs to.
