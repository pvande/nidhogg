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
        $gtk.draw_solid({ x: x, y: y, w: w, h: h, **style.background })
      end

      if style.dig(:border)
        $gtk.draw_border({ x: x, y: y, w: w, h: h, **(style.dig(:border, :color) || {}) })
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
end
