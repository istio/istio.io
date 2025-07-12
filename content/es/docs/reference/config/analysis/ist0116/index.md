---
title: DeploymentAssociatedToMultipleServices
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when pods of a deployment are associated with multiple services using the same port but different protocols.

## An example

Consider an Istio mesh with the following services:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: productpage-tcp-v1
spec:
  ports:
    - port: 9080
      name: tcp
      protocol: TCP
  selector:
    app: productpage
---
apiVersion: v1
kind: Service
metadata:
  name: productpage-http-v1
spec:
  ports:
    - port: 9080
      name: http
      protocol: HTTP
  selector:
    app: productpage
{{< /text >}}

This example shows both HTTP and TCP protocols associated with port 9080.

No two services should select the same pod port with different protocols.
