---
title: Istio
---
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "Organization",
        "url": "https://istio.io",
        "logo": "https://istio.io/img/logo.png",
        "sameAs": [
            "https://twitter.com/IstioMesh",
            "https://istio.rocket.chat/"
        ]
    }
</script>
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "WebSite",
        "url": "https://istio.io/",
        "potentialAction": {
            "@type": "SearchAction",
            "target": "https://istio.io/search.html?q={search_term_string}",
            "query-input": "required name=search_term_string"
        }
    }
</script>
<script type="application/ld+json">
    {
      "@context": "http://schema.org/",
      "@type": "Product",
      "name": "Istio",
      "image": [
          "https://istio.io/img/logo.png"
       ],
      "description": "Istio是一个用来连接、管理和保护微服务的开放平台。"
    }
</script>

<main class="landing">
    <div class="hero">
        <div class="container">
            <h1 class="hero-label">Istio{{< site_suffix >}} {{< istio_version >}}</h1>
            <img class="hero-logo" alt="Istio Logo" src="/img/istio-logo.svg" />
            <h1 class="hero-lead">连接、管理和保护微服务的开放平台</h1>
            <span onclick="getElementById('SCROLLME').scrollIntoView({block: 'start', inline: 'nearest', behavior: 'smooth'})" class="hero-down-arrow fa fa-2 fa-caret-down"></span>
            <span id="SCROLLME"></span>
        </div>
    </div>

    <div class="container-fluid traffic color1">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/routing-and-load-balancing.svg" >}}
            </div>
            <div class="col-12 col-md-5 landing-text">
                <h2>智能路由与负载均衡</h2>
                <p>
                    通过动态路由配置控制服务之间的流量，进行A/B测试、金丝雀发布，使用红/黑部署逐步升级版本。
                    <a href="/docs/concepts/traffic-management/overview/">了解更多...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid resilience color2">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/resiliency.svg" >}}
            </div>
            <div class="col-12 col-md-5 order-md-first landing-text">
                <h2>跨语言和跨平台的弹性</h2>
                <p>
                    通过屏蔽来自片状网络的应用和恶劣条件下的级联故障来提高可靠性。
                    <a href="/docs/concepts/traffic-management/handling-failures/">了解更多...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid policy color1">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/policy-enforcement.svg" >}}
            </div>
            <div class="col-12 col-md-5 landing-text">
                <h2>舰队范围的策略执行</h2>
                <p>
                    在服务交互间应用编制的策略，确保访问策略得到执行且资源在消费者之间公平分配。
                    <a href="/docs/concepts/policies-and-telemetry/overview/">了解更多...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid reporting color2">
        <div class="row align-items-center justify-content-center">
            <div class="col-12 col-md-5">
                {{< inline_image "landing/telemetry-and-reporting.svg" >}}
            </div>
            <div class="col-12 col-md-5 order-md-first landing-text">
                <h2>深度遥测</h2>
                <p>
                    了解服务之间的依赖关系、服务间流量的性质及流向，使用分布式跟踪快速识别问题。
                    <a href="/docs/concepts/what-is-istio/overview/">了解更多...</a>
                </p>
            </div>
        </div>
    </div>

    <div class="container-fluid call color1">
        <div class="row no-gutters">
            <div class="col-12 col-md-6">
                <h2>想了解更多？</h2>
                <p>了解Istio的概念和运行Bookinfo示例来快速开始</p>
                <a class="btn btn-istio" href="/docs/">快速开始</a>
            </div>

            <div class="col-12 col-md-6">
                <h2>准备好开始了吗？</h2>
                <p>下载最新版本</p>
                <a class="btn btn-istio" href="https://github.com/istio/istio/releases/">下载</a>
            </div>
        </div>
    </div>

    <style>
        header .navbar {
            box-shadow: none;
        }

        body {
            padding-top: 2.8rem;
        }

        .navbar-brand {
            visibility: hidden;
        }
    </style>
</main>
