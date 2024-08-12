# Menu: Carto
# https://www.gameuidatabase.com/index.php?scrn=44&scroll=500&autoload=29541&inspector=1

background = { r: 0x1C, g: 0x27, b: 0x27, a: 220 }
active = { r: 0xFF, g: 0xFF, b: 0xFF }
inactive = active.merge(a: 120)
MENUS[3] = {
  gui: UI.build(color: inactive, font_size: 24, justify: { content: :center }, align: { items: :center }) do
    node(background: background, padding: 32, gap: 16, flex: { direction: :column }, align: { items: :center }) do
      node { text("Resume Game") }
      node { text("Settings") }
      node { text("Load Last Checkpoint") }
      node(color: active) { text("Save & Exit") }
    end
  end,
}
