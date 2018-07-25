---
title: Can I enable Istio Auth with some services while disable others in the same cluster?
weight: 30
---

You can use [authentication policy](/docs/concepts/security/#authentication-policies) to enable (or disable) mutual TLS per service. For example, the policy below will disable mutual TLS on port 9080 for service `details`

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example"
spec:
  targets:
  - name: details
    ports:
    - number: 9080
  peers:
EOF
{{< /text >}}

For older versions of Istio (but newer than 0.3), you can use service-level annotations to disable (or enable) Istio Auth for a particular service and port pair.
The annotation key should be `auth.istio.io/{port_number}`, and the value should be `NONE` (to disable), or `MUTUAL_TLS` (to enable).

For example:

{{< text yaml >}}
kind: Service
metadata:
name: details
labels:
  app: details
annotations:
  auth.istio.io/9080: NONE
{{< /text >}}

The above disables Istio Auth on port 9080 for service `details`.
