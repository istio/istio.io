---
title: Istio
---
<main class="landing">
    <div class="container-fluid">
        <div class="row justify-content-center">
            {{< inline_image "landing/istio-logo.svg" >}}
            <div style="width: 20rem; margin-left: 3rem">
                <h1 class="hero-label">Istio</h1>
                <h1 class=“hero-lead”>用于连接、保护、控制和观测服务。
            </div>
        </div>
    </div>

    <div class="container-fluid">
        <div class="row justify-content-center">
            <div id="card1" class="card">
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
            </div>
            <div id="card2" class="card">
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
            </div>
            <div id="card3" class="card">
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
            </div>
            <div id="card4" class="card">
                <div class="card-img-top">
                    {{< inline_image "landing/telemetry-and-reporting.svg" >}}
                </div>
                <div class="card-body">
                    <hr class="card-line">
                    <h5 class="card-title text-center">观测</h5>
                    <hr class="card-line">
                    <p class="card-text">
                        通过丰富的自动跟踪、监控和记录所有服务，了解正在发生的情况。
                   </p>
                </div>
            </div>
        </div>
    </div>
    <div id="buttons" class="buttons container-fluid">
        <div class="row justify-content-center">
            <a class="btn btn-istio" href="/zh/docs/concepts/what-is-istio/">了解更多</a>
            <a class="btn btn-istio" href="https://github.com/istio/istio/releases/">下载</a>
        </div>
    </div>
</main>
