---
title: Troubleshooting Networking Issues
description: Describes tools and techniques that can be used to root cause networking issues
weight: 5
---

You can use the command `istioctl proxy-status` to check the status for all the proxy sidecars running in the mesh. You can also use `istioctl proxy-config` to inspect the mesh configuration. Details on how to use the two commands can be found in [Debugging Envoy and Pilot](/help/ops/traffic-management/proxy-cmd/). If a proxy's xDS status is `STALE`, it usually signals a underlying networking issue between Envoy and Pilot or a bug in the system.

The following is a general high-level troubleshooting guide for networking issues in Kubernetes environment.

## Pod reachability issues

Usually, the first thing you want to check is whether or not the pod associated with your application has been allocated a valid IP address. This can be done by examining the pod status with `kubectl get pods -o wide`. In addition, check whether or not the service associated with the application has been properly created with a service IP. Assuming the pod is up and running and an IP is allocated, ping the pod IP and make sure it can be pinged. Otherwise, a few things that may be tried to isolate the issue:

* Determine where you’d like to access the application: from inside the same cluster or outside the cluster. If it’s outside the cluster, find out if port-forward is needed, if the right service type is configured for the service associated with the application, etc. If port-forward is needed, use the `kubectl port-forward` command to configure it.
* Ping the node where the pod is running.
* Check route table to make sure that there is a route to the pod IP: `ip route` or `route -n`.
* Check to make sure that the return packet path is also properly configured. This involves checking the route tables, iptables, etc, in the node where the pod is running.
* Check iptables to make sure that packets are not dropped.

## Service discovery

If service discovery fails, do the following:

* Check if the service name associated with the application can be properly resolved: login to any other pod’s shell, use `nslookup` or `dig`, to find out if the name can be resolved. Otherwise, check to make sure that
    * `kube-dns` (if used) is running properly
    * `/etc/resolve.conf` is properly configured
* Check if the port associated with the application has been opened in the pod: login to the pod or its namespace, and use `netstat` to find out.

## Connection issues

If your application runs a web service, you can `curl` the URLs that the application supports. If it returns errors such as ‘connection refused’, or empty content:

* Check if `mTLS` has been enabled. And if it is, check the flags in your curl command are correct. Refer to [Mutual TLS](/docs/tasks/security/mutual-tls/#verifying-keys-and-certificates-installation).
* Verify that the port used is correct and has been opened for communication.
* Verify that the services that the application is calling are accessible and return successfully. This can be done by checking the sidecar logs of the application and the services with `kubectl log`.
* Verify that iptables has been properly configured for the service associated with the application.
* Verify that the application's envoy sidecar is up and running. Especially, verify that the sidecar has been successfully connected with istio Pilot. Refer to [Verifying connectivity to Istio Pilot](/help/ops/misc/#verifying-connectivity-to-istio-pilot).
* Verify that the application's envoy sidecar has no significant errors in its log, especially errors with regard to mesh configuration.
* Check Pilot's log and make sure that it doesn't contain errors related to the application.
* Verify that envoy has been configured properly for the service associated with the application to work. Refer to [Debugging Envoy and Pilot](/help/ops/traffic-management/proxy-cmd/) on using `istioctl proxy-status` and `istioctl proxy-config` to do so.

Another useful tool to check connection issues is `nc` or `netcat`, which may be useful for gRPC applications.
