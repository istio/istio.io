---
title: Iniciar
description: Baixar, instalar, e aprender como avaliar e experimentar os recursos básicos do Istio rapidamente.
weight: 5
aliases:
    - /docs/setup/kubernetes/getting-started/
    - /docs/setup/kubernetes/
    - /docs/setup/kubernetes/install/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
---

Para iniciar com o Istio, siga estas três etapas:

1. [Configure sua plataforma](#platform)
1. [Faça o download de uma release do Istio](#download)
1. [Instale o Istio](#install)

## Configure sua plataforma {#platform}

Antes de instalar o Istio, você precisa de um {{< gloss >}}cluster{{< /gloss >}} executando uma versão compatível do Kubernetes. O Istio {{< istio_version >}} foi testado com as versões {{< supported_kubernetes_versions >}} do Kubernetes.

Crie um cluster selecionando apropriadamente as [instruções da plataforma especifica](/pt-br/docs/setup/platform-setup/).

Algumas plataformas fornecem um {{< gloss >}}managed control plane{{< /gloss >}} que você pode usar em vez de instalar o Istio manualmente. Se esse for o caso da sua plataforma selecionada e você optar por usá-la, você terá concluido a instalação do Istio após a criação do cluster, então você poderá pular as instruções a seguir. Consulte o seu provedor de serviços de plataforma para obter mais detalhes e instruções.

## Faça o download de uma release do Istio {#download}

Faça o download de uma release do Istio, que inclui arquivos de instalação, exemplos e o utilitário de linha de comando [{{< istioctl >}}](/pt-br/docs/reference/commands/istioctl/).

1.  Vá para a página de [release do Istio]({{< istio_release_url >}}) para baixar o arquivo de instalação correspondente ao seu sistema operacional. Como alternativa, em um sistema macOS ou Linux, você pode executar o seguinte comando para baixar e extrair a versão mais recente automaticamente:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

1.  Entre no diretório do pacote do Istio. Por exemplo, se o nome do pacote for
    `istio-{{< istio_full_version >}}`:

    {{< text bash >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    O diretório de instalação contém:

    - Arquivos YAML de instalação do Kubernetes em `install/kubernetes`
    - Exemplos de aplicações em `samples/`
    - O binário [`istioctl`](/pt-br/docs/reference/commands/istioctl) no diretório `bin/`. `istioctl` é
      usado quando injetamos manualmente o Envoy como um proxy sidecar.

1.  Adicione o cliente `istioctl` ao seu path, em um sistema macOS ou Linux:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

1. Você pode habilitar opcionalmente a [opção de auto-completion](/pt-br/docs/ops/diagnostic-tools/istioctl#enabling-auto-completion) se estiver usando os consoles bash ou ZSH .

## Instale o Istio {#install}

Essas instruções pressupõem que você é novo no Istio, fornecendo instruções simplificadas para instalar
o [perfil de configuração](/pt-br/docs/setup/additional-setup/config-profiles/) de  `demo` embutido no Istio.
Esta instalação permite iniciar rapidamente a avaliação do Istio.
Se você já conhece o Istio ou está interessado em instalar outros perfis de configuração
ou um [modelo de deploy](/pt-br/docs/ops/deployment/deployment-models/)
mais avançado, siga [as instruções de instalação com {{< istioctl >}}](/pt-br/docs/setup/install/istioctl).

{{< warning >}}
O perfil de configuração da demonstração não é adequado para avaliação de desempenho.
Ele foi projetado para mostrar a funcionalidade do Istio com altos níveis de rastreamento e log de acesso.
{{< /warning >}}

1. Instale o perfil `demo` 

    {{< text bash >}}
    $ istioctl manifest apply --set profile=demo
    {{< /text >}}

1. Verifique a instalação, assegurando que os seguintes serviços Kubernetes estejam implementados e 
    verifique se todos têm um `CLUSTER-IP` apropriado, exceto o serviço `jaeger-agent`:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                                      AGE
    grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP                                                                                                                                     2m
    istio-citadel            ClusterIP      172.21.177.222   <none>          8060/TCP,15014/TCP                                                                                                                           2m
    istio-egressgateway      ClusterIP      172.21.113.24    <none>          80/TCP,443/TCP,15443/TCP                                                                                                                     2m
    istio-galley             ClusterIP      172.21.132.247   <none>          443/TCP,15014/TCP,9901/TCP                                                                                                                   2m
    istio-ingressgateway     LoadBalancer   172.21.144.254   52.116.22.242   15020:31831/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:30318/TCP,15030:32645/TCP,15031:31933/TCP,15032:31188/TCP,15443:30838/TCP   2m
    istio-pilot              ClusterIP      172.21.105.205   <none>          15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                                       2m
    istio-policy             ClusterIP      172.21.14.236    <none>          9091/TCP,15004/TCP,15014/TCP                                                                                                                 2m
    istio-sidecar-injector   ClusterIP      172.21.155.47    <none>          443/TCP,15014/TCP                                                                                                                            2m
    istio-telemetry          ClusterIP      172.21.196.79    <none>          9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                                       2m
    jaeger-agent             ClusterIP      None             <none>          5775/UDP,6831/UDP,6832/UDP                                                                                                                   2m
    jaeger-collector         ClusterIP      172.21.135.51    <none>          14267/TCP,14268/TCP                                                                                                                          2m
    jaeger-query             ClusterIP      172.21.26.187    <none>          16686/TCP                                                                                                                                    2m
    kiali                    ClusterIP      172.21.155.201   <none>          20001/TCP                                                                                                                                    2m
    prometheus               ClusterIP      172.21.63.159    <none>          9090/TCP                                                                                                                                     2m
    tracing                  ClusterIP      172.21.2.245     <none>          80/TCP                                                                                                                                       2m
    zipkin                   ClusterIP      172.21.182.245   <none>          9411/TCP                                                                                                                                     2m
    {{< /text >}}

    {{< tip >}}
    Se o cluster estiver em execução em um ambiente que não suporta
    um balanceador de carga externo (por exemplo, minikube), o 
    `EXTERNAL-IP` do `istio-ingressgateway` mostrará `<pending>`.
    Para acessar o gateway, use o `NodePort` do serviço ou use um port-forwarding.
    {{< /tip >}}

    Verifique também se os pods Kubernetes correspondentes estão implantados e têm um `STATUS` de `Running`:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                                           READY   STATUS      RESTARTS   AGE
    grafana-f8467cc6-rbjlg                                         1/1     Running     0          1m
    istio-citadel-78df5b548f-g5cpw                                 1/1     Running     0          1m
    istio-egressgateway-78569df5c4-zwtb5                           1/1     Running     0          1m
    istio-galley-74d5f764fc-q7nrk                                  1/1     Running     0          1m
    istio-ingressgateway-7ddcfd665c-dmtqz                          1/1     Running     0          1m
    istio-pilot-f479bbf5c-qwr28                                    1/1     Running     0          1m
    istio-policy-6fccc5c868-xhblv                                  1/1     Running     2          1m
    istio-sidecar-injector-78499d85b8-x44m6                        1/1     Running     0          1m
    istio-telemetry-78b96c6cb6-ldm9q                               1/1     Running     2          1m
    istio-tracing-69b5f778b7-s2zvw                                 1/1     Running     0          1m
    kiali-99f7467dc-6rvwp                                          1/1     Running     0          1m
    prometheus-67cdb66cbb-9w2hm                                    1/1     Running     0          1m
    {{< /text >}}

## Próximos passos

Com o istio instalado, agora você pode fazer o deploy de suas próprias aplicações ou usar uma 
das aplicações de exemplo fornecidas com a instalação.

{{< warning >}}
A aplicação dever usar os protocolos HTTP/1.1 ou HTTP/2.0 
para todo o tráfego HTTP; HTTP/1.0 não é suportado.
{{< /warning >}}

Quando você faz o deploy de sua aplicação usando o `kubectl apply`,
o [Istio sidecar injector](/pt-br/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
injeta automaticamente contêineres Envoy nos seus pods se eles forem iniciados em namespaces 
com label `istio-injection=enabled`:

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

Em namespaces sem a label `istio-injection`, você pode usar o 
[`istioctl kube-inject`](/pt-br/docs/reference/commands/istioctl/#istioctl-kube-inject)
para injetar manualmente containers Envoy nos pods da sua aplicação antes de fazer o deploy:

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

Se você não sabe por onde começar, faça o 
[deploy do exemplo Bookinfo](/pt-br/docs/examples/bookinfo/),
que permitirá avaliar os recursos do Istio para roteamento de tráfego, injeção de falhas, limitação de taxa etc.
Em seguida, explore as várias [tarefas do Istio](/pt-br/docs/tasks/) que lhe interessam.

As tarefas a seguir são um bom local para iniciantes:

- [Roteamento de request](/pt-br/docs/tasks/traffic-management/request-routing/)
- [Injeção de falha](/pt-br/docs/tasks/traffic-management/fault-injection/)
- [Migrando tráfego](/pt-br/docs/tasks/traffic-management/traffic-shifting/)
- [Consultando métricas](/pt-br/docs/tasks/observability/metrics/querying-metrics/)
- [Visualizando métricas](/pt-br/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Coletando logs](/pt-br/docs/tasks/observability/logs/collecting-logs/)
- [Limitando tráfego](/pt-br/docs/tasks/policy-enforcement/rate-limiting/)
- [Ingress gateways](/pt-br/docs/tasks/traffic-management/ingress/ingress-control/)
- [Acessando serviços externos](/pt-br/docs/tasks/traffic-management/egress/egress-control/)
- [Visualizando sua mesh](/pt-br/docs/tasks/observability/kiali/)

O próximo passo é personalizar o Istio e fazer o deploy de suas próprias aplicações.
Antes de instalar e personalizar o Istio para se adequar à sua plataforma e uso 
pretendido, confira os seguintes recursos:

- [Modelos de deployment](/pt-br/docs/ops/deployment/deployment-models/)
- [Melhores práticas de deployment](/pt-br/docs/ops/best-practices/deployment/)
- [Requisitos do Pod](/pt-br/docs/ops/deployment/requirements/)
- [Instruções gerais de instalação](/pt-br/docs/setup/)

Enquanto você continua a usar o Istio, estamos ansiosos para ouvi-lo e recebê-lo
em nossa [comunidade](/pt-br/about/community/join/).

## Desinstalar

A desinstalação exclui as permissões RBAC, a namespace `istio-system` e 
todos os recursos hierarquicamente sob ele. É seguro ignorar erros para recursos inexistentes porque eles podem ter sido excluídos hierarquicamente.

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}
