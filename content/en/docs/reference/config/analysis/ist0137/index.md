---
title: DeploymentConflictingPorts
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when two services selecting the same workload with same target port but different ports.

## An example

Consider an Istio mesh with the following services:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: conflicting-ports-1
  namespace: bookinfo
  labels:
    app: conflicting-ports
spec:
  ports:
    - port: 9080
      name: tcp
      targetPort: 9080
      protocol: TCP
  selector:
    app: conflicting-ports
---
apiVersion: v1
kind: Service
metadata:
  name: conflicting-ports-2
  namespace: bookinfo
  labels:
    app: conflicting-ports
spec:
  ports:
    - port: 9090
      name: http
      targetPort: 9080
      protocol: HTTP
  selector:
    app: conflicting-ports
{{< /text >}}

## How to resolve

Delete one of the services or modify these to the same port.
