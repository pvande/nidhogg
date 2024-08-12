$gtk.disable_nil_punning!

require "lib/ui"

MENUS = []
require_relative "instructions"
require "samples/mini_motorways_pc"
require "samples/mini_motorways_switch"
require "samples/carto"
require "samples/mirrors_edge"
require "samples/game_builder_garage"

def self.init
  $state.menu = 0
end

def self.tick(...)
  init if Kernel.tick_count.zero?

  if $inputs.keyboard.key_down.left
    $state.menu -= 1
  elsif $inputs.keyboard.key_down.right
    $state.menu += 1
  end
  $state.menu = $state.menu.clamp_wrap(0, MENUS.length - 1)

  $outputs.primitives << $grid.rect.merge(path: "images/screenshot.png")

  menu = MENUS[$state.menu]
  UI::Layout.apply(menu.gui, target: $grid.rect)

  $outputs.primitives << menu.gui
  menu[:tick]&.call
end
