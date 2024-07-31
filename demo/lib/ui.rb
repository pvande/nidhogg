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

      if internal.dig(:border, :width) > 0
        color = internal.dig(:border, :color)
        color = UI::Colors[color] if color.is_a?(Symbol)
        color ||= {}

        size = internal.dig(:border, :width)
        case size
        when 1
          $gtk.draw_border({ x: x, y: y, w: w, h: h, **color })
        else
          $gtk.draw_solid({ x: x, y: y, w: w - size, h: size, **color })
          $gtk.draw_solid({ x: x + w - size, y: y, w: size, h: h - size, **color })
          $gtk.draw_solid({ x: x + size, y: y + h - size, w: w - size, h: size, **color })
          $gtk.draw_solid({ x: x, y: y + size, w: size, h: h - size, **color })
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
      $gtk.draw_label({
        x: @internal.screen_x,
        y: @internal.screen_y,
        text: @text,
        **@internal.typeface,
        **(@internal.color || {}),
        vertical_alignment_enum: 0,
      })
    end
  end

  module Engine
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
end
