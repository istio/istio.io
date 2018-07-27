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
NAME                                     TYPE            DATA      AGE
istio.my-sa             istio.io/key-and-cert               3      24d
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
$ kubectl exec -it my-pod-id -c istio-proxy ls /etc/certs
cert-chain.pem    key.pem    root-cert.pem
{{< /text >}}
