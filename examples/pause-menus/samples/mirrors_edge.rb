# Menu: Mirror's Edge
# https://www.gameuidatabase.com/index.php?scrn=44&scroll=500&autoload=33451&inspector=1

background = { r: 255, g: 255, b: 255, a: 200 }
accent = { r: 0xEA, g: 0x18, b: 0x00 }
shadow = { a: 0x50 }
dark = { r: 0x3C, g: 0x42, b: 0x47 }
MENUS[4] = {
  gui: UI.build(background: background) do
    node(grow: 1)
    node(background: accent, color: :white, font_size: 24, width: 450, flex: { direction: :column }) do
      node(grow: 1, padding: 24, flex: { direction: :column }, justify: { content: :center }) do
        text "GAME PAUSED"
        text "THE EDGE", font_size: 48
      end
      node(grow: 1, flex: { direction: :column }) do
        node(background: :white, color: dark, padding: [8, 24], font_size: 32) { text("Resume Game") }
        node(color: :white, padding: [8, 24], font_size: 32) { text("Options") }
        node(color: :white, padding: [8, 24], font_size: 32) { text("Quit to Main Menu") }
      end
    end
    node(width: 6, background: shadow)
    node(grow: 1) do
    end
  end,

  tick: -> () do
    hints = UI.build(font_size: 24, align: { items: :center }) do
      node(dark.to_solid, height: 40, width: 40, margin: { right: 8, left: 32 })
      text "SELECT"

      node(dark.to_solid, height: 40, width: 40, margin: { right: 8, left: 32 })
      text "BACK"
    end
    UI::Layout.apply(hints, target: { right: $grid.w - 96, bottom: 48 })
    $outputs.primitives << hints
  end,
}
