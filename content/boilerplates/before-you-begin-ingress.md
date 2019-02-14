## Before you begin

1.  Perform the steps in the [Before you begin](/docs/tasks/traffic-management/ingress#before-you-begin) and [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress#determining-the-ingress-ip-and-ports) sections of the
[Control Ingress Traffic](/docs/tasks/traffic-management/ingress) task. After performing those steps you should have Istio and the [httpbin]({{< github_tree >}}/samples/httpbin) service deployed, and the environment variables `INGRESS_HOST` and `SECURE_INGRESS_PORT` set.

1.  For macOS users, verify that you use _curl_ compiled with the [LibreSSL](http://www.libressl.org) library:

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    If a version of _LibreSSL_ is printed as in the output above, your _curl_ should work correctly with the
    instructions in this task. Otherwise, try another installation of _curl_, for example on a Linux machine.
