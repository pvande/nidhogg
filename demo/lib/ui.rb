module UI
  def self.build(rect = nil, **style, &block)
    root = Node.new(rect, **style)

    builder = Builder.new(root)
    builder.instance_eval(&block) if block_given?

    return root
  end

  class Builder
    def initialize(root)
      @root = root
      @stack = [root]
    end

    def node(rect = nil, id: nil, **style, &block)
      node = Node.new(rect, id: id, parent: @stack.last, **style)
      @stack << node
      instance_eval(&block) if block
    ensure
      @stack.pop
    end

    def text(text = "", **style)
      label = TextNode.new(text, parent: @stack.last, **style)
    end
  end

  class Node
    attr_reader :parent
    attr_reader :rect, :id, :style, :children
    attr_reader :internal

    def initialize(rect, id: nil, parent: nil, **style)
      @id = id&.to_sym
      @parent = parent
      @parent.children << self if parent

      @rect = rect
      @style = style

      @children = []
      @internal = {}

      @descendent_index = {}
      @descendent_index[@id] = self if @id
    end

    # Look up descendant nodes by `id`. If multiple nodes with the same ID are
    # present in the tree, only the first matching node (in-order, depth-first)
    # is returned.
    #
    # @param id [#to_sym] The ID of the node to look up.
    # @return [Node, nil] The first node with the given ID, if present.
    def [](id)
      id = id.to_sym

      @descendent_index.fetch(id) do
        node = @children.find { |child| child[id] if child.is_a?(Node) }
        @descendent_index[id] = node && node[id]
      end
    end

    def inspect
      if @children.empty?
        <<~XML
          <!-- #{internal.inspect} -->
          <node #{@id} style=#{@style.inspect} />
        XML
      else
        <<~XML
          <!-- #{internal.inspect} -->
          <node #{@id} style=#{@style.inspect}>
          #{@children.map(&:inspect).join.indent(1)}</node>
        XML
      end
    end

    def x()= internal.screen_x
    def y()= internal.screen_y
    def w()= internal.screen_width
    def h()= internal.screen_height

    def draw_override(ffi)
      if style.background
        color = style.background
        color = UI::Colors[color] if color.is_a?(Symbol)

        $gtk.draw_solid({ x: x, y: y, w: w, h: h, **(color || {}) })
      end

      border_w = internal.dig(:border, :width) || 0
      if border_w > 0
        color = internal.dig(:border, :color)
        color = UI::Colors[color] if color.is_a?(Symbol)
        color ||= {}

        case border_w
        when 1
          $gtk.draw_border({ x: x, y: y, w: w, h: h, **color })
        else
          $gtk.draw_solid({ x: x, y: y, w: w - border_w, h: border_w, **color })
          $gtk.draw_solid({ x: x + w - border_w, y: y, w: border_w, h: h - border_w, **color })
          $gtk.draw_solid({ x: x + border_w, y: y + h - border_w, w: w - border_w, h: border_w, **color })
          $gtk.draw_solid({ x: x, y: y + border_w, w: border_w, h: h - border_w, **color })
        end
      end

      if @rect
        @rect.x = self.x
        @rect.y = self.y
        @rect.w = self.w
        @rect.h = self.h

        $gtk.draw_primitive(rect)
      end

      Array.each(@children) { |child| child.draw_override(ffi) }
    end
  end

  class TextNode
    attr_reader :parent
    attr_reader :text, :style
    attr_reader :internal

    def initialize(text, parent: nil, **style)
      @parent = parent
      @parent.children << self

      @text = text
      @style = style
      @internal = {}
    end

    def inspect
      "<!-- #{@internal.inspect} -->\n#{@text.inspect}\n"
    end

    def draw_override(ffi)
      color = @internal.color
      color = UI::Colors[color] if color.is_a?(Symbol)
      color ||= {}

      $gtk.draw_label({
        x: @internal.screen_x,
        y: @internal.screen_y,
        text: @text,
        **@internal.typeface,
        **color,
        vertical_alignment_enum: 0,
      })
    end
  end

  module Colors
    NAMED_COLORS = {
      aliceblue: { r: 240, g: 248, b: 255 }.freeze,
      antiquewhite: { r: 250, g: 235, b: 215 }.freeze,
      aqua: { r: 0, g: 255, b: 255 }.freeze,
      aquamarine: { r: 127, g: 255, b: 212 }.freeze,
      azure: { r: 240, g: 255, b: 255 }.freeze,
      beige: { r: 245, g: 245, b: 220 }.freeze,
      bisque: { r: 255, g: 228, b: 196 }.freeze,
      black: { r: 0, g: 0, b: 0 }.freeze,
      blanchedalmond: { r: 255, g: 235, b: 205 }.freeze,
      blue: { r: 0, g: 0, b: 255 }.freeze,
      blueviolet: { r: 138, g: 43, b: 226 }.freeze,
      brown: { r: 165, g: 42, b: 42 }.freeze,
      burlywood: { r: 222, g: 184, b: 135 }.freeze,
      cadetblue: { r: 95, g: 158, b: 160 }.freeze,
      chartreuse: { r: 127, g: 255, b: 0 }.freeze,
      chocolate: { r: 210, g: 105, b: 30 }.freeze,
      coral: { r: 255, g: 127, b: 80 }.freeze,
      cornflower: { r: 100, g: 149, b: 237 }.freeze,
      cornflowerblue: { r: 100, g: 149, b: 237 }.freeze,
      cornsilk: { r: 255, g: 248, b: 220 }.freeze,
      crimson: { r: 220, g: 20, b: 60 }.freeze,
      cyan: { r: 0, g: 255, b: 255 }.freeze,
      darkblue: { r: 0, g: 0, b: 139 }.freeze,
      darkcyan: { r: 0, g: 139, b: 139 }.freeze,
      darkgoldenrod: { r: 184, g: 134, b: 11 }.freeze,
      darkgray: { r: 169, g: 169, b: 169 }.freeze,
      darkgreen: { r: 0, g: 100, b: 0 }.freeze,
      darkgrey: { r: 169, g: 169, b: 169 }.freeze,
      darkkhaki: { r: 189, g: 183, b: 107 }.freeze,
      darkmagenta: { r: 139, g: 0, b: 139 }.freeze,
      darkolivegreen: { r: 85, g: 107, b: 47 }.freeze,
      darkorange: { r: 255, g: 140, b: 0 }.freeze,
      darkorchid: { r: 153, g: 50, b: 204 }.freeze,
      darkred: { r: 139, g: 0, b: 0 }.freeze,
      darksalmon: { r: 233, g: 150, b: 122 }.freeze,
      darkseagreen: { r: 143, g: 188, b: 143 }.freeze,
      darkslateblue: { r: 72, g: 61, b: 139 }.freeze,
      darkslategray: { r: 47, g: 79, b: 79 }.freeze,
      darkslategrey: { r: 47, g: 79, b: 79 }.freeze,
      darkturquoise: { r: 0, g: 206, b: 209 }.freeze,
      darkviolet: { r: 148, g: 0, b: 211 }.freeze,
      deeppink: { r: 255, g: 20, b: 147 }.freeze,
      deepskyblue: { r: 0, g: 191, b: 255 }.freeze,
      dimgray: { r: 105, g: 105, b: 105 }.freeze,
      dimgrey: { r: 105, g: 105, b: 105 }.freeze,
      dodgerblue: { r: 30, g: 144, b: 255 }.freeze,
      firebrick: { r: 178, g: 34, b: 34 }.freeze,
      floralwhite: { r: 255, g: 250, b: 240 }.freeze,
      forestgreen: { r: 34, g: 139, b: 34 }.freeze,
      fuchsia: { r: 255, g: 0, b: 255 }.freeze,
      gainsboro: { r: 220, g: 220, b: 220 }.freeze,
      ghostwhite: { r: 248, g: 248, b: 255 }.freeze,
      gold: { r: 255, g: 215, b: 0 }.freeze,
      goldenrod: { r: 218, g: 165, b: 32 }.freeze,
      gray: { r: 128, g: 128, b: 128 }.freeze,
      green: { r: 0, g: 128, b: 0 }.freeze,
      greenyellow: { r: 173, g: 255, b: 47 }.freeze,
      grey: { r: 128, g: 128, b: 128 }.freeze,
      honeydew: { r: 240, g: 255, b: 240 }.freeze,
      hotpink: { r: 255, g: 105, b: 180 }.freeze,
      indianred: {r: 205, g:92, b: 92 }.freeze,
      indigo: { r: 75, g: 0, b: 130 }.freeze,
      ivory: { r: 255, g: 255, b: 240 }.freeze,
      khaki: { r: 240, g: 230, b: 140 }.freeze,
      laserlemoon: { r: 255, g: 255, b: 102 }.freeze,
      lavender: { r: 230, g: 230, b: 250 }.freeze,
      lavenderblush: { r: 255, g: 240, b: 245 }.freeze,
      lawngreen: { r: 124, g: 252, b: 0 }.freeze,
      lemonchiffon: { r: 255, g: 250, b: 205 }.freeze,
      lightblue: { r: 173, g: 216, b: 230 }.freeze,
      lightcoral: { r: 240, g: 128, b: 128 }.freeze,
      lightcyan: { r: 224, g: 255, b: 255 }.freeze,
      lightgoldenrodyellow: { r: 250, g: 250, b: 210 }.freeze,
      lightgray: { r: 211, g: 211, b: 211 }.freeze,
      lightgreen: { r: 144, g: 238, b: 144 }.freeze,
      lightgrey: { r: 211, g: 211, b: 211 }.freeze,
      lightpink: { r: 255, g: 182, b: 193}.freeze,
      lightsalmon: { r: 255, g: 160, b: 122 }.freeze,
      lightseagreen: { r: 32, g: 178, b: 170 }.freeze,
      lightskyblue: { r: 135, g: 206, b: 250 }.freeze,
      lightslategray: { r: 119, g: 136, b: 153 }.freeze,
      lightslategrey: { r: 119, g: 136, b: 153 }.freeze,
      lightsteelblue: { r: 176, g: 196, b: 222 }.freeze,
      lightyellow: { r: 255, g: 255, b: 224 }.freeze,
      lime: { r: 0, g: 255, b: 0 }.freeze,
      limegreen: { r: 50, g: 205, b: 50 }.freeze,
      linen: { r: 250, g: 240, b: 230 }.freeze,
      magenta: { r: 255, g: 0, b: 255 }.freeze,
      maroon: { r: 128, g: 0, b: 0 }.freeze,
      mediumaquamarine: { r: 102, g: 205, b: 170 }.freeze,
      mediumblue: { r: 0, g: 0, b: 205 }.freeze,
      mediumorchid: { r: 186, g: 85, b: 211 }.freeze,
      mediumpurple: { r: 147, g: 112, b: 219 }.freeze,
      mediumseagreen: { r: 60, g: 179, b: 113 }.freeze,
      mediumslateblue: { r: 123, g: 104, b: 238 }.freeze,
      mediumspringgreen: { r: 0, g: 250, b: 154 }.freeze,
      mediumturquoise: { r: 72, g: 209, b: 204 }.freeze,
      mediumvioletred: { r: 199, g: 21, b: 133 }.freeze,
      midnightblue: { r: 25, g: 25, b: 112 }.freeze,
      mintcream: { r: 245, g: 255, b: 250 }.freeze,
      mistyrose: { r: 255, g: 228, b: 225 }.freeze,
      moccasin: { r: 255, g: 228, b: 181 }.freeze,
      navajowhite: { r: 255, g: 222, b: 173 }.freeze,
      navy: { r: 0, g: 0, b: 128 }.freeze,
      oldlace: { r: 253, g: 245, b: 230 }.freeze,
      olive: { r: 128, g: 128, b: 0 }.freeze,
      olivedrab: { r: 107, g: 142, b: 35 }.freeze,
      orange: { r: 255, g: 165, b: 0 }.freeze,
      orangered: { r: 255, g: 69, b: 0 }.freeze,
      orchid: { r: 218, g: 112, b: 214 }.freeze,
      palegoldenrod: { r: 238, g: 232, b: 170 }.freeze,
      palegreen: { r: 152, g: 251, b: 152 }.freeze,
      paleturquoise: { r: 175, g: 238, b: 238 }.freeze,
      palevioletred: { r: 219, g: 112, b: 147 }.freeze,
      papayawhip: { r: 255, g: 239, b: 213 }.freeze,
      peachpuff: { r: 255, g: 218, b: 185 }.freeze,
      peru: { r: 205, g: 133, b: 63 }.freeze,
      pink: { r: 255, g: 192, b: 203 }.freeze,
      plum: { r: 221, g: 160, b: 221 }.freeze,
      powderblue: { r: 176, g: 224, b: 230 }.freeze,
      purple: { r: 128, g: 0, b: 128 }.freeze,
      purple2: { r: 127, g: 0, b: 127 }.freeze,
      purple3: { r: 160, g:  32, b: 240 }.freeze,
      rebeccapurple: { r: 102, g: 51, b: 153 }.freeze,
      red: { r: 255, g: 0, b: 0 }.freeze,
      rosybrown: { r: 188, g: 143, b: 143 }.freeze,
      royalblue: { r: 65, g: 105, b: 225 }.freeze,
      saddlebrown: { r: 139, g: 69, b: 19 }.freeze,
      salmon: { r: 250, g: 128, b: 114 }.freeze,
      sandybrown: { r: 244, g: 164, b: 96 }.freeze,
      seagreen: { r: 46, g: 139, b: 87 }.freeze,
      seashell: { r: 255, g: 245, b: 238 }.freeze,
      sienna: { r: 160, g: 82, b: 45 }.freeze,
      silver: { r: 192, g: 192, b: 192}.freeze,
      skyblue: { r: 135, g: 206, b: 235 }.freeze,
      slateblue: { r: 106, g: 90, b: 205 }.freeze,
      slategray: { r: 112, g: 128, b: 144 }.freeze,
      slategrey: { r: 112, g: 128, b: 144 }.freeze,
      snow: { r: 255, g: 250, b: 250 }.freeze,
      springgreen: { r: 0, g: 255, b: 127 }.freeze,
      steelblue: { r: 70, g: 130, b: 180 }.freeze,
      tan: { r: 210, g: 180, b: 140 }.freeze,
      teal: { r: 0, g: 128, b: 128 }.freeze,
      thistle: { r: 216, g: 191, b: 216 }.freeze,
      tomato: { r: 255, g: 99, b: 71 }.freeze,
      turquoise: { r: 64, g: 224, b: 208 }.freeze,
      violet: { r: 238, g: 130, b: 238 }.freeze,
      wheat: { r: 245, g: 222, b: 179 }.freeze,
      white: { r: 255, g: 255, b: 255 }.freeze,
      whitesmoke: { r: 245, g: 245, b: 245 }.freeze,
      yellow: { r: 255, g: 255, b: 0 }.freeze,
      yellowgreen: { r: 154, g: 205, b: 50 }.freeze,
    }.freeze

    def self.[](color)
      NAMED_COLORS[color]
    end
  end

  module Layout
    extend self

    DEFAULT_FONT = { font: nil, size_px: 16 }

    # Setup
    # * Generate anonymous flex items
    # Line Length Determination
    # * Determine the available main and cross space for the flex items
    # * Determine the flex base size and hypothetical main size of each item
    # * Determine the mainsize of the flex container
    # Main Size Determination
    # * Collect flex items into flex lines
    # * Resolve the flexible lengths of all the flex items
    # Cross Size Determination
    # * Determine the hypothetical cross size of each item
    # * Calculate the cross size of each flex line
    # * Handle content-align: stretch
    # * Collapse visibility: collapse items
    # * Determine the used cross size of each flex item
    # Main-Axis Alignment
    # * Distribute any remaining free space
    # Cross-Axis Alignment
    # * Resolve cross-axis auto margins
    # * Align all flex items along the cross-axis per align-self
    # * Determine the flex container's used cross size
    # * Align all flex lines per align-content
    # Resolving Flexible Lengths
    # * Determine which flex factor to use
    # * Size inflexible items
    # * Calculate initial free space
    # * Loop:
    #   * Check for flexible items
    #   * Calculate the remaining free space
    #   * Distribute free space
    #   * Fix min/max violations
    #   * Freeze over-flexed items
    # * Set main size to target main size
    def apply(root, target:)
      raise if root.nil?
      queue = [ root ]

      # Build a breadth-first traversal of the tree.
      idx = 0
      while idx < queue.length
        node = queue[idx]
        node.internal.screen_x = 0
        node.internal.screen_y = 0
        node.internal.definite_width = nil
        node.internal.definite_height = nil
        node.internal.gap = axis_shorthand(node, :gap)
        node.internal.margin = cardinal_shorthand(node, :margin)
        node.internal.padding = cardinal_shorthand(node, :padding)
        node.internal.border = { width: 0, color: {} }
        node.internal.typeface = {}

        # Determine the border metrics.
        case node.style.dig(:border)
        when Integer
          node.internal.border.width = node.style.dig(:border)
        when Hash
          node.internal.border.width = node.style.dig(:border, :width) || 1
          if node.style.dig(:border).key?(:color)
            node.internal.border.color = node.style.dig(:border, :color)
          else
            node.internal.border.color = node.style.dig(:border)
          end
        when Symbol
          node.internal.border.width = 1
          node.internal.border.color = node.style.dig(:border)
        end

        # Determine the inherited font.
        node.internal.typeface.font = case
        when node.style.key?(:font) then node.style.font
        when node.parent then node.parent.internal.typeface.font
        else DEFAULT_FONT[:font]
        end

        # Determine the inherited font size.
        node.internal.typeface.size_px = node.parent ? node.parent.internal.typeface.size_px : DEFAULT_FONT[:size_px]
        if node.style.font_size.is_a?(Float)
          node.internal.typeface.size_px *= node.style.font_size
        elsif node.style.font_size.is_a?(Integer)
          node.internal.typeface.size_px = node.style.font_size
        end

        # Determine the inherited color.
        node.internal.color = node.style.color
        node.internal.color ||= node.parent ? node.parent.internal.color : {}

        # Calculate the ideal sizes of text nodes.
        if node.is_a?(::UI::TextNode)
          width, height = $gtk.calcstringbox(node.text, node.internal.typeface).map(&:ceil)
          node.internal.text = node.text
          node.internal.definite_width = width
          node.internal.definite_height = height
        end

        # @NOTE `children` needs to be sorted by `order`, then index.
        if node.respond_to?(:children)
          queue += reverse_layout?(node) ? node.children.reverse_each : node.children
        end

        idx += 1
      end

      root.internal.definite_width = target.w
      root.internal.definite_height = target.h
      root.internal.screen_x = 0
      root.internal.screen_y = 0

      queue.reverse_each do |node|
        # Calculate the ideal sizes of each node, based their children.
        node.internal.definite_width ||= case node.style.width
        when Integer then node.style.width
        when nil
          sizes = node.children.lazy.filter_map { |x| x.internal.definite_width + x.internal.margin.horizontal }
          horizontal_layout?(node) ? sizes.sum + node.internal.gap.horizontal * (node.children.length - 1) : sizes.max || 0
        end

        node.internal.definite_height ||= case node.style.height
        when Integer then node.style.height
        when nil
          sizes = node.children.lazy.filter_map { |x| x.internal.definite_height + x.internal.margin.vertical }
          horizontal_layout?(node) ? sizes.max || 0 : sizes.sum + node.internal.gap.vertical * (node.children.length - 1)
        end

        node.internal.definite_width += node.internal.border.width.mult(2) + node.internal.padding.horizontal
        node.internal.definite_height += node.internal.border.width.mult(2) + node.internal.padding.vertical

        if wrapped_layout?(node)
          if horizontal_layout?(node)
            node.internal.definite_height = node.internal.border.width.mult(2) + node.internal.padding.vertical if node.style.height.nil?
          else
            node.internal.definite_width = node.internal.border.width.mult(2) + node.internal.padding.horizontal if node.style.width.nil?
          end
        end

        next unless node.respond_to?(:children)

        lines = [[]]
        main = longest_child = 0
        node.children.each do |child|
          parent_main = horizontal_layout?(node) ? node.internal.definite_width - node.internal.border.width.mult(2) - node.internal.padding.horizontal : node.internal.definite_height - node.internal.border.width.mult(2) - node.internal.padding.vertical
          delta_main = horizontal_layout?(node) ? child.internal.definite_width + child.internal.border.width.mult(2) + child.internal.padding.horizontal : child.internal.definite_height + child.internal.border.width.mult(2) + child.internal.padding.vertical

          if wrapped_layout?(node) && main + delta_main > parent_main
            length = longest_child + (horizontal_layout?(node) ? node.internal.gap.column : node.internal.gap.row)
            lines << []
            longest_child = 0
            main = 0
          end

          main += delta_main
          main += horizontal_layout?(node) ? node.internal.gap.row : node.internal.gap.column if positional_alignment?(node)
          lines.last&.push(child)

          child_size = horizontal_layout?(node) ? child.internal.definite_height : child.internal.definite_width
          longest_child = child_size if child_size > longest_child
        end

        lines.shift if lines.first.empty?
        node.internal.lines = lines
      end

      queue.each do |node|
        next if node.is_a?(::UI::TextNode)

        main_pos = main_start = horizontal_layout?(node) ? node.internal.screen_x + node.internal.border.width + node.internal.padding.left : node.internal.screen_y + node.internal.border.width + node.internal.padding.top
        cross_pos = cross_start = horizontal_layout?(node) ? node.internal.screen_y + node.internal.border.width + node.internal.padding.top : node.internal.screen_x + node.internal.border.width + node.internal.padding.left

        main_gap = horizontal_layout?(node) ? node.internal.gap.horizontal : node.internal.gap.vertical
        cross_gap = horizontal_layout?(node) ? node.internal.gap.vertical : node.internal.gap.horizontal

        main_available = horizontal_layout?(node) ? node.internal.definite_width - node.internal.padding.horizontal : node.internal.definite_height - node.internal.padding.vertical
        cross_available = horizontal_layout?(node) ? node.internal.definite_height - node.internal.padding.vertical : node.internal.definite_width - node.internal.padding.horizontal
        main_available -= node.internal.border.width.mult(2)
        cross_available -= node.internal.border.width.mult(2)

        main_content = main_available
        cross_content = cross_available

        lines = node.internal.lines
        lines = lines.reverse_each if [:reverse, :wrap_reverse].include?(node.style.dig(:flex, :wrap))
        cross_sizes = lines.map do |line|
          sizes = line.map do |child|
            horizontal_layout?(node) ? child.internal.definite_height : child.internal.definite_width
          end
          sizes.max
        end

        cross_available -= cross_sizes.sum

        cross_portion = 0
        cross_remainder = 0
        if cross_available.positive? && cross_sizes.any?
          case node.style.dig(:align, :content)
          when :stretch, nil
            cross_portion = cross_available.fdiv(cross_sizes.length).floor
            cross_remainder = cross_available - cross_portion.mult(cross_sizes.length)
          end
        end

        lines.each_with_index do |line, idx|
          cross_size = cross_sizes[idx]
          stretched = false
          total_grow = 0
          total_shrink = 0

          main_available -= main_gap * (line.length - 1) if positional_alignment?(node)

          line.each_with_index do |child, idx|
            main_available -= horizontal_layout?(node) ? child.internal.definite_width : child.internal.definite_height
            main_available -= horizontal_layout?(node) ? child.internal.margin.horizontal : child.internal.margin.vertical if positional_alignment?(node)

            unless horizontal_layout?(node) ? child.style.height : child.style.width
              case node.style.dig(:align, :content)
              when :stretch, nil
                if [:stretch, nil].include?(child.style.dig(:align, :self) || node.style.dig(:align, :items))
                  stretched = true
                  if horizontal_layout?(node)
                    child.internal.definite_height = cross_size + cross_portion
                    child.internal.definite_height += cross_remainder if idx == line.length - 1
                  else
                    child.internal.definite_width = cross_size + cross_portion
                    child.internal.definite_width += cross_remainder if idx == line.length - 1
                  end
                end
              end
            end

            total_grow += child.style.grow if child.style.fetch(:grow, 0) > 0
            total_shrink += child.style.shrink if child.style.fetch(:shrink, 0) > 0
          end

          grow_fraction = nil
          if total_grow.positive?
            grow_fraction = main_available / total_grow
            main_available = 0
          end

          case alignment_shorthand(node, :justify).content
          when :start, :flex_start
            main_pos += main_available if reverse_layout?(node)
          when :center
            main_pos += main_available / 2
          when :end, :flex_end
            main_pos += main_available unless reverse_layout?(node)
          when :space_around
            main_pos += main_available / (line.length * 2)
          when :space_between
            main_pos += 0
          when :space_evenly
            main_pos += main_available / (line.length + 1)
          end

          reversed_wrap = [:reverse, :wrap_reverse].include?(node.style.dig(:flex, :wrap))
          case alignment_shorthand(node, :align).content
          when :stretch, nil
            cross_pos += cross_portion if reversed_wrap && !stretched
          when :start
            cross_pos += 0
          when :center
            cross_pos += cross_available / 2 if idx.zero?
          when :end
            cross_pos += cross_available if idx.zero?
          when :space_around
            gap = cross_available / lines.count
            cross_pos += idx.zero? ? gap / 2 : gap
          when :space_between
            cross_pos += cross_available if lines.one? && reversed_wrap
            cross_pos += cross_available / (lines.count - 1) unless idx.zero?
          when :space_evenly
            cross_pos += cross_available / (lines.count + 1)
          when :flex_start
            cross_pos += cross_available if idx.zero? && reversed_wrap
          when :flex_end
            cross_pos += cross_available if idx.zero? && !reversed_wrap
          end

          main_used = 0
          line.each_with_index do |child, idx|
            grow = child.style.fetch(:grow, 0)
            if grow_fraction && grow > 0
              size = grow.mult(grow_fraction).round
              main_used += size
              size += (grow_fraction * total_grow) - main_used if idx == line.length - 1

              if horizontal_layout?(node)
                child.internal.definite_width += size
              else
                child.internal.definite_height += size
              end
            end

            child.internal.screen_x += horizontal_layout?(node) ? main_pos : cross_pos
            child.internal.screen_y += horizontal_layout?(node) ? cross_pos : main_pos

            case alignment_shorthand(node, :justify).content
            when :space_around
              main_pos += main_available / line.size
            when :space_between
              main_pos += main_available / (line.size - 1)
            when :space_evenly
              main_pos += main_available / (line.size + 1)
            else
              main_pos += horizontal_layout?(node) ? child.internal.margin.horizontal : child.internal.margin.vertical
              main_pos += main_gap
            end
            main_pos += horizontal_layout?(node) ? child.internal.definite_width : child.internal.definite_height

            if horizontal_layout?(node)
              case alignment_shorthand(child, :align).self || alignment_shorthand(node, :align).items
              when :start
                child.internal.screen_y = cross_pos
              when :center
                child.internal.screen_y = cross_start + (cross_content - child.internal.definite_height).half
              when :end
                child.internal.screen_y = cross_content - child.internal.definite_height
              when :stretch
                unless child.style.height
                  child.internal.screen_y = cross_pos
                  child.internal.definite_height = cross_content
                end
              when :space_around
              when :space_between
              when :space_evenly
              when :flex_start
                if reverse_layout?(node)
                  child.internal.screen_y = cross_content - child.internal.definite_height
                else
                  child.internal.screen_y = cross_pos
                end
              when :flex_end
                if reverse_layout?(node)
                  child.internal.screen_y = cross_pos
                else
                  child.internal.screen_y = cross_content - child.internal.definite_height
                end
              end
            else
              case alignment_shorthand(child, :align).self || alignment_shorthand(node, :align).items
              when :start
                child.internal.screen_x = cross_pos
              when :center
                child.internal.screen_x = cross_start + (cross_content - child.internal.definite_width).half
              when :end
                child.internal.screen_x = cross_content - child.internal.definite_width
              when :stretch
                unless child.style.width
                  child.internal.screen_x = cross_pos
                  child.internal.definite_width = cross_content
                end
              when :space_around
              when :space_between
              when :space_evenly
              when :flex_start
                if reverse_layout?(node)
                  child.internal.screen_x = cross_content - child.internal.definite_width
                else
                  child.internal.screen_x = cross_pos
                end
              when :flex_end
                if reverse_layout?(node)
                  child.internal.screen_x = cross_pos
                else
                  child.internal.screen_x = cross_content - child.internal.definite_width
                end
              end
            end

            # @TODO These are probably supposed to be conditional on something…
            child.internal.screen_x += child.internal.margin.left
            child.internal.screen_y += child.internal.margin.top
          end

          main_pos = main_start
          cross_pos += cross_gap + cross_size
          cross_pos += cross_portion if !reversed_wrap || stretched
        end
      end

      queue.each do |node|
        node.internal.screen_width = node.internal.definite_width.round
        node.internal.screen_height = node.internal.definite_height.round

        left = target.x
        top = target.y + target.h
        node.internal.screen_x = (left + node.internal.screen_x).round
        node.internal.screen_y = (top - node.internal.definite_height - node.internal.screen_y).round
      end
    end

    HORIZONTAL_LAYOUT_DIRECTIONS = [nil, :row, :row_reverse].freeze
    def horizontal_layout?(node)
      HORIZONTAL_LAYOUT_DIRECTIONS.include?(node.style.dig(:flex, :direction))
    end

    REVERSE_LAYOUT_DIRECTIONS = [:row_reverse, :column_reverse].freeze
    def reverse_layout?(node)
      REVERSE_LAYOUT_DIRECTIONS.include?(node.style.dig(:flex, :direction))
    end

    COMPACT_JUSTIFICATION_VALUES = [nil, :start, :center, :end].freeze
    def positional_alignment?(node)
      justify = alignment_shorthand(node, :justify)
      COMPACT_JUSTIFICATION_VALUES.include?(justify.content)
    end

    WRAPPED_LAYOUT_VALUES = [true, :wrap, :reverse, :wrap_reverse]
    def wrapped_layout?(node)
      WRAPPED_LAYOUT_VALUES.include?(node.style.dig(:flex, :wrap))
    end

    def cross_size(node)
      horizontal_layout?(node) ? node.internal.definite_height : node.internal.definite_width
    end

    def flex_base_size(node)
      flex = node.style.flex
      case flex&.basis
      when :auto, nil
        :auto
      when :content
        if node.value?.w.is_a?(Integer) && node.value?.h.is_a?(Integer) && cross_size(node)
          cross_size(node).mult(node.value.w).fdiv(node.value.h).ceil
        else
          :content
        end
      when Integer
        flex.basis
      when Float
      else raise "Unexpected flex.basis: #{flex.basis.inspect}"
      end
    end

    def alignment_shorthand(node, property, default = nil)
      value = node.style[property]

      hash = case value
      when Symbol, nil
        if property == :align
          { content: nil, items: value, self: nil }
        else
          { content: value, items: nil, self: nil }
        end
      when Hash
        value
      else raise "Unexpected #{property}: #{node.style[property].inspect}"
      end

      hash[property == :align ? :items : :content] ||= default
      return hash
    end

    def axis_shorthand(node, property, default = 0)
      value = node.style.fetch(property, default)

      row, col = case value
      when Integer then [value, value]
      when Array
        case value.size
        when 1 then value * 2
        when 2 then value
        else raise "Invalid value for #{property}: #{value.inspect}"
        end
      when Hash
        [ value.row || value.horizontal || 0, value.column || value.vertical || 0 ]
      else raise "Unexpected #{property}: #{node.style[property].inspect}"
      end

      { row: row, column: col, horizontal: row, vertical: col }
    end

    def cardinal_shorthand(node, property, default = 0)
      value = node.style.fetch(property, default)

      top, right, bottom, left = case value
      when Integer then [value, value, value, value]
      when Array
        case value.size
        when 1 then value * 4
        when 2 then value * 2
        when 3 then value.push(value[1])
        when 4 then value
        else raise "Invalid value for #{property}: #{value.inspect}"
        end
      when Hash
        [ value.top || 0, value.right || 0, value.bottom || 0, value.left || 0 ]
      else raise "Unexpected #{property}: #{node.style[property].inspect}"
      end

      { top: top, right: right, bottom: bottom, left: left, horizontal: left + right, vertical: top + bottom }
    end
  end
end
