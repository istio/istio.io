---
title: Is the secret encrypted for workload key and cert?
order: 125
type: markdown
---
{% include home.html %}

By default, they are base64 encoded but not encrypted. However, the [secret encryption feature](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) is supported in Kubernetes and you can do it by following the instruction.

Notice that this feature is not enabled yet in Google Container Enginer (GKE). While the data may not be encrypted inside the etcd running on the master node, the contents of the master node itself are encrypted, see [here](https://cloud.google.com/security/encryption-at-rest/default-encryption/#encryption_of_data_at_rest) for more info.
