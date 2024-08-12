# Menu: Mini Motorways
# https://www.gameuidatabase.com/index.php?scrn=44&scroll=500&autoload=7593&inspector=1

background = { r: 255, g: 255, b: 255, a: 220 }
accent = { r: 0xF2, g: 0xCA, b: 0x78 }
MENUS[1] = {
  gui: UI.build(background: background, gap: 16, flex: { direction: :column }, justify: { content: :center }, align: { items: :center }) do
    node(background: accent, padding: [12, 24], color: :white, font_size: 32) { text("Resume") }
    node(background: accent, padding: [12, 24], color: :white, font_size: 32) { text("Restart") }
    node(background: accent, padding: [12, 24], color: :white, font_size: 32) { text("Main menu") }
  end,

  tick: -> () do
    $outputs.primitives << accent.to_solid(x: $grid.w - 64 - 24, y: 24, h: 64, w: 64)
    $outputs.primitives << accent.to_solid(x: $grid.w - 64 - 24, y: $grid.h - 64 - 24, h: 64, w: 64)
    $outputs.primitives << accent.to_solid(x: $grid.w - 64 - 128, y: $grid.h - 64 - 24, h: 64, w: 64)
  end,
}
