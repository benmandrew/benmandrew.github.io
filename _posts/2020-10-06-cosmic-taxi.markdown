---
layout:     post
title:      "Cosmic Taxi"
date:       2020-10-06
categories: articles
header:     headers/cosmic.jpg
tag:        "Game Jam Entry"
header_rendering: auto
banner: false
fullwidth: true
---


<div class="webgl-content" style="padding: 20px 0px 30px 0px;">
<canvas id="unity-canvas"></canvas>
<div id="unity-loading-bar">
<div id="unity-logo"></div>
<div id="unity-progress-bar-empty">
<div id="unity-progress-bar-full"></div>
</div>
</div>
</div>

Pick up and drop off people who need a taxi, but avoid hitting the other vehicles!

##### Controls:

- Switch orbits - Left and right arrow keys / A and D
- Open passenger monitor - Right CTRL / Q
- Menu - Escape

A submission for the Ludum Dare 47 Game Jam, made in Unity, and completed over 72 hours.

##### <a href="https://ldjam.com/events/ludum-dare/47/cosmic-taxi">Link to our Ludum Dare submission page</a>

##### <a href="https://github.com/benmandrew/CosmicTaxi">Link to GitHub repository</a>


<script>
var buildUrl = "{{ site.s3_path }}/cosmic";
var loaderUrl = buildUrl + "/Cosmic Taxi.loader.js";
var config = {
    dataUrl: buildUrl + "/Cosmic Taxi.data",
    frameworkUrl: buildUrl + "/Cosmic Taxi.framework.js",
    codeUrl: buildUrl + "/Cosmic Taxi.wasm",
    streamingAssetsUrl: "StreamingAssets",
    companyName: "",
    productName: "Cosmic Taxi",
    productVersion: "1.0",
};
var container = document.querySelector("#unity-container");
var canvas = document.querySelector("#unity-canvas");
var loadingBar = document.querySelector("#unity-loading-bar");
var progressBarFull = document.querySelector("#unity-progress-bar-full");
// var fullscreenButton = document.querySelector("#unity-fullscreen-button");
if (/iPhone|iPad|iPod|Android/i.test(navigator.userAgent)) {
    container.className = "unity-mobile";
    config.devicePixelRatio = 1;
} else {
    canvas.style.width = "100%";
    canvas.style.height = "100%";
}
loadingBar.style.display = "block";
var script = document.createElement("script");
script.src = loaderUrl;
script.onload = () => {
    createUnityInstance(canvas, config, (progress) => {
        progressBarFull.style.width = 100 * progress + "%";
    }).then((unityInstance) => {
        loadingBar.style.display = "none";
        // fullscreenButton.onclick = () => {
        // unityInstance.SetFullscreen(1);
        // };
    }).catch((message) => {
        alert(message);
    });
};
document.body.appendChild(script);
</script>
