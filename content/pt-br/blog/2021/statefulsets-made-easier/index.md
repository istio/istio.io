---
title: "StatefulSets Made Easier With Istio 1.10"
description: Learn how to easily deploy StatefulSets with Istio 1.10.
publishdate: 2021-05-19
attribution: "Lin Sun (Solo.io), Christian Posta (Solo.io), John Howard (Google), Zhonghu Xu (Huawei)"
keywords: [statefulset,Istio,networking,localhost,loopback,eth0]
---

Kubernetes [`StatefulSets`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) are commonly used to manage stateful applications. In addition to managing the deployment and scaling of a set of `Pods`, `StatefulSets` provide guarantees about the ordering and uniqueness of those `Pods`. Common applications used with `StatefulSets` include ZooKeeper, Cassandra, Elasticsearch, Redis and NiFi.

The Istio community has been making gradual progress towards zero-configuration support for `StatefulSets`; from automatic mTLS, to eliminating the need to create `DestinationRule` or `ServiceEntry` resources, to the most recent [pod networking changes in Istio 1.10](/blog/2021/upcoming-networking-changes/).

What is unique about using a `StatefulSet` with a service mesh? The `StatefulSet` pods are created from the same spec, but are not interchangeable: each has a persistent identifier that it maintains across any rescheduling. The kind of apps that run in a `StatefulSet` are often those that need to communicate among their pods, and, as they come from a world of hard-coded IP addresses, may listen on the pod IP only, instead of `0.0.0.0`.

ZooKeeper, for example, is configured by default to not listen on all IPs for quorum communication:

{{< text plain >}}
quorumListenOnAllIPs=false
{{< /text >}}

