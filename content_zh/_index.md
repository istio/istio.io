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
      "description": "Istio 可以用于管理、保护、控制和观测服务。"
    }
</script>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        document.getElementById('card1').style.opacity = "1";

        window.setTimeout(function() {
            document.getElementById('card2').style.opacity = "1";
        }, 375);

        window.setTimeout(function() {
            document.getElementById('card3').style.opacity = "1";
        }, 750);

        window.setTimeout(function() {
            document.getElementById('card4').style.opacity = "1";
        }, 1125);

        window.setTimeout(function() {
            document.getElementById('buttons').style.opacity = "1";
        }, 1500);
    });
</script>

<main class="landing">
    <div class="container-fluid">
        <div class="row justify-content-center">
            {{< inline_image "landing/istio-logo.svg" >}}
            <div class="hero-text">
                <h1 class="hero-label">Istio</h1>
                <h1 class=“hero-lead”>用于连接、保护、控制和观测服务。
            </div>
        </div>
    </div>

    <div class="container-fluid">
        <div class="row justify-content-center">
            <div id="card1" class="card">
                <a href="/zh/docs/concepts/traffic-management/">
                    <div class="card-img-top">
                        {{< inline_image "landing/routing-and-load-balancing.svg" >}}
                     </div>
                    <div class="card-body">
                        <hr class="card-line">
                        <h5 class="card-title text-center">连接</h5>
                        <hr class="card-line">
                        <p class="card-text">
                            智能控制服务之间的流量和 API 调用，进行一系列测试，并通过红/黑部署逐步升级。
                        </p>
                    </div>
                </a>
            </div>

            <div id="card2" class="card">
                <a href="/zh/docs/concepts/security/">
                    <div class="card-img-top">
                        {{< inline_image "landing/resiliency.svg" >}}
                    </div>
                    <div class="card-body">
                        <hr class="card-line">
                        <h5 class="card-title text-center">保护</h5>
                        <hr class="card-line">
                        <p class="card-text">
                            通过托管身份验证、授权和服务之间通信加密自动保护您的服务。
                        </p>
                    </div>
                </a>
            </div>

            <div id="card3" class="card">
                <a href="/zh/docs/concepts/policies-and-telemetry/">
                    <div class="card-img-top">
                        {{< inline_image "landing/policy-enforcement.svg" >}}
                    </div>
                    <div class="card-body">
                        <hr class="card-line">
                        <h5 class="card-title text-center">控制</h5>
                        <hr class="card-line">
                        <p class="card-text">
                            应用策略并确保其执行使得资源在消费者之间公平分配。
                        </p>
                    </div>
                </a>
            </div>

            <div id="card4" class="card">
                <a href="/zh/docs/concepts/policies-and-telemetry/">
                    <div class="card-img-top">
                        {{< inline_image "landing/telemetry-and-reporting.svg" >}}
                    </div>
                    <div class="card-body">
                        <hr class="card-line">
                        <h5 class="card-title text-center">观测</h5>
                        <hr class="card-line">
                        <p class="card-text">
                            通过丰富的自动追踪、监控和记录所有服务，了解正在发生的情况。
                       </p>
                    </div>
                </a>
            </div>
        </div>
    </div>

    <div id="buttons" class="buttons container-fluid">
        <div class="row justify-content-center">
            <a title="在 Kubernetes 上安装 Istio。" class="btn btn-istio" href="/zh/docs/setup/kubernetes/quick-start">开始吧</a>
            <a title="深入了解 Istio 是什么以及它是如何工作的。" class="btn btn-istio" href="/zh/docs/concepts/what-is-istio/">了解更多</a>
            <a title="下载最新版本。" class="btn btn-istio" href="{{< istio_release_url >}}">下载 {{< istio_release_name >}}</a>
        </div>
    </div>
</main>
