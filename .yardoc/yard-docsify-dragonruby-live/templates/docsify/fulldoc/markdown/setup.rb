def assets
  super + [
    "javascripts/live-demo.js",
    "stylesheets/live-demo.css",
    "dragonruby-live-demo.html",
    "dragonruby-loader.js",
    "dragonruby-serviceworker.js",
    "dragonruby/manifest.json",
    "dragonruby/wasm.js",
    "dragonruby/wasm.wasm",
    "dragonruby/wasm.worker.js",
    "dragonruby/gamedata/font.ttf",
  ]
end
