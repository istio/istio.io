---
title: Text Blocks
description: Basic text blocks.
skip_sitemap: true
---

Plain text block with html tag

{{< text plain >}}
$ kubectl get svc -n istio-system
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)
grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP
...
{{< /text >}}

Bash text block with plain output

{{< text bash >}}
$ this is a text block
$ echo Foo \
Bar
Foo Bar
{{< /text >}}

Bash text block with redirection

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
{{< /text >}}

Bash text block with html tag

{{< text bash >}}
$ kubectl get svc -n istio-system
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)
grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP
...
{{< /text >}}

Bash text block with yaml output and download name

{{< text syntax="bash" outputis="yaml" downloadas="foo.yaml" >}}
$ kubectl -n istio-system get configmap istio-galley-configuration -o jsonpath='{.data}'
map[validatingwebhookconfiguration.yaml:apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  name: istio-galley
  namespace: istio-system
  labels:
    app: istio-galley
    chart: galley-1.0.0
    release: istio
    heritage: Tiller
webhooks:
  - name: pilot.validation.istio.io
    clientConfig:
      service:
        name: istio-galley
        namespace: istio-system
        path: "/admitpilot"
      caBundle: ""
    rules:
      - operations:
      (... snip ...)
{{< /text >}}

Bash text block with json output and download name

{{< text syntax="bash" outputis="json" downloadas="foo.txt" >}}
$ kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"newlog.logentry.istio-system\" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'
{"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
{"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
{{< /text >}}

File-based text block

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

File-based text block with snippet extraction and download name

{{< text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" downloadas="foo.txt" >}}

File-based bash text block with download name

{{< text_import file="test/command_example.txt" syntax="bash" downloadas="foo.sh" >}}

URL-based text block

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" >}}

URL-based text block with snippet extraction

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

URL-based text block with redirects

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/command_example.txt" syntax="bash" >}}
