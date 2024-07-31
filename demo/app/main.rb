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
  current_test = $state.tests.keys[$state.selected_test]

  $state.textbox ||= Input::Multiline.new(**$layout.rect(row: 1, col: 1, w: 8, h: 10), size_px: 12)

  $state.textbox.value = <<~OUTPUT
  #{$state.tests[current_test]}

  Tests
  -----

  #{$state.tests.keys.map { |name| "#{name == current_test ? ">" : " "} #{name}" }.join("\n")}
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

  $outputs.screenshots << $state.rect.merge(path: "screenshots/#{$state.tests.keys[$state.selected_test]}.png")

  $state.selected_test += 1
  $gtk.request_quit if $state.selected_test == $state.tests.count
end

# @NOTE These examples have been adapted from the CSS Flexbox Test Suite.
# @SEE https://test.csswg.org/suites/css-flexbox-1_dev/nightly-unstable/html/reftest-toc.htm
module Examples
  extend self

  DARK_BACKGROUND = { r: 0x33, g: 0x33, b: 0x33 }
  LIGHT_BACKGROUND = { r: 0xEE, g: 0xEE, b: 0xEE }

  attr_reader :examples
  @examples = {}
  def self.example(name, message, &block)
    @examples[name] = message
    self.define_method(name, &block)
  end

  example "align-content-001", "align: { content: :center } groups all wrapping lines in the middle of their container" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :center }) do
        node(width: 150, height: 25, background: {r:200})
        node(width: 150, height: 25, background: {g:200})
        node(width: 150, height: 25, background: {b:200})
        node(width: 150, height: 25, background: {r:200, g:200})
      end
    end
  end

  example "align-content-002", "align: { content: :start } groups all wrapping lines at the start of their container" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :start }) do
        node(width: 150, height: 25, background: {r:200})
        node(width: 150, height: 25, background: {g:200})
        node(width: 150, height: 25, background: {b:200})
        node(width: 150, height: 25, background: {r:200, g:200})
      end
    end
  end

  example "align-content-003", "align: { content: :end } groups all wrapping lines at the end of their container" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :end }) do
        node(width: 150, height: 25, background: {r:200})
        node(width: 150, height: 25, background: {g:200})
        node(width: 150, height: 25, background: {b:200})
        node(width: 150, height: 25, background: {r:200, g:200})
      end
    end
  end

  example "align-content-004", "align: { content: :space_between } ensures that wrapping lines are maximally distant from one another" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :space_between }) do
        node(width: 150, height: 25, background: {r:200})
        node(width: 150, height: 25, background: {g:200})
        node(width: 150, height: 25, background: {b:200})
        node(width: 150, height: 25, background: {r:200, g:200})
      end
    end
  end

  example "align-content-005", "align: { content: :space_around } ensures that wrapping lines' edges each receive an equal portion of empty space" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :space_around }) do
        node(width: 150, height: 22, background: {r:200})
        node(width: 150, height: 22, background: {g:200})
        node(width: 150, height: 22, background: {b:200})
        node(width: 150, height: 22, background: {r:200, g:200})
      end
    end
  end

  example "align-content-006", "align: { content: :stretch } stretches lines to fill their container" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :stretch }) do
        node(width: 150, background: {r:200})
        node(width: 150, background: {g:200})
        node(width: 150, background: {b:200})
        node(width: 150, background: {r:200, g:200})
      end
    end
  end

  # @NOTE Not a formal test provided in the suite, but useful for debugging.
  example "align-content-007x", "align: { content: :space_evenly } ensures that wrapping lines are evenly distributed within the space" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :space_evenly }) do
        node(width: 150, height: 22, background: {r:200})
        node(width: 150, height: 22, background: {g:200})
        node(width: 150, height: 22, background: {b:200})
        node(width: 150, height: 22, background: {r:200, g:200})
      end
    end
  end

  example "align-content-horiz-001a", "testing 1-3 flex lines within horizontal flex containers with each possible value of the 'align-content' property" do
    container = {
      width: 20,
      height: 200,
      flex: { wrap: true },
      margin: { right: 2 },
      background: { r: 200, g: 200, b: 200 },
    }

    child_a = { width: 20, height: 10, background: { r: 200 } }
    child_b = { width: 20, background: { g: 200 } }
    grandchild = { width: 10, height: 30, background: { r: 200, b: 200 }}
    child_c = { width: 20, height: 40, background: { b: 200 } }

    alignments = [
      nil,
      :flex_start,
      :flex_end,
      :center,
      :space_between,
      :space_around,
      :space_evenly,
      :start,
      :end,
    ]

    UI.build do
      alignments.each do |alignment|
        node(**container, align: { content: alignment }) do
          node(**child_a)
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
          node(**child_c)
        end
      end
    end
  end

  # # @FIXME `max_width` support.
  # example "align-content-horiz-001b", "testing 1-3 flex lines within horizontal flex containers with each possible value of the 'align-content' property and no explicit width" do
  #   container = {
  #     max_width: 20,
  #     height: 200,
  #     flex: { wrap: true },
  #     margin: { right: 2 },
  #     background: { r: 200, g: 200, b: 200 },
  #   }

  #   child_a = { width: 20, height: 10, background: { r: 200 } }
  #   child_b = { width: 20, background: { g: 200 } }
  #   grandchild = { width: 10, height: 30, background: { r: 200, b: 200 }}
  #   child_c = { width: 20, height: 40, background: { b: 200 } }

  #   alignments = [
  #     nil,
  #     :flex_start,
  #     :flex_end,
  #     :center,
  #     :space_between,
  #     :space_around,
  #     :space_evenly,
  #     :start,
  #     :end,
  #   ]

  #   UI.build do
  #     alignments.each do |alignment|
  #       node(**container, align: { content: alignment }) do
  #         node(**child_a)
  #       end
  #       node(**container, align: { content: alignment }) do
  #         node(**child_a)
  #         node(**child_b) { node(**grandchild) }
  #       end
  #       node(**container, align: { content: alignment }) do
  #         node(**child_a)
  #         node(**child_b) { node(**grandchild) }
  #         node(**child_c)
  #       end
  #     end
  #   end
  # end

  example "align-content-horiz-002", "testing 1-3 flex lines within horizontal { wrap: :reverse } flex containers with each possible value of the 'align-content' property" do
    container = {
      width: 20,
      height: 200,
      flex: { wrap: :reverse },
      margin: { right: 2 },
      background: { r: 200, g: 200, b: 200 },
    }

    child_a = { width: 20, height: 10, background: { r: 200 } }
    child_b = { width: 20, background: { g: 200 } }
    grandchild = { width: 10, height: 30, background: { r: 200, b: 200 }}
    child_c = { width: 20, height: 40, background: { b: 200 } }

    alignments = [
      nil,
      :flex_start,
      :flex_end,
      :center,
      :space_between,
      :space_around,
      :space_evenly,
      :start,
      :end,
    ]

    UI.build do
      alignments.each do |alignment|
        node(**container, align: { content: alignment }) do
          node(**child_a)
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
          node(**child_c)
        end
      end
    end
  end

  example "align-content-vert-001a", "testing 1-3 flex lines within vertical flex containers with each possible value of the 'align-content' property" do
    container = {
      width: 200,
      height: 10,
      flex: { direction: :column, wrap: true },
      margin: { bottom: 2 },
      background: { r: 200, g: 200, b: 200 },
    }

    child_a = { width: 10, height: 10, background: { r: 200 } }
    child_b = { height: 10, background: { g: 200 } }
    grandchild = { width: 30, height: 5, background: { r: 200, b: 200 }}
    child_c = { width: 40, height: 10, background: { b: 200 } }

    alignments = [
      nil,
      :flex_start,
      :flex_end,
      :center,
      :space_between,
      :space_around,
      :space_evenly,
      :start,
      :end,
    ]

    UI.build(flex: { direction: :column }) do
      alignments.each do |alignment|
        node(**container, align: { content: alignment }) do
          node(**child_a)
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
          node(**child_c)
        end
      end
    end
  end

  # # @FIXME `max_height` support.
  # example "align-content-vert-001b", "testing 1-3 flex lines within vertical flex containers with each possible value of the 'align-content' property and no explicit height" do
  #   container = {
  #     width: 200,
  #     max_height: 10,
  #     flex: { direction: :column, wrap: true },
  #     margin: { bottom: 2 },
  #     background: { r: 200, g: 200, b: 200 },
  #   }

  #   child_a = { width: 10, height: 10, background: { r: 200 } }
  #   child_b = { height: 10, background: { g: 200 } }
  #   grandchild = { width: 30, height: 5, background: { r: 200, b: 200 }}
  #   child_c = { width: 40, height: 10, background: { b: 200 } }

  #   alignments = [
  #     nil,
  #     :flex_start,
  #     :flex_end,
  #     :center,
  #     :space_between,
  #     :space_around,
  #     :space_evenly,
  #     :start,
  #     :end,
  #   ]

  #   UI.build(flex: { direction: :column }) do
  #     alignments.each do |alignment|
  #       node(**container, align: { content: alignment }) do
  #         node(**child_a)
  #       end
  #       node(**container, align: { content: alignment }) do
  #         node(**child_a)
  #         node(**child_b) { node(**grandchild) }
  #       end
  #       node(**container, align: { content: alignment }) do
  #         node(**child_a)
  #         node(**child_b) { node(**grandchild) }
  #         node(**child_c)
  #       end
  #     end
  #   end
  # end

  example "align-content-vert-002", "testing 1-3 flex lines within vertical { wrap: :reverse } flex containers with each possible value of the 'align-content' property" do
    container = {
      width: 200,
      height: 10,
      flex: { direction: :column, wrap: :reverse },
      margin: { bottom: 2 },
      background: { r: 200, g: 200, b: 200 },
    }

    child_a = { width: 10, height: 10, background: { r: 200 } }
    child_b = { height: 10, background: { g: 200 } }
    grandchild = { width: 30, height: 5, background: { r: 200, b: 200 }}
    child_c = { width: 40, height: 10, background: { b: 200 } }

    alignments = [
      nil,
      :flex_start,
      :flex_end,
      :center,
      :space_between,
      :space_around,
      :space_evenly,
      :start,
      :end,
    ]

    UI.build(flex: { direction: :column }) do
      alignments.each do |alignment|
        node(**container, align: { content: alignment }) do
          node(**child_a)
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
        end
        node(**container, align: { content: alignment }) do
          node(**child_a)
          node(**child_b) { node(**grandchild) }
          node(**child_c)
        end
      end
    end
  end

  example "align-content_center", "renders three contiguous boxes in the middle left of their container" do
    UI.build do
      node(height: 200, width: 80, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :center }) do
        node(width: 50, height: 50, background: {r:200})
        node(width: 50, height: 50, background: {g:200})
        node(width: 50, height: 50, background: {b:200})
      end
    end
  end

  example "align-content_flex-end", "renders three contiguous boxes in the bottom left of their container" do
    UI.build do
      node(height: 200, width: 80, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :flex_end }) do
        node(width: 50, height: 50, background: {r:200})
        node(width: 50, height: 50, background: {g:200})
        node(width: 50, height: 50, background: {b:200})
      end
    end
  end

  example "align-content_flex-start", "renders three contiguous boxes in the upper left of their container" do
    UI.build do
      node(height: 200, width: 80, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :flex_start }) do
        node(width: 50, height: 50, background: {r:200})
        node(width: 50, height: 50, background: {g:200})
        node(width: 50, height: 50, background: {b:200})
      end
    end
  end

  example "align-content_space-around", "renders three boxes and the gap between the boxes and the container edge is half the size of the gap between boxes" do
    UI.build do
      node(height: 200, width: 80, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :space_around }) do
        node(width: 50, height: 50, background: {r:200})
        node(width: 50, height: 50, background: {g:200})
        node(width: 50, height: 50, background: {b:200})
      end
    end
  end

  example "align-content_space-between", "renders three boxes with no gap between the boxes and the container edge and equally sized gaps between boxes" do
    UI.build do
      node(height: 200, width: 80, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :space_between }) do
        node(width: 50, height: 50, background: {r:200})
        node(width: 50, height: 50, background: {g:200})
        node(width: 50, height: 50, background: {b:200})
      end
    end
  end

  example "align-content_stretch", "renders three boxes with no gap between the first box and the container edge and equal gaps after each box" do
    UI.build do
      node(height: 200, width: 80, background: DARK_BACKGROUND, flex: { wrap: true }, align: { content: :stretch }) do
        node(width: 50, height: 50, background: {r:200})
        node(width: 50, height: 50, background: {g:200})
        node(width: 50, height: 50, background: {b:200})
      end
    end
  end

  example "align-items-001", "align: { items: :center } centers each flex item's margin box in the cross-axis of its line" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { items: :center }) do
        node(width: 150, height: 50, background: {r:200})
        node(width: 150, height: 50, background: {g:200})
      end
    end
  end

  example "align-items-002", "align: { items: :flex_start } centers each flex item's margin box flush with the cross-start edge of line" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { items: :flex_start }) do
        node(width: 150, height: 50, background: {r:200})
        node(width: 150, height: 50, background: {g:200})
      end
    end
  end

  example "align-items-003", "align: { items: :flex_end } centers each flex item's margin box flush with the cross-end edge of line" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { items: :flex_end }) do
        node(width: 150, height: 50, background: {r:200})
        node(width: 150, height: 50, background: {g:200})
      end
    end
  end

  # @SKIPPED align-items-004
  # @REASON No support for `baseline` alignment is planned.

  example "align-items-005", "align: { items: :stretch } centers each flex item's margin box so that its cross size matches its line's" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { wrap: true }, align: { items: :stretch }) do
        node(width: 150, background: {r:200})
        node(width: 150, background: {g:200})
      end
    end
  end

  example "align-items-006", "align: { items: :flex_start } implies the flex item's width should fit to its content" do
    UI.build do
      node(height: 100, width: 300, background: DARK_BACKGROUND, flex: { direction: :column }, align: { items: :flex_start }) do
        node(background: {r:200}) do
          node(width: 150, height: 50, background: {g:200}, flex: { direction: :column }) do
            text "No red showing"
          end
        end
      end
    end
  end

  example "align-self-001", "align: { self: :flex_start } aligns the flex items to the start edge of cross axis" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND) do
        node(width: 25, height: 50, align: { self: :flex_start }, background: {r:200})
        node(width: 25, height: 50, align: { self: :flex_start }, background: {g:200})
        node(width: 25, height: 50, align: { self: :flex_start }, background: {b:200})
        node(width: 25, height: 50, align: { self: :flex_start }, background: {r:200, g:200})
      end
    end
  end

  example "align-self-002", "align: { self: :flex_end } aligns the flex items to the end edge of cross axis" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND) do
        node(width: 25, height: 50, align: { self: :flex_end }, background: {r:200})
        node(width: 25, height: 50, align: { self: :flex_end }, background: {g:200})
        node(width: 25, height: 50, align: { self: :flex_end }, background: {b:200})
        node(width: 25, height: 50, align: { self: :flex_end }, background: {r:200, g:200})
      end
    end
  end

  example "align-self-003", "align: { self: :center } aligns the flex items to the center of cross axis" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND) do
        node(width: 25, height: 50, align: { self: :center }, background: {r:200})
        node(width: 25, height: 50, align: { self: :center }, background: {g:200})
        node(width: 25, height: 50, align: { self: :center }, background: {b:200})
        node(width: 25, height: 50, align: { self: :center }, background: {r:200, g:200})
      end
    end
  end

  example "align-self-004", "align: { self: :stretch } makes the flex items fill the cross axis" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND) do
        node(width: 25, align: { self: :stretch }, background: {r:200})
        node(width: 25, align: { self: :stretch }, background: {g:200})
        node(width: 25, align: { self: :stretch }, background: {b:200})
        node(width: 25, align: { self: :stretch }, background: {r:200, g:200})
      end
    end
  end

  example "align-self-005", "align: { self: :stretch } does not stretch items with an exact cross axis size" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND) do
        node(width: 25, height: 50, align: { self: :stretch }, background: {r:200})
        node(width: 25, height: 50, align: { self: :stretch }, background: {g:200})
        node(width: 25, height: 50, align: { self: :stretch }, background: {b:200})
        node(width: 25, height: 50, align: { self: :stretch }, background: {r:200, g:200})
      end
    end
  end

  # @SKIPPED align-self-006
  # @REASON No support for `baseline` alignment is planned.

  example "align-self-007", "align: { self: nil } aligns flex items to the start edge of the cross-axis when the parent is set to align: { items: :flex-start }" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND, align: { items: :flex_start }) do
        node(width: 25, height: 50, align: { self: nil }, background: {r:200})
        node(width: 25, height: 50, align: { self: nil }, background: {g:200})
        node(width: 25, height: 50, align: { self: nil }, background: {b:200})
        node(width: 25, height: 50, align: { self: nil }, background: {r:200, g:200})
      end
    end
  end

  example "align-self-008", "align: { self: nil } aligns flex items to the end edge of the cross-axis when the parent is set to align: { items: :flex-end }" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND, align: { items: :flex_end }) do
        node(width: 25, height: 50, align: { self: nil }, background: {r:200})
        node(width: 25, height: 50, align: { self: nil }, background: {g:200})
        node(width: 25, height: 50, align: { self: nil }, background: {b:200})
        node(width: 25, height: 50, align: { self: nil }, background: {r:200, g:200})
      end
    end
  end

  example "align-self-009", "align: { self: nil } aligns flex items to the center of the cross-axis when the parent is set to align: { items: :center }" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND, align: { items: :center }) do
        node(width: 25, height: 50, align: { self: nil }, background: {r:200})
        node(width: 25, height: 50, align: { self: nil }, background: {g:200})
        node(width: 25, height: 50, align: { self: nil }, background: {b:200})
        node(width: 25, height: 50, align: { self: nil }, background: {r:200, g:200})
      end
    end
  end

  # @SKIPPED align-self-010
  # @REASON No support for `baseline` alignment is planned.

  example "align-self-011", "align: { self: nil } stretches the items across the cross-axis when the parent is set to align: { items: :stretch }" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND, align: { items: :stretch }) do
        node(width: 25, align: { self: nil }, background: {r:200})
        node(width: 25, align: { self: nil }, background: {g:200})
        node(width: 25, align: { self: nil }, background: {b:200})
        node(width: 25, align: { self: nil }, background: {r:200, g:200})
      end
    end
  end

  example "align-self-012", "not setting align: { :self } stretches the items across the cross-axis when the parent is set to align: { items: :stretch }" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND, align: { items: :stretch }) do
        node(width: 25, background: {r:200})
        node(width: 25, background: {g:200})
        node(width: 25, background: {b:200})
        node(width: 25, background: {r:200, g:200})
      end
    end
  end

  example "align-self-013", "align: { :self } applies to children of a flex container" do
    UI.build do
      node(height: 100, width: 100, background: DARK_BACKGROUND, align: { items: :flex_start, self: :flex_end }) do
        node(width: 25, height: 50, background: {r:200})
        node(width: 25, height: 50, background: {g:200})
        node(width: 25, height: 50, background: {b:200})
        node(width: 25, height: 50, background: {r:200, g:200})
      end
    end
  end

  example "auto-height-column-with-border-and-padding", "Tests that auto-height column flexboxes with border and padding correctly size their height to their content." do
    UI.build(flex: { direction: :column }) do
      node(border: { width: 5, color: :salmon }, padding: 5, flex: { direction: :column }) do
        node(min_height: 10, flex: { grow: 1 }) do
          # @NOTE The `width` here works around an assumption in the source test
          #       that nodes are implicitly 100% the width of their container.
          node(width: 50, height: 50, background: :pink)
        end
      end
    end
  end
end
