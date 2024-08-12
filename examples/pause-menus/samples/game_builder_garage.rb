# Menu: Game Builder Garage
# https://www.gameuidatabase.com/index.php?scrn=44&scroll=500&autoload=57117&inspector=1

background = { r: 0x1C, g: 0x27, b: 0x27, a: 220 }
accent = { r: 0xFA, g: 0xD1, b: 0x1E }
white = { r: 0xFF, g: 0xFF, b: 0xFF }
dark = { r: 0x33, g: 0x35, b: 0x48 }
grey = dark.merge(a: 100)
MENUS[5] = {
  gui: UI.build(background: background, font_size: 24, justify: { content: :center }, align: { items: :center }) do
    node(background: accent, flex: { direction: :column }) do
      node(padding: 24, gap: 16, flex: { direction: :column }) do
        node(justify: { content: :center }, align: { items: :center }, gap: 24 ) do
          node(align: { items: :center }, gap: 12) do
            node(dark.to_border, height: 40, width: 40)
            node(font_size: 20, flex: { direction: :column }, align: { items: :center }) do
              text("Free")
              text("Programming")
            end
          end
          node(width: 3, background: grey)
          text "No title"
        end
        node(height: 3, background: dark)
        node(color: grey, font_size: 16, justify: { content: :end }, gap: 12) do
          text "Nodon ▶︎ 6/512"
          text "Connections ▶︎ 3/1024"
        end
        node(background: white, border: { color: dark, width: 2 }, padding: 48, flex: { direction: :column }, align: { items: :center }) do
          text "Edit game title"
        end
        node(gap: 24) do
          node(background: white, width: 100, border: { color: dark, width: 2 }, padding: [16, 48], gap: 12, flex: { direction: :column }, align: { items: :center }) do
            node(dark.to_border, height: 72, width: 72)
            text "End"
          end
          node(background: white, width: 100, border: { color: dark, width: 2 }, padding: [16, 48], gap: 12, flex: { direction: :column }, align: { items: :center }) do
            node(dark.to_border, height: 72, width: 72)
            text "Controls"
          end
          node(background: white, width: 100, border: { color: dark, width: 2 }, padding: [16, 48], gap: 12, flex: { direction: :column }, align: { items: :center }) do
            node(dark.to_border, height: 72, width: 72)
            text "Nodopedia"
          end
        end
      end
      node(background: accent, color: white, flex: { direction: :column }) do
        node(background: dark.merge(a: 200), padding: 12, gap: 24, justify: { content: :end }) do
          node(gap: 8) do
            node(white.to_solid, height: 24, width: 24)
            text "Close"
          end
          node(gap: 8) do
            node(white.to_solid, height: 24, width: 24)
            text "Confirm"
          end
        end
      end
    end
  end,
}
