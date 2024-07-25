$gtk.disable_nil_punning!

require "lib/input"
require "lib/ui"
require "lib/ui/layout"

def self.tick(...)
  if Kernel.tick_count.zero?
    rect = $layout.rect(row: 1, col: 10, w: 13, h: 10)
    $state.rect = rect || { top: rect.y + rect.h, left: rect.x }

    $state.tests = Examples.examples
    $state.selected_test = 0
  end

  if $inputs.keyboard.key_down.up
    $state.selected_test -= 1
  elsif $inputs.keyboard.key_down.down
    $state.selected_test += 1
  end
  $state.selected_test %= $state.tests.count
  current_test = $state.tests[$state.selected_test]

  $state.textbox ||= Input::Multiline.new(**$layout.rect(row: 1, col: 1, w: 8, h: 10), size_px: 12)

  $state.textbox.value = <<~OUTPUT
  Tests
  -----

  #{$state.tests.map { |name| "#{name == current_test ? ">" : " "} #{name}" }.join("\n")}
  OUTPUT

  $state.textbox.tick

  tree = Examples.send(current_test)
  UI::Layout.apply(tree, target: $state.rect)

  generate_screenshots if $gtk.cli_arguments.key?(:regression)

  $outputs.primitives << tree
  $outputs.primitives << $state.textbox
end

def generate_screenshots
  return unless Kernel.tick_count.pos? && Kernel.tick_count.zmod?(5)

  $outputs.screenshots << $state.rect.merge(path: "screenshots/#{$state.tests[$state.selected_test].tr(":/", "")}.png")

  $state.selected_test += 1
  $gtk.request_quit if $state.selected_test == $state.tests.count
end

module Examples
  extend self

  DARK_BACKGROUND = { r: 0x33, g: 0x33, b: 0x33 }
  LIGHT_BACKGROUND = { r: 0xEE, g: 0xEE, b: 0xEE }

  attr_reader :examples
  @examples = []
  def self.example(name, &block)
    @examples << name
    self.define_method(name, &block)
  end

  example "flex-direction: row" do
    UI.build(align: :stretch) do
      node(background: DARK_BACKGROUND, flex: { direction: :row }) do
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "1" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "2" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "3" }
      end
    end
  end

  example "flex-direction: row-reverse" do
    UI.build(align: :stretch) do
      node(background: DARK_BACKGROUND, flex: { direction: :row_reverse }) do
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "1" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "2" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "3" }
      end
    end
  end

  example "flex-direction: column" do
    UI.build(align: :stretch) do
      node(background: DARK_BACKGROUND, flex: { direction: :column }) do
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "1" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "2" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "3" }
      end
    end
  end

  example "flex-direction: column-reverse" do
    UI.build(align: :stretch) do
      node(background: DARK_BACKGROUND, flex: { direction: :column_reverse }) do
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "1" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "2" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "3" }
      end
    end
  end

  example "flex-direction: column-reverse swaps main start and end" do
    UI.build(flex: { direction: :row }) do
      node(background: DARK_BACKGROUND, flex: { direction: :column }) do
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "1" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "2" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "3" }
      end
      node(background: {r:200}, flex: { direction: :column_reverse }) do
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "3" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "2" }
        node(width: 50, height: 50, background: LIGHT_BACKGROUND, margin: 20, align: :center, justify: :center) { text "1" }
      end
    end
  end
end
