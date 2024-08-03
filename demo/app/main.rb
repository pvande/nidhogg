$gtk.disable_nil_punning!

require "lib/input"
require "lib/ui"

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

  $outputs.screenshots << $state.rect.merge(path: "screenshots/#{$state.tests.keys[$state.selected_test]}.png", r: 1)

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

  # @SKIPPED abspos-autopos-htb-ltr
	# @SKIPPED abspos-autopos-htb-rtl
	# @SKIPPED abspos-autopos-vlr-ltr
	# @SKIPPED abspos-autopos-vlr-rtl
	# @SKIPPED abspos-autopos-vrl-ltr
	# @SKIPPED abspos-autopos-vrl-rtl
  # @REASON No support for writing direction is planned.

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

  # @SKIPPED auto-height-with-flex
  # @REASON We don't implement a shorthand `flex` property.

  # @SKIPPED calc-rounds-to-integer
  # @REASON We don't support CSS `calc()`.

  example "column-flex-child-with-overflow-scroll", "This test ensures children of flexbox with flex-direction: column|column-reverse does not shrink their height after applying the overflow: scroll style." do
    UI.build(gap: 10) do
      node(flex: { direction: :column }) do
        node(width: 100, height: 75, border: { width: 2, color: :red }, padding: 5)
        node(width: 100, height: 75, border: { width: 2, color: :red }, padding: 5, overflow: :scroll)
      end
      node(flex: { direction: :column_reverse }) do
        node(width: 100, height: 75, border: { width: 2, color: :red }, padding: 5, overflow: :scroll)
        node(width: 100, height: 75, border: { width: 2, color: :red }, padding: 5)
      end
    end
  end

  # @SKIPPED columns-height-set-via-top-bottom
  # @REASON No support for positioning.

  # @SKIPPED contain-layout-baseline-002
  # @SKIPPED contain-layout-suppress-baseline-001
  # @SKIPPED contain-layout-suppress-baseline-002
  # @REASON No support for `baseline` alignment is planned.

  # @SKIPPED content-height-with-scrollbars
  # @SKIPPED cross-axis-scrollbar
  # @REASON No support for scrollbars.

  example "css-box-justify-content", "This test passes if the black box's position is at the end" do
    UI.build do
      node(width: 300, height: 40, background: :green, justify: { content: :flex_end }) do
        node(width: 50, height: 30, background: :white)
        text " "
        node(width: 50, height: 30, background: :lightgrey)
        text " "
        node(width: 50, height: 30, background: :darkgrey)
        text " "
        node(width: 50, height: 30, background: :grey)
        text " "
        node(width: 50, height: 30, background: :black)
      end
    end
  end

  example "css-flexbox-height-animation-stretch", "The test passes if you keep seeing a green rectangle and no red." do
    UI.build(flex: { direction: :column }) do
      node(width: 200, background: :red) do
        node(width: 50, background: :blue) { node(height: 75 + Math.sin(Kernel.tick_count / 20).mult(25).round) }
        node(width: 50, background: :green) { node(height: 50) }
        node(width: 50, background: :yellow) { node(height: 50) }
        node(width: 50, background: :purple) { node(height: 50) }
      end
    end
  end

  example "css-flexbox-img-expand-evenly", "3 rectangular images fill out border" do
    UI.build do
      node(width: 300, height: 50, border: 2) do
        node({ path: "solidblue.png" }, width: 48, grow: 1, border: :white)
        node({ path: "solidblue.png" }, width: 48, grow: 1, border: :white)
        node({ path: "solidblue.png" }, width: 48, grow: 1, border: :white)
      end
    end
  end

  # @SKIPPED css-flexbox-row-reverse-wrap-reverse
  # @SKIPPED css-flexbox-row-reverse-wrap
  # @SKIPPED css-flexbox-row-reverse
  # @SKIPPED css-flexbox-row-wrap-reverse
  # @SKIPPED css-flexbox-row-wrap
  # @SKIPPED css-flexbox-row
  # @SKIPPED css-flexbox-test1
  # @REASON No support for writing direction.

  # @SKIPPED direction-upright-002
  # @SKIPPED display-flex-001
  # @SKIPPED display_flex_exist
  # @SKIPPED display_inline-flex_exist
  # @SKIPPED dynamic-baseline-change-nested
  # @SKIPPED dynamic-baseline-change
  # @SKIPPED flex-001
  # @SKIPPED flex-002
  # @SKIPPED flex-003
  # @SKIPPED flex-004
  # @SKIPPED flex-align-content-center
  # @SKIPPED flex-align-content-end
  # @SKIPPED flex-align-content-space-around
  # @SKIPPED flex-align-content-space-between
  # @SKIPPED flex-align-content-start
  # @SKIPPED flex-aspect-ratio-019
  # @SKIPPED flex-aspect-ratio-020
  # @SKIPPED flex-aspect-ratio-021
  # @SKIPPED flex-aspect-ratio-022
  # @SKIPPED flex-aspect-ratio-023
  # @SKIPPED flex-aspect-ratio-024
  # @SKIPPED flex-aspect-ratio-img-column-001
  # @SKIPPED flex-aspect-ratio-img-column-002
  # @SKIPPED flex-aspect-ratio-img-column-003
  # @SKIPPED flex-aspect-ratio-img-column-016
  # @SKIPPED flex-aspect-ratio-img-row-001
  # @SKIPPED flex-aspect-ratio-img-row-002
  # @SKIPPED flex-aspect-ratio-img-row-003
  # @SKIPPED flex-aspect-ratio-img-row-012
  # @SKIPPED flex-aspect-ratio-img-row-014
  # @SKIPPED flex-base
  # @SKIPPED flex-basis-001
  # @SKIPPED flex-basis-002
  # @SKIPPED flex-basis-003
  # @SKIPPED flex-basis-004
  # @SKIPPED flex-basis-005
  # @SKIPPED flex-basis-006
  # @SKIPPED flex-basis-007
  # @SKIPPED flex-basis-008
  # @SKIPPED flex-basis-009
  # @SKIPPED flex-basis-010
  # @SKIPPED flex-basis-011
  # @SKIPPED flex-basis-composition
  # @SKIPPED flex-basis-interpolation
  # @SKIPPED flex-box-wrap
  # @SKIPPED flex-column-relayout-assert
  # @SKIPPED flex-container-margin
  # @SKIPPED flex-direction-column-001-visual
  # @SKIPPED flex-direction-column-reverse-001-visual
  # @SKIPPED flex-direction-column-reverse-002-visual
  # @SKIPPED flex-direction-column-reverse
  # @SKIPPED flex-direction-column
  # @SKIPPED flex-direction-modify
  # @SKIPPED flex-direction-row-001-visual
  # @SKIPPED flex-direction-row-002-visual
  # @SKIPPED flex-direction-row-reverse-001-visual
  # @SKIPPED flex-direction-row-reverse-002-visual
  # @SKIPPED flex-direction-row-reverse
  # @SKIPPED flex-direction-row-vertical
  # @SKIPPED flex-direction-with-element-insert
  # @SKIPPED flex-direction
  # @SKIPPED flex-factor-less-than-one
  # @SKIPPED flex-flexitem-childmargin
  # @SKIPPED flex-flexitem-percentage-prescation
  # @SKIPPED flex-flow-001
  # @SKIPPED flex-flow-002
  # @SKIPPED flex-flow-003
  # @SKIPPED flex-flow-004
  # @SKIPPED flex-flow-005
  # @SKIPPED flex-flow-006
  # @SKIPPED flex-flow-007
  # @SKIPPED flex-flow-008
  # @SKIPPED flex-flow-009
  # @SKIPPED flex-flow-010
  # @SKIPPED flex-flow-011
  # @SKIPPED flex-flow-012
  # @SKIPPED flex-flow-013
  # @REASON Time.

  example "flex-grow-001", "'grow' property specifies the flex grow factor" do
    UI.build do
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 30, height: 60, grow: 0, background: {r:200})
        node(width: 30, height: 60, grow: 1, background: {g:200})
        node(width: 30, height: 60, grow: 2, background: {b:200})
      end
    end
  end

  example "flex-grow-002", "'grow' defaults to '0', which retains main-axis size" do
    UI.build do
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 30, height: 60, grow: 1, background: {r:200})
        node(width: 30, height: 60, grow: 0, background: {g:200})
        node(width: 30, height: 60, background: {b:200})
      end
    end
  end

  example "flex-grow-003", "negative 'grow' values are treated as invalid" do
    UI.build do
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 30, height: 60, grow: -1, background: {r:200})
        node(width: 30, height: 60, grow: -2, background: {g:200})
        node(width: 30, height: 60, grow: -3, background: {b:200})
      end
    end
  end

  example "flex-grow-004", "'grow' values have no effect when no empty space exists" do
    UI.build do
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 120, height: 60, grow: 3, background: {r:200})
        node(width: 120, height: 60, grow: 2, background: {g:200})
      end
    end
  end

  # @SKIPPED flex-grow-005
  # @REASON All nodes are considered flex containers.

  example "flex-grow-006", "all space will be taken up by a single flex item with any positive 'grow' value" do
    UI.build(flex: { direction: :column }) do
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 120, height: 60, grow: 1.5, background: {r:200})
      end
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 120, height: 60, grow: 2, background: {g:200})
      end
    end
  end

  example "flex-grow-007", "remaining space is calculated for positive 'grow' values less than one" do
    UI.build(flex: { direction: :column }) do
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 120, height: 60, grow: 0.1, background: {r:200})
      end
      node(width: 240, height: 60, background: DARK_BACKGROUND) do
        node(width: 120, height: 60, grow: 0.05, background: {g:200})
        node(width: 120, height: 60, grow: 0.05, background: {b:200})
      end
    end
  end

  example "flex-shrink-001", ":shrink determines how much the flex item will shrink relative to the others when negative free space is distributed" do
    UI.build do
      node(width: 100, height: 100, background: DARK_BACKGROUND) do
        node(width: 100, height: 80, shrink: 2, background: {r:200})
        node(width: 100, height: 80, shrink: 3, background: {g:200})
      end
    end
  end

  example "flex-shrink-002", ":shrink is invalid when set to a negative number" do
    UI.build do
      node(width: 100, height: 100, background: DARK_BACKGROUND) do
        node(width: 100, height: 80, shrink: -2, background: {r:200})
        node(width: 100, height: 80, shrink: -3, background: {g:200})
      end
    end
  end

  example "flex-shrink-003", ":shrink is initially '1'" do
    UI.build(flex: { direction: :column }) do
      node(width: 100, height: 80, background: DARK_BACKGROUND) do
        node(width: 100, height: 80, background: {r:200})
        node(width: 100, height: 80, shrink: 4, background: {g:200})
      end
      node(width: 100, height: 20, background: DARK_BACKGROUND) do
        node(width: 80, height: 20, background: {r:100})
        node(width: 20, height: 20, shrink: 4, background: {g:100})
      end
    end
  end

  example "flex-shrink-004", ":shrink has no effect if there's adequate space for children" do
    UI.build() do
      node(width: 100, height: 100, background: DARK_BACKGROUND) do
        node(width: 40, height: 80, shrink: 2, background: {r:200})
        node(width: 40, height: 80, shrink: 3, background: {g:200})
      end
    end
  end

  example "flex-shrink-005", ":shrink will prevent resizing when set to '0'" do
    UI.build() do
      node(width: 50, height: 100, background: DARK_BACKGROUND) do
        node(width: 50, height: 80, shrink: 0, background: {r:200})
        node(width: 50, height: 80, shrink: 0, background: {g:200})
      end
    end
  end

  # @SKIPPING flex-shrink-006
  # @REASON We don't yet properly resolve flex sizes iteratively.

  # @SKIPPED flex-shrink-007
  # @REASON All nodes are considered flex containers.

  example "flex-shrink-008", "remaining space is calculated for positive 'shrink' values less than one" do
    UI.build(flex: { direction: :column }) do
      node(width: 100, height: 50, background: DARK_BACKGROUND) do
        node(width: 120, height: 50, grow: 0.9, background: {r:200})
      end
      node(width: 100, height: 50, background: DARK_BACKGROUND) do
        node(width: 120, height: 50, grow: 0.25, background: {g:200})
        node(width: 120, height: 50, grow: 0.25, background: {b:200})
      end
    end
  end
end
