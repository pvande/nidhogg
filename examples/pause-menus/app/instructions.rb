MENUS[0] = {
  gui: UI.build(background: :white, padding: { top: 30 }, flex: { direction: :column }) do
    node(flex: { direction: :column }, align: { self: :center, items: :start }) do
      text "This application represents a functional demonstration of how this UI toolkit"
      text "can be used to layout production-quality pause menus for video games."
      text ""
      text "To that end, a selection of interesting menus from gameuidatabase.com have been"
      text "modeled and layed out. These have been implemented with varying degrees of"
      text "graphical fidelity, since the intention is to showcase the layout toolkit."
      text "Feel free to use these as a starting point for your own work."
      text ""
      text "You can move through the examples with the left and right arrow keys,"
      text "and the source code can be found under `examples/pause-menus/samples`."
    end
  end,
}
