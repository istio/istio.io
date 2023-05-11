---
title: InvalidGatewayCredential
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

The `InvalidGatewayCredential` message occurs when a Gateway resource references a secret for its TLS configuration, but the secret is either not found or contains an invalid TLS certificate. This message helps identify issues with the TLS configuration of a Gateway resource, which may lead to insecure or non-functional connections.

This message is generated when the following conditions are met:

1. A Gateway resource has a server with a TLS configuration.

1. The TLS configuration references a `credentialName`.

1. The secret with the specified `credentialName` is either not found, or the secret is found but the TLS certificate is invalid.

To resolve this issue, ensure that the secret with the specified `credentialName` exists in the same namespace as the Gateway workload, and that the secret contains a valid TLS certificate. You may need to create or update the secret to fix the problem.

If the secret is missing, create a new secret with the correct TLS certificate and private key. For example, using `kubectl`:

{{< text bash >}}
$ kubectl create secret tls my-tls-secret --cert=path/to/cert.pem --key=path/to/key.pem -n <namespace>
{{< /text >}}

Make sure to replace `<namespace>` with the actual namespace where the Gateway workload is running, and update the file paths to point to the correct certificate and key files.

If the secret is found but the TLS certificate is invalid, update the secret with the correct TLS certificate and private key.
