function hotload() { window.gtk.hotload(editor.getValue()) }
function load() { window.gtk.load(editor.getValue()) }
function debounce(callback, delay) {
  let timeout;

  return function() {
    clearTimeout(timeout);
    timeout = setTimeout(callback, delay);
  }
}

const toggle = document.querySelector(".dragonruby-live-demo > .toggle")
toggle.addEventListener("click", () => { document.body.classList.toggle("show-demo") })

const el = document.querySelector(".dragonruby-live-demo > .editor")
const editor = ace.edit(el, { mode: "ace/mode/ruby", tabSize: 2 });
editor.commands.addCommand({ name: "save", exec: hotload, bindKey: { mac: "cmd-s", win: "ctrl-s" } });
editor.commands.addCommand({ name: "reload", exec: load, bindKey: { mac: "ctrl-r", win: "ctrl-r" } });
editor.session.on("change", debounce(hotload, 200))
editor.setValue("def tick(args)\n  \nend\n", -1)

const media = window.matchMedia('(prefers-color-scheme: dark)')
const updateTheme = (event) => editor.setTheme(`ace/theme/${event.matches ? "cloud9_night" : "cloud9_day"}`)
media.addEventListener('change', updateTheme)
updateTheme(media)

window.$docsify.plugins.push((hook) => hook.mounted(() => {
  window.$docsify.prism.plugins.toolbar.registerButton("live-demo", {
    text: 'Run Demo',
    onClick: function(env) {
      editor.setValue(env.code, -1)
      load()
      document.body.classList.add("show-demo")
    },
  });
}))
