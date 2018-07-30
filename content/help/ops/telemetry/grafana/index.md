---
title: Grafana
description: Dealing with Grafana issues.
weight: 90
---

If you're unable to get Grafana output when connecting from a local web client to Istio remotely hosted, you
should validate the client and server date and time match.

The time of the web client (e.g. Chrome) affects the output from Grafana. A simple solution
to this problem is to verify a time synchronization service is running correctly within the
Kubernetes cluster and the web client machine also is correctly using a time synchronization
service. Some common time synchronization systems are NTP and Chrony. This is especially
problematic in engineering labs with firewalls. In these scenarios, NTP may not be configured
properly to point at the lab-based NTP services.
