---
title: Troubleshooting Networking Issues
description: Describes tools and techniques that can be used to root cause networking issues
weight: 5
---

`istioctl` provides a couple of commands to check proxy status and inspect mesh
configuration:

* `istioctl proxy-status` to check the status for all the proxy sidecars running
  in the mesh.
* `istioctl proxy-config` to inspect the mesh configuration.

You can find details on how to use the two commands in [Debugging Envoy and
Pilot](/help/ops/traffic-management/proxy-cmd/). A proxy's xDS status
of `STALE` usually signals a underlying networking issue between Envoy and Pilot
or a bug in the system.

The following is a high-level troubleshooting guide for networking issues in
Kubernetes environment.

## Pod reachability issues

Usually, the first thing you want to ensure is that Kubernetes has allocated a
valid IP address to the pod associated with your application. To do so, you can
examine the pod status with:

{{< text bash >}}
$ kubectl get pods -o wide
{{< /text >}}

In addition, check whether or not Kubernetes properly created the service
associated with the application. Assuming the pod is up and running and
an IP is allocated, ping the pod IP to ensure it can be pinged. Otherwise, you
can try a few things to isolate the issue:

* Determine how you access the application: from inside the same cluster or from
  outside the cluster. When accessing the application from outside the cluster,
  you should find out if port-forwarding is needed and if the right service type
  is configured for the service associated with the application. When
  port-forwarding is needed, configure it with the `kubectl port-forward`
  command.
* Ping the node where the pod runs.
* To ensure that there is a route to the pod IP, check the route table with `ip
  route` or `route -n`.
* To ensure the return packet path is properly configured, check route tables
  and iptables in the node where the pod runs.
* Check iptables to ensure that it doesn't contain rules that cause packets to
  be dropped.

## Service discovery

If service discovery fails, do the following:

* Ensure `kube-dns` runs properly
* Find a pod that has a container with an image that supports shell and is built
  with tools such as `nslookup` or `dig`. If you run envoy sidecars with the
  debug image, you can login to the shell of one of the sidecars.
* Login to the container’s shell, run `nslookup` or `dig` to find out if the
  name can be resolved.
* Ensure `/etc/resolve.conf` is properly configured to point to kube-dns service.

## Connection issues

If your application runs a web service, you can `curl` the URLs that the
application supports. If `curl` returns errors such as ‘connection refused’, or
empty content:

* Check if mutual TLS (`mTLS`) has been enabled. And if it is enabled, check the
  flags in your `curl` command are correct. Refer to [Mutual
  TLS](/docs/tasks/security/mutual-tls/#verifying-keys-and-certificates-installation).
* Verify that the port used is correct and is open for communication. You can
  login to one of the pods' container and run `netstat -l` to see all the
  listeners that are open for communication.
* Verify that the application's envoy sidecar is up and running.
* Verify that the sidecar has been successfully connected with istio Pilot.
  Refer to [Verifying connectivity to Istio
  Pilot](/help/ops/misc/#verifying-connectivity-to-istio-pilot).
* To verify that the services that the application calls are accessible and
  return successfully, check the sidecar logs of the application and the
  services with `kubectl log`.
* Verify that iptables has been properly configured for the service associated
  with the application.
* Verify the log of the application's envoy sidecar has no significant errors.
  Look specifically those errors regarding mesh configuration.
* Ensure Pilot's log doesn't contain errors related to the application.
