---
title: Troubleshooting Networking Issues
description: Describes tools and techniques that can be used to root cause networking issues
weight: 5
---

* Migrate content from old troubleshooting guide here

* Provide a few general procedures that should be followed to isolate

* Describe high level isolation steps and things to check.

## Pod reachability issues

Usually, the first thing you want to check is whether or not the POD associated with your app has been allocated with a valid IP address. This can be done by examining the POD status with `kubectl get pods -o wide`. In addition, check whether or not the service associated with the app has been properly created with a service IP. Assuming the POD is up and running and IP is allocated, ping the POD IP and make sure it can be pinged. Otherwise, a few things that may be done to isolate the issue:

* Where is it that you’d like to access the app: from inside the same cluster or outside the cluster. If it’s outside the cluster, find out if port-forward is needed, if the right service type is configured for the service associated with the app, etc. If port-forward is needed, use the `kubectl port-forward` command to configure it.
* can the node where the POD is running be pinged.
* Check route table to make sure that there is a route to the POD IP: `ip route` or `route -n`.
* Check to make sure that the return packet path is also properly configured. This involves checking the route tables, iptables, etc, in the node where the POD is running.
* Check iptables, if necessary, to make sure that packets are not dropped.

## Service naming and Service discovery

A few things that can be checked in this regard:

* Whether or not the service name associated with the app can be properly resolved: login to any other POD’s shell, use `nslookup`, `dig`, etc, to find out if the name can be resolved. Otherwise, check to make sure that
    * `kube-dns` (if used) is running properly
    * `/etc/resolve.conf` is properly configured
* Whether or not the port associated with the app has been opened in the POD: login to the POD or its namespace, and use `netstat` to find out.

## Connection Issues

If your app runs a web service, you can `curl` the URLs that the app supports. If `mTLS` is enabled, make sure proper flags for curl have been used. If it returns errors such as ‘connection refused’, or empty content, things to look at include:

* Whether or not `mTLS` has been enabled and flags used are correct. Refer to [Mutual TLS](docs/tasks/security/mutual-tls/#verifying-keys-and-certificates-installation)
* Whether or not the port used is correct and has been opened: `netstat`
* Whether or not the services that the app is calling are not accessible or return errors: checking the app’s logs with `kubectl log`
* Whether or not iptables has been properly configured for the service associated with the app
* Whether or not the app's envoy sidecar is up and running
* Whether or not the envoy sidecar has errors in its log, especially errors with regard to mesh configuration.
* Whether or not envoy has been configured properly for the service associated with the app to work: `istioctl proxy-status`, `istioctl proxy-config`. Refer to [Debugging Envoy and Pilot](help/ops/traffic-management/proxy-cmd/)

Another useful tool to check connection issues is `nc` or `netcat`.
