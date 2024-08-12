# Menu: Mini Motorways (Switch)
# https://www.gameuidatabase.com/index.php?scrn=44&scroll=500&autoload=58807&inspector=1

background = { r: 255, g: 255, b: 255, a: 220 }
active = { r: 0xF2, g: 0xCA, b: 0x78 }
inactive = { r: 0xC6, g: 0xD8, b: 0xD8 }
dark = { r: 0x3C, g: 0x42, b: 0x47 }
MENUS[2] = {
  gui: UI.build(background: background, justify: { content: :center }, align: { items: :center }) do
    node(color: :white, font_size: 32, gap: 16, flex: { direction: :column }, align: { items: :start }) do
      node(background: active, padding: [12, 24]) { text("Resume") }
      node(background: inactive, padding: [12, 24]) { text("Restart") }
      node(background: inactive, padding: [12, 24]) { text("Main menu") }
      node(color: :dark) do
        node(background: dark, width: 40, height: 40, margin: { right: 16 })
        text("Night Mode")
      end
    end
  end,

  tick: -> () do
    $outputs.primitives << dark.to_solid(x: $grid.w - 48 - 24, y: 24, h: 48, w: 48)
  end,
}
