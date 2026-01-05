const badgeRegex = /\s*\[(\w+?)(?:\|([\w\s]+))?\]\s*$/

window.$docsify ||= {}
window.$docsify.headerBadges ||= {}
window.$docsify.headerBadges.abstract = "grey"
window.$docsify.headerBadges.deprecated = "grey"
window.$docsify.headerBadges.private = "grey"
window.$docsify.headerBadges.readonly = "blue"

window.$docsify.plugins ||= []
window.$docsify.plugins.push(hook => {
  hook.init(() => {
    marked.use({
      walkTokens(token) {
        if (token.type !== "heading") return

        let match
        while (match = token.text.match(badgeRegex)) {
          const color = $docsify.headerBadges[match[1].toLowerCase()]
          if (!color) break

          const label = match[1]
          const status = match[2] || label
          token.text = token.text.replace(badgeRegex, "")
          token.tokens[0].text = token.tokens[0].text.replace(badgeRegex, "")
          token.tokens.splice(1, 0, {
            type: "header-badge",
            label: label,
            status: status,
            color: color,
          })
        }
      },
      extensions: [
        {
          name: "header-badge",
          level: "inline",
          renderer: ({ label, status, color }) => ` <img src="https://badgen.net/badge/x/${status}?color=${color}&scale=1.2&label=${label === status ? "" : label}" />`,
        },
      ],
    })
  })
})
