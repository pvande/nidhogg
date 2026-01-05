import "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/toolbar/prism-toolbar.min.js"

export const isAbsolutePath = path => /(:|(\/{2}))/g.test(path)

window.$docsify.prism = window.Prism

window.$docsify.plugins ||= []
// window.$docsify.plugins.unshift((hook, vm) => hook.init(() => {
//   // debugger;
//   // vm
//   // console.dir(marked.defaults)
//   // console.dir(vm.config.markdown)
//   // console.dir(marked.defaults)
//   marked.setOptions($docsify.markdown)
//   marked.use(markedAlert())
//   window.marked = marked
// }))
window.$docsify.plugins.unshift((hook, vm) => {
  // hook.mounted(() => window.docsifyInstance = vm)

  // hook.beforeEach(content => {
  //   vm.isUnprocessed = !vm.isHTML
  //   vm.isHTML = true
  //   return content
  // })
  // hook.afterEach((content) => {
  //   if (vm.isUnprocessed) content = marked(content)
  //   return content
  // })
})
window.$docsify.plugins.push((hook) => hook.doneEach(window.$docsify.prism.highlightAll))
window.$docsify.markdown ||= {}
window.$docsify.markdown.renderer ||= {
  // code: (code, lang) => {
  //   return `<pre v-pre data-lang="${lang}"><code class="lang-${lang}">${new Option(code).innerHTML}</code></pre>`
  // },
}

const tag = document.createElement("script")
tag.src = "https://cdn.jsdelivr.net/npm/docsify@4"
document.body.append(tag)