Over the last few releases, the Istio community has [reported many issues](https://github.com/istio/istio/issues/10659) around support for applications running in `StatefulSets`.

## `StatefulSets` in action, prior to Istio 1.10

In a GKE cluster running Kubernetes 1.19, we have Istio 1.9.5 installed. We enabled automatic sidecar injection in the `default` namespace, then we installed ZooKeeper using the [Helm charts provided by Bitnami](https://artifacthub.io/packages/helm/bitnami/zookeeper), along with the Istio `sleep` pod for interactive debugging:

{{< text bash >}}
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm install my-release bitnami/zookeeper --set replicaCount=3
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

After a few minutes, all pods come up nicely with sidecar proxies:

{{< text bash yaml >}}
$ kubectl get pods,svc
NAME                             READY   STATUS    RESTARTS   AGE
my-release-zookeeper-0           2/2     Running   0          3h4m
my-release-zookeeper-1           2/2     Running   0          3h4m
my-release-zookeeper-2           2/2     Running   0          3h5m
pod/sleep-8f795f47d-qkgh4        2/2     Running   0          3h8m

NAME                            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                            AGE
my-release-zookeeper            ClusterIP   10.100.1.113   <none>        2181/TCP,2888/TCP,3888/TCP         3h
my-release-zookeeper-headless   ClusterIP   None           <none>        2181/TCP,2888/TCP,3888/TCP         3h
service/sleep                   ClusterIP   10.100.9.26    <none>        80/TCP                             3h
{{< /text >}}

Are our ZooKeeper services working and is the status `Running`? Let’s find out! ZooKeeper listens on 3 ports:

* Port 2181 is the TCP port for clients to connect to the ZooKeeper service
* Port 2888 is the TCP port  for peers to connect to other peers
* Port 3888 is the dedicated TCP port for leader election

By default, the ZooKeeper installation configures port 2181 to listen on `0.0.0.0` but ports 2888 and 3888 only listen on the pod IP. Let’s check out the network status on each of these ports from one of the ZooKeeper pods:

{{< text bash yaml >}}
$ kubectl exec my-release-zookeeper-1 -c istio-proxy -- netstat -na | grep -E '(2181|2888|3888)'
tcp        0      0 0.0.0.0:2181            0.0.0.0:*               LISTEN
tcp        0      0 10.96.7.7:3888          0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:2181          127.0.0.1:37412         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37486         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37456         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37498         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37384         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37514         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37402         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37434         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37526         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37374         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37442         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:37464         TIME_WAIT
{{< /text >}}

There is nothing `ESTABLISHED` on port 2888 or 3888.  Next, let us get the ZooKeeper server status:

{{< text bash yaml >}}
$ kubectl exec my-release-zookeeper-1 -c zookeeper -- /opt/bitnami/zookeeper/bin/zkServer.sh status
/opt/bitnami/java/bin/java
ZooKeeper JMX enabled by default
Using config: /opt/bitnami/zookeeper/bin/../conf/zoo.cfg
Client port found: 2181. Client address: localhost. Client SSL: false.
Error contacting service. It is probably not running.
{{< /text >}}

From the above output, you can see the ZooKeeper service is not functioning properly. Let us check the cluster configuration for one of the ZooKeeper pods:

{{< text bash yaml >}}
$ istioctl proxy-config cluster my-release-zookeeper-1 --port 3888 --direction inbound -o json
[
    {
        "name": "inbound|3888||",
        "type": "STATIC",
        "connectTimeout": "10s",
        "loadAssignment": {
            "clusterName": "inbound|3888||",
            "endpoints": [
                {
                    "lbEndpoints": [
                        {
                            "endpoint": {
                                "address": {
                                    "socketAddress": {
                                        "address": "127.0.0.1",
                                        "portValue": 3888
                                    }
                                }
                            }
                        }
                    ]
                }
            ]
        },
...
{{< /text >}}

What is interesting here is that the inbound on port 3888 has `127.0.0.1` as its endpoint. This is because the Envoy proxy, in versions of Istio prior to 1.10, redirects the inbound traffic to the `loopback` interface, as described in [our blog post about the change](/blog/2021/upcoming-networking-changes/).

## `StatefulSets` in action with Istio 1.10

Now, we have upgraded our cluster to Istio 1.10 and configured the `default` namespace to enable 1.10 sidecar injection. Let’s rolling restart the ZooKeeper `StatefulSet` to update the pods to use the new version of the sidecar proxy:

{{< text bash >}}
$ kubectl rollout restart statefulset my-release-zookeeper
{{< /text >}}

Once the ZooKeeper pods reach the running status, let’s check out the network connections for these 3 ports from any of the ZooKeeper pods:

{{< text bash yaml >}}
$ kubectl exec my-release-zookeeper-1 -c istio-proxy -- netstat -na | grep -E '(2181|2888|3888)'
tcp        0      0 0.0.0.0:2181            0.0.0.0:*               LISTEN
tcp        0      0 10.96.8.10:2888         0.0.0.0:*               LISTEN
tcp        0      0 10.96.8.10:3888         0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.6:42571         10.96.8.10:2888         ESTABLISHED
tcp        0      0 10.96.8.10:2888         127.0.0.6:42571         ESTABLISHED
tcp        0      0 127.0.0.6:42655         10.96.8.10:2888         ESTABLISHED
tcp        0      0 10.96.8.10:2888         127.0.0.6:42655         ESTABLISHED
tcp        0      0 10.96.8.10:37876        10.96.6.11:3888         ESTABLISHED
tcp        0      0 10.96.8.10:44872        10.96.7.10:3888         ESTABLISHED
tcp        0      0 10.96.8.10:37878        10.96.6.11:3888         ESTABLISHED
tcp        0      0 10.96.8.10:44870        10.96.7.10:3888         ESTABLISHED
tcp        0      0 127.0.0.1:2181          127.0.0.1:54508         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54616         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54664         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54526         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54532         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54578         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54634         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54588         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54610         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54550         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54560         TIME_WAIT
tcp        0      0 127.0.0.1:2181          127.0.0.1:54644         TIME_WAIT
{{< /text >}}

There are `ESTABLISHED` connections on both port 2888 and 3888!  Next, let us check out the ZooKeeper server status:

{{< text bash yaml >}}
$ kubectl exec my-release-zookeeper-1 -c zookeeper -- /opt/bitnami/zookeeper/bin/zkServer.sh status
/opt/bitnami/java/bin/java
ZooKeeper JMX enabled by default
Using config: /opt/bitnami/zookeeper/bin/../conf/zoo.cfg
Client port found: 2181. Client address: localhost. Client SSL: false.
Mode: follower
{{< /text >}}

The ZooKeeper service is now running!

We can connect to each of the ZooKeeper pods from the `sleep` pod and run the below command to discover the server status of each pod within the `StatefulSet`. Note that there is no need to create ServiceEntry resources for any of the ZooKeeper pods and we can call these pods directly using their DNS names (e.g. `my-release-zookeeper-0.my-release-zookeeper-headless`) from the `sleep` pod.

{{< text bash yaml >}}
$ kubectl exec -it deploy/sleep -c sleep -- sh  -c 'for x in my-release-zookeeper-0.my-release-zookeeper-headless my-release-zookeeper-1.my-release-zookeeper-headless my-release-zookeeper-2.my-release-zookeeper-headless; do echo $x; echo srvr|nc $x 2181; echo; done'
my-release-zookeeper-0.my-release-zookeeper-headless
Zookeeper version: 3.7.0-e3704b390a6697bfdf4b0bef79e3da7a4f6bac4b, built on 2021-03-17 09:46 UTC
Latency min/avg/max: 1/7.5/20
Received: 3845
Sent: 3844
Connections: 1
Outstanding: 0
Zxid: 0x200000002
Mode: follower
Node count: 6

my-release-zookeeper-1.my-release-zookeeper-headless
Zookeeper version: 3.7.0-e3704b390a6697bfdf4b0bef79e3da7a4f6bac4b, built on 2021-03-17 09:46 UTC
Latency min/avg/max: 0/0.0/0
Received: 3856
Sent: 3855
Connections: 1
Outstanding: 0
Zxid: 0x200000002
Mode: follower
Node count: 6

my-release-zookeeper-2.my-release-zookeeper-headless
Zookeeper version: 3.7.0-e3704b390a6697bfdf4b0bef79e3da7a4f6bac4b, built on 2021-03-17 09:46 UTC
Latency min/avg/max: 0/0.0/0
Received: 3855
Sent: 3854
Connections: 1
Outstanding: 0
Zxid: 0x200000002
Mode: leader
Node count: 6
Proposal sizes last/min/max: 48/48/48
{{< /text >}}

Now our ZooKeeper service is running, let’s use Istio to secure all communication to our regular and headless services. Apply mutual TLS to the `default` namespace:

{{< text bash >}}
$ kubectl apply -n default -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Continue sending some traffic from the `sleep` pod and bring up the Kiali dashboard to visualize the services in the `default` namespace:

{{< image link="./view-zookeeper-from-kiali.png" caption="Visualize the ZooKeeper Services in Kiali" >}}

The padlock icons on the traffic flows indicate that the connections are secure.

## Wrapping up

With the new networking changes in Istio 1.10, a Kubernetes pod with a sidecar has the same networking behavior as a pod without a sidecar. This change enables stateful applications to function properly in Istio as we have shown you in this post. We believe this is a huge step towards Istio’s goal of providing transparent service mesh and zero-configuration Istio.
