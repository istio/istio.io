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
            "https://discuss.istio.io/"
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
      "description": "Istio 可以用于管理、保护、控制和观测服务。"
    }
</script>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        document.getElementById('panel1').style.opacity = "1";

        window.setTimeout(function() {
            document.getElementById('panel2').style.opacity = "1";
        }, 375);

        window.setTimeout(function() {
            document.getElementById('panel3').style.opacity = "1";
        }, 750);

        window.setTimeout(function() {
            document.getElementById('panel4').style.opacity = "1";
        }, 1125);

        window.setTimeout(function() {
            document.getElementById('buttons').style.opacity = "1";
        }, 1500);
    });
</script>

<main class="landing">
    <div class="banner">
        {{< inline_image "landing/istio-logo.svg" >}}
        <div class="hero-text">
            <h1 class="hero-label">Istio</h1>
            <h1 class=“hero-lead”>用于连接、保护、控制和观测服务。
        </div>
    </div>

    <div class="panels">
        <div id="panel1" class="panel">
            <a href="/zh/docs/concepts/traffic-management/">
                <div class="panel-img-top">
                    {{< inline_image "landing/routing-and-load-balancing.svg" >}}
                 </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">连接</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        智能控制服务之间的流量和 API 调用，进行一系列测试，并通过红/黑部署逐步升级。
                    </p>
                </div>
            </a>
        </div>

        <div id="panel2" class="panel">
            <a href="/zh/docs/concepts/security/">
                <div class="panel-img-top">
                    {{< inline_image "landing/resiliency.svg" >}}
                </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">保护</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        通过托管身份验证、授权和服务之间通信加密自动保护您的服务。
                    </p>
                </div>
            </a>
        </div>

        <div id="panel3" class="panel">
            <a href="/zh/docs/concepts/policies-and-telemetry/">
                <div class="panel-img-top">
                    {{< inline_image "landing/policy-enforcement.svg" >}}
                </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">控制</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        应用策略并确保其执行使得资源在消费者之间公平分配。
                    </p>
                </div>
            </a>
        </div>

        <div id="panel4" class="panel">
            <a href="/zh/docs/concepts/policies-and-telemetry/">
                <div class="panel-img-top">
                    {{< inline_image "landing/telemetry-and-reporting.svg" >}}
                </div>
                <div class="panel-body">
                    <hr class="panel-line">
                    <h5 class="panel-title">观测</h5>
                    <hr class="panel-line">
                    <p class="panel-text">
                        通过丰富的自动追踪、监控和记录所有服务，了解正在发生的情况。
                   </p>
                </div>
            </a>
        </div>
    </div>

    <div id="buttons">
        <a title="在 Kubernetes 上安装 Istio。" class="btn" href="/zh/docs/setup/kubernetes/quick-start">开始吧</a>
        <a title="深入了解 Istio 是什么以及它是如何工作的。" class="btn" href="/zh/docs/concepts/what-is-istio/">了解更多</a>
        <a title="下载最新版本。" class="btn" href="{{< istio_release_url >}}">下载 {{< istio_release_name >}}</a>
    </div>
</main>
