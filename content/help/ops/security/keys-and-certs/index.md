---
title: Keys and Certificates
description: What to do if you suspect problems with Istio keys and certificates.
weight: 20
---

If you suspect that some of the keys and/or certificates used by Istio aren't correct, the
first step is to ensure that [Citadel is healthy](/help/ops/security/repairing-citadel/).

You can then verify that Citadel is actually generating keys and certificates:

{{< text bash >}}
$ kubectl get secret istio.my-sa -n my-ns
NAME                    TYPE                           DATA      AGE
istio.my-sa             istio.io/key-and-cert          3         24d
{{< /text >}}

Where `my-ns` and `my-sa` are the namespace and service account your pod is running as.

If you want to check the keys and certificates of other service accounts, you can run the following
command to list all secrets for which Citadel has generated a key and certificate:

{{< text bash >}}
$ kubectl get secret --all-namespaces | grep istio.io/key-and-cert
NAMESPACE      NAME                                                 TYPE                                  DATA      AGE
.....
istio-system   istio.istio-citadel-service-account                  istio.io/key-and-cert                 3         14d
istio-system   istio.istio-cleanup-old-ca-service-account           istio.io/key-and-cert                 3         14d
istio-system   istio.istio-egressgateway-service-account            istio.io/key-and-cert                 3         14d
istio-system   istio.istio-ingressgateway-service-account           istio.io/key-and-cert                 3         14d
istio-system   istio.istio-mixer-post-install-account               istio.io/key-and-cert                 3         14d
istio-system   istio.istio-mixer-service-account                    istio.io/key-and-cert                 3         14d
istio-system   istio.istio-pilot-service-account                    istio.io/key-and-cert                 3         14d
istio-system   istio.istio-sidecar-injector-service-account         istio.io/key-and-cert                 3         14d
istio-system   istio.prometheus                                     istio.io/key-and-cert                 3         14d
kube-public    istio.default                                        istio.io/key-and-cert                 3         14d
.....
{{< /text >}}

Then check that the certificate is valid with:

{{< text bash >}}
$ kubectl get secret -o json istio.my-sa -n my-ns | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            99:59:6b:a2:5a:f4:20:f4:03:d7:f0:bc:59:f5:d8:40
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = k8s.cluster.local
        Validity
            Not Before: Jun  4 20:38:20 2018 GMT
            Not After : Sep  2 20:38:20 2018 GMT
        Subject: O =
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:c8:a0:08:24:61:af:c1:cb:81:21:90:cc:03:76:
                    01:25:bc:ff:ca:25:fc:81:d1:fa:b8:04:aa:d4:6b:
                    55:e9:48:f2:e4:ab:22:78:03:47:26:bb:8f:22:10:
                    66:47:47:c3:b2:9a:70:f1:12:f1:b3:de:d0:e9:2d:
                    28:52:21:4b:04:33:fa:3d:92:8c:ab:7f:cc:74:c9:
                    c4:68:86:b0:4f:03:1b:06:33:48:e3:5b:8f:01:48:
                    6a:be:64:0e:01:f5:98:6f:57:e4:e7:b7:47:20:55:
                    98:35:f9:99:54:cf:a9:58:1e:1b:5a:0a:63:ce:cd:
                    ed:d3:a4:88:2b:00:ee:b0:af:e8:09:f8:a8:36:b8:
                    55:32:80:21:8e:b5:19:c0:2f:e8:ca:4b:65:35:37:
                    2f:f1:9e:6f:09:d4:e0:b1:3d:aa:5f:fe:25:1a:7b:
                    d4:dd:fe:d1:d3:b6:3c:78:1d:3b:12:c2:66:bd:95:
                    a8:3b:64:19:c0:51:05:9f:74:3d:6e:86:1e:20:f5:
                    ed:3a:ab:44:8d:7c:5b:11:14:83:ee:6b:a1:12:2e:
                    2a:0e:6b:be:02:ad:11:6a:ec:23:fe:55:d9:54:f3:
                    5c:20:bc:ec:bf:a6:99:9b:7a:2e:71:10:92:51:a7:
                    cb:79:af:b4:12:4e:26:03:ab:35:e2:5b:00:45:54:
                    fe:91
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/my-ns/sa/my-sa
    Signature Algorithm: sha256WithRSAEncryption
         78:77:7f:83:cc:fc:f4:30:12:57:78:62:e9:e2:48:d6:ea:76:
         69:99:02:e9:62:d2:53:db:2c:13:fe:0f:00:56:2b:83:ca:d3:
         4c:d2:01:f6:08:af:01:f2:e2:3e:bb:af:a3:bf:95:97:aa:de:
         1e:e6:51:8c:21:ee:52:f0:d3:af:9c:fd:f7:f9:59:16:da:40:
         4d:53:db:47:bb:9c:25:1a:6e:34:41:42:d9:26:f7:3a:a6:90:
         2d:82:42:97:08:f4:6b:16:84:d1:ad:e3:82:2c:ce:1c:d6:cd:
         68:e6:b0:5e:b5:63:55:3e:f1:ff:e1:a0:42:cd:88:25:56:f7:
         a8:88:a1:ec:53:f9:c1:2a:bb:5c:d7:f8:cb:0e:d9:f4:af:2e:
         eb:85:60:89:b3:d0:32:60:b4:a8:a1:ee:f3:3a:61:60:11:da:
         2d:7f:2d:35:ce:6e:d4:eb:5c:82:cf:5c:9a:02:c0:31:33:35:
         51:2b:91:79:8a:92:50:d9:e0:58:0a:78:9d:59:f4:d3:39:21:
         bb:b4:41:f9:f7:ec:ad:dd:76:be:28:58:c0:1f:e8:26:5a:9e:
         7b:7f:14:a9:18:8d:61:d1:06:e3:9e:0f:05:9e:1b:66:0c:66:
         d1:27:13:6d:ab:59:46:00:77:6e:25:f6:e8:41:ef:49:58:73:
         b4:93:04:46
{{< /text >}}

