module UI
  module Layout
    extend ::UI::Engine
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
        node.internal.typeface = {}

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
        queue += node.children if node.respond_to?(:children)

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

        node.internal.definite_width += node.internal.padding.horizontal
        node.internal.definite_height += node.internal.padding.vertical
      end

      queue.each do |node|
        next if node.is_a?(::UI::TextNode)

        main_pos = main_start = horizontal_layout?(node) ? node.internal.screen_x + node.internal.padding.left : node.internal.screen_y + node.internal.padding.top
        cross_pos = cross_start = horizontal_layout?(node) ? node.internal.screen_y + node.internal.padding.top : node.internal.screen_x + node.internal.padding.left

        main_gap = horizontal_layout?(node) ? node.internal.gap.horizontal : node.internal.gap.vertical
        cross_gap = horizontal_layout?(node) ? node.internal.gap.vertical : node.internal.gap.horizontal

        main_available = horizontal_layout?(node) ? node.internal.definite_width - node.internal.padding.horizontal : node.internal.definite_height - node.internal.padding.vertical
        cross_available = horizontal_layout?(node) ? node.internal.definite_height - node.internal.padding.vertical : node.internal.definite_width - node.internal.padding.horizontal

        # if compact_layout?(node)
        #   main_available += horizontal_layout?(node) ? node.internal.margin.horizontal : node.internal.margin.vertical
        #   cross_available += horizontal_layout?(node) ? node.internal.margin.vertical : node.internal.margin.horizontal
        # end

        main_content = main_available
        cross_content = cross_available

        total_grow = 0
        total_shrink = 0

        node.children.each do |child|
          main_available -= horizontal_layout?(node) ? child.internal.definite_width : child.internal.definite_height
          cross_available -= horizontal_layout?(node) ? child.internal.definite_height : child.internal.definite_width

          if compact_layout?(node)
            main_available -= horizontal_layout?(node) ? child.internal.margin.horizontal : child.internal.margin.vertical
            cross_available -= horizontal_layout?(node) ? child.internal.margin.vertical : child.internal.margin.horizontal
          end

          total_grow += child.style.grow if child.style.fetch(:grow, 0) > 0
          total_shrink += child.style.shrink if child.style.fetch(:shrink, 0) > 0
        end

        main_available -= main_gap * (node.children.length - 1) if compact_layout?(node)

        grow_fraction = nil
        if total_grow.pos?
          grow_fraction = main_available / total_grow
          main_available = 0
        end

        case alignment_shorthand(node, :justify).content
        when :start
          main_pos += main_available if reverse_layout?(node)
        when :center
          main_pos += main_available / 2
        when :end
          main_pos += main_available unless reverse_layout?(node)
        when :space_around
          main_pos += main_available / (node.children.length * 2)
        when :space_between
          main_pos += 0
        when :space_evenly
          main_pos += main_available / (node.children.length + 1)
        end

        case alignment_shorthand(node, :align).items
        when :start
          cross_pos += 0
        when :center
          cross_pos += (cross_available - node.children.lazy.filter_map { |x| x.internal.screen_height }.sum) / 2
        when :end
          cross_pos += cross_available - node.children.lazy.filter_map { |x| x.internal.screen_height }.sum
        when :stretch
          cross_pos += 0
        when :space_around
          cross_pos += (cross_available - node.children.lazy.filter_map { |x| x.internal.screen_height }.sum) / 2
        when :space_between
          cross_pos += 0
        when :space_evenly
          cross_pos += 0
        end

        main_used = 0
        children = reverse_layout?(node) ? node.children.reverse_each : node.children
        children.each_with_index do |child, idx|
          grow = child.style.fetch(:grow, 0)
          if grow_fraction && grow > 0
            size = grow.mult(grow_fraction).round
            main_used += size
            size += (grow_fraction * total_grow) - main_used if idx == node.children.length - 1

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
            main_pos += main_available / node.children.size
          when :space_between
            main_pos += main_available / (node.children.size - 1)
          when :space_evenly
            main_pos += main_available / (node.children.size + 1)
          else
            main_pos += horizontal_layout?(node) ? child.internal.margin.horizontal : child.internal.margin.vertical
            main_pos += main_gap
          end
          main_pos += horizontal_layout?(node) ? child.internal.definite_width : child.internal.definite_height

          if horizontal_layout?(node)
            case alignment_shorthand(node, :align).self || alignment_shorthand(node, :align).items
            when :start
              child.internal.screen_y += cross_start
            when :center
              child.internal.screen_y = cross_start + (cross_content - child.internal.definite_height).half
            when :end
              child.internal.screen_y = cross_content - child.internal.definite_height
            when :stretch
              child.internal.screen_y = cross_start unless child.style.height
              child.internal.definite_height = cross_content
            when :space_around
            when :space_between
            when :space_evenly
            end
          else
            case alignment_shorthand(node, :align).self || alignment_shorthand(node, :align).items
            when :start
              child.internal.screen_x = cross_start
            when :center
              child.internal.screen_x = cross_start + (cross_content - child.internal.definite_width).half
            when :end
              child.internal.screen_x = cross_content - child.internal.definite_width
            when :stretch
              child.internal.screen_x = cross_start unless child.style.width
              child.internal.definite_width = cross_content
            when :space_around
            when :space_between
            when :space_evenly
            end
          end

          # @TODO These are probably supposed to be conditional on something…
          child.internal.screen_x += child.internal.margin.left
          child.internal.screen_y += child.internal.margin.top
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

    HORIZONTAL_LAYOUT_DIRECTIONS = [:row, :row_reverse].freeze
    def horizontal_layout?(node)
      HORIZONTAL_LAYOUT_DIRECTIONS.include?(node.style.dig(:flex, :direction))
    end

    REVERSE_LAYOUT_DIRECTIONS = [:row_reverse, :column_reverse].freeze
    def reverse_layout?(node)
      REVERSE_LAYOUT_DIRECTIONS.include?(node.style.dig(:flex, :direction))
    end

    COMPACT_JUSTIFICATION_VALUES = [:start, :center, :end].freeze
    def compact_layout?(node)
      justify = alignment_shorthand(node, :justify)
      COMPACT_JUSTIFICATION_VALUES.include?(justify.content)
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

    def alignment_shorthand(node, property, default = :start)
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