Make sure the displayed certificate contains valid information. In particular, the Subject Alternative Name field should be `URI:spiffe://cluster.local/ns/my-ns/sa/my-sa`.
If this is not the case, it is likely that something is wrong with your Citadel. Try to redeploy Citadel and check again.

Finally, you can verify that the key and certificate are correctly mounted by your sidecar proxy at the directory `/etc/certs`. You
can use this command to check:

{{< text bash >}}
$ kubectl exec -it my-pod-id -c istio-proxy -- ls /etc/certs
cert-chain.pem    key.pem    root-cert.pem
{{< /text >}}

Optionally, you could use the following command to check its contents:

{{< text bash >}}
$ kubectl exec -it my-pod-id -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            7e:b4:44:fe:d0:46:ba:27:47:5a:50:c8:f0:8e:8b:da
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = k8s.cluster.local
        Validity
            Not Before: Jul 13 01:23:13 2018 GMT
            Not After : Oct 11 01:23:13 2018 GMT
        Subject: O =
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:bb:c9:cd:f4:b8:b5:e4:3b:f2:35:aa:4c:67:cc:
                    1b:a9:30:c4:b7:fd:0a:f5:ac:94:05:b5:82:96:b2:
                    c8:98:85:f9:fc:09:b3:28:34:5e:79:7e:a9:3c:58:
                    0a:14:43:c1:f4:d7:b8:76:ab:4e:1c:89:26:e8:55:
                    cd:13:6b:45:e9:f1:67:e1:9b:69:46:b4:7e:8c:aa:
                    fd:70:de:21:15:4f:f5:f3:0f:b7:d4:c6:b5:9d:56:
                    ef:8a:91:d7:16:fa:db:6e:4c:24:71:1c:9c:f3:d9:
                    4b:83:f1:dd:98:5b:63:5c:98:5e:2f:15:29:0f:78:
                    31:04:bc:1d:c8:78:c3:53:4f:26:b2:61:86:53:39:
                    0a:3b:72:3e:3d:0d:22:61:d6:16:72:5d:64:e3:78:
                    c8:23:9d:73:17:07:5a:6b:79:75:91:ce:71:4b:77:
                    c5:1f:60:f1:da:ca:aa:85:56:5c:13:90:23:02:20:
                    12:66:3f:8f:58:b8:aa:72:9d:36:f1:f3:b7:2b:2d:
                    3e:bb:7c:f9:b5:44:b9:57:cf:fc:2f:4b:3c:e6:ee:
                    51:ba:23:be:09:7b:e2:02:6a:6e:e7:83:06:cd:6c:
                    be:7a:90:f1:1f:2c:6d:12:9e:2f:0f:e4:8c:5f:31:
                    b1:a2:fa:0b:71:fa:e1:6a:4a:0f:52:16:b4:11:73:
                    65:d9
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/default/sa/bookinfo-productpage
    Signature Algorithm: sha256WithRSAEncryption
         8f:be:af:a4:ee:f7:be:21:e9:c8:c9:e2:3b:d3:ac:41:18:5d:
         f8:9a:85:0f:98:f3:35:af:b7:e1:2d:58:5a:e0:50:70:98:cc:
         75:f6:2e:55:25:ed:66:e7:a4:b9:4a:aa:23:3b:a6:ee:86:63:
         9f:d8:f9:97:73:07:10:25:59:cc:d9:01:09:12:f9:ab:9e:54:
         24:8a:29:38:74:3a:98:40:87:67:e4:96:d0:e6:c7:2d:59:3d:
         d3:ea:dd:6e:40:5f:63:bf:30:60:c1:85:16:83:66:66:0b:6a:
         f5:ab:60:7e:f5:3b:44:c6:11:5b:a1:99:0c:bd:53:b3:a7:cc:
         e2:4b:bd:10:eb:fb:f0:b0:e5:42:a4:b2:ab:0c:27:c8:c1:4c:
         5b:b5:1b:93:25:9a:09:45:7c:28:31:13:a3:57:1c:63:86:5a:
         55:ed:14:29:db:81:e3:34:47:14:ba:52:d6:3c:3d:3b:51:50:
         89:a9:db:17:e4:c4:57:ec:f8:22:98:b7:e7:aa:8a:72:28:9a:
         a7:27:75:60:85:20:17:1d:30:df:78:40:74:ea:bc:ce:7b:e5:
         a5:57:32:da:6d:f2:64:fb:28:94:7d:28:37:6f:3c:97:0e:9c:
         0c:33:42:f0:b6:f5:1c:0d:fb:70:65:aa:93:3e:ca:0e:58:ec:
         8e:d5:d0:1e
{{< /text >}}
