# dr-input v0.0.17
# MIT Licensed
# Copyright (c) 2024 Marc Heiligers
# See https://github.com/marcheiligers/dr-input

# Initially based loosely on code from Zif (https://github.com/danhealy/dragonruby-zif)

$clipboard = ''

# TODO: Switch clipboard to system clipboard when setclipboard is available
# TODO: Drag selected text
# TODO: Render Squiggly lines
# TODO: “ghosting text” feature
# TODO: Find/Replace (all)
# TODO: Replace unavailable chars with [?]
module Input
  class TextValue
    attr_reader :text

    def initialize(text)
      @text = text
    end

    def to_s
      @text
    end

    def length
      @text.length
    end

    def empty?
      @text.empty?
    end

    def insert(from, to, text)
      @text = @text[0, from].to_s + text + @text[to, @text.length].to_s
    end

    def index(text)
      @text.index(text)
    end

    def rindex(text)
      @text.rindex(text)
    end

    def slice(from, length = 1)
      @text.slice(from, length)
    end
    alias [] slice

    def replace(text)
      @text = text
    end
  end

  class MultilineValue
    attr_reader :lines

    def initialize(text, word_wrap_chars, crlf_chars, w, font_style:)
      @w = w
      @line_parser = LineParser.new(word_wrap_chars, crlf_chars, font_style: font_style)
      @lines = @line_parser.perform_word_wrap(text, @w)
    end

    def to_s
      @lines.text
    end

    def length
      @lines.last.end
    end

    def empty?
      @lines.last.end == 0
    end

    def insert(from, to, text) # rubocop:disable Metrics/AbcSize
      modified_lines = @lines.modified(from, to)
      original_value = modified_lines.text
      first_modified_line = modified_lines.first
      original_index = first_modified_line.start
      modified_value = original_value[0, from - original_index].to_s + text + original_value[to - original_index, original_value.length].to_s
      new_lines = @line_parser.perform_word_wrap(modified_value, @w, first_modified_line.number, original_index)

      @lines.replace(modified_lines, new_lines)
    end

    def index(text)
      @lines.text.index(text)
    end

    def rindex(text)
      @lines.text.rindex(text)
    end

    def slice(from, length = 1)
      @lines.text.slice(from, length)
    end
    alias [] slice

    def replace(text)
      @lines = @line_parser.perform_word_wrap(text, @w)
    end
  end
end

module Input
  class Line
    attr_reader :text, :clean_text, :start, :end, :length, :wrapped, :new_line
    attr_accessor :number

    def initialize(number, start, text, wrapped, font_style)
      @number = number
      @start = start
      @text = text
      @clean_text = text.delete_prefix("\n")
      @length = text.length
      @end = start + @length
      @wrapped = wrapped
      @new_line = text[0] == "\n"
      @font_style = font_style
    end

    def start=(val)
      @start = val
      @end = @start + @length
    end

    def wrapped?
      @wrapped
    end

    def new_line?
      @new_line
    end

    def to_s
      @text
    end

    def inspect
      "<Line##{@number} #{@start},#{@length} #{@text.gsub("\n", '\n')[0, 200]} #{@wrapped ? '\r' : '\n'}>"
    end

    def measure_to(index)
      if @text[0] == "\n"
        index < 1 ? 0 : @font_style.string_width(@text[1, index - 1].to_s)
      else
        @font_style.string_width(@text[0, index].to_s)
      end
    end

    def index_at(x)
      return @start if x <= 0

      index = -1
      width = 0
      while (index += 1) < length
        char = @text[index, 1]
        char_w = char == "\n" ? 0 : @font_style.string_width(char)
        # TODO: Test `index_at` with multiple different fonts
        char_mid = char_w / 4
        return index + @start if width + char_mid > x
        return index + 1 + @start if width + char_mid > x

        width += char_w
      end

      index + @start
    end
  end

  class LineCollection
    attr_reader :lines

    include Enumerable

    def initialize(lines = [])
      @lines = lines
    end

    def each
      @lines.each { |line| yield(line) }
    end

    def length
      @lines.length
    end

    def [](num)
      @lines[num]
    end

    def first
      @lines.first
    end

    def last
      @lines.last
    end

    def <<(line)
      @lines.append(line)
      self
    end

    def empty?
      @lines.empty?
    end

    def replace(old_lines, new_lines)
      @lines = (@lines[0, old_lines.first.number] || []) + new_lines.lines + (@lines[old_lines.last.number + 1, @lines.length] || [])

      i = new_lines.last.number
      l = @lines.length
      s = new_lines.last.end
      while (i += 1) < l
        line = @lines[i]
        line.number = i
        line.start = s
        s = line.end
      end
    end

    def modified(from_index, to_index)
      to_index, from_index = from_index, to_index if from_index > to_index
      line = line_at(from_index)
      modified_lines = []
      i = line.number
      loop do
        modified_lines << line
        break unless line.end < to_index || line.wrapped?

        line = @lines[i += 1]
      end

      LineCollection.new(modified_lines)
    end

    def text
      @lines.map(&:text).join
    end

    def line_at(index)
      @lines.detect { |line| index <= line.end } || @lines.last
    end

    def inspect
      @lines.map(&:inspect)
    end
  end

  class LineParser
    def initialize(word_wrap_chars, crlf_chars, font_style:)
      @word_wrap_chars = word_wrap_chars
      @crlf_chars = crlf_chars
      @font_style = font_style
    end

    def find_word_breaks(text)
      # @word_chars = params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']
      # @punctuation_chars = params[:punctuation_chars] || %w[! % , . ; : ' " ` ) \] } * &]
      # @crlf_chars = ["\r", "\n"]
      # @word_wrap_chars = @word_chars + @punctuation_chars
      words = []
      word = ''
      index = -1
      length = text.length
      mode = :leading_white_space

      while (index += 1) < length # mode = find a word-like thing
        case mode
        when :leading_white_space
          if text[index].strip == '' # leading white-space
            if @crlf_chars.include?(text[index]) # TODO: prolly need to replace \r\n with \n up front
              words << word
              word = "\n"
            else
              word << text[index] # TODO: consider how to render TAB, maybe convert TAB into 4 spaces?
            end
          else
            word << text[index]
            mode = :word_wrap_chars
          end
        when :word_wrap_chars # TODO: consider smarter handling. "something!)something" would be considered a word right now, theres an extra step needed
          if @word_wrap_chars.include?(text[index])
            word << text[index]
          elsif @crlf_chars.include?(text[index])
            words << word
            word = "\n"
            mode = :leading_white_space
          else
            word << text[index]
            mode = :trailing_white_space
          end
        when :trailing_white_space
          if text[index].strip == '' # trailing white-space
            if @crlf_chars.include?(text[index])
              words << word
              word = "\n" # converting all new line chars to \n
              mode = :leading_white_space
            else
              word << text[index] # TODO: consider how to render TAB, maybe convert TAB into 4 spaces?
            end
          else
            words << word
            word = text[index]
            mode = :word_wrap_chars
          end
        end
      end

      words << word
    end

    def perform_word_wrap(text, width, first_line_number = 0, first_line_start = 0)
      words = find_word_breaks(text)
      lines = LineCollection.new
      line = ''
      i = -1
      le = words.length
      while (i += 1) < le
        word = words[i]
        if word == "\n"
          unless line == ''
            lines << Line.new(lines.length + first_line_number, first_line_start, line, false, @font_style)
            first_line_start = lines.last.end
          end
          line = word
        else
          w = @font_style.string_width((line + word).rstrip)
          if w > width
            unless line == ''
              lines << Line.new(lines.length + first_line_number, first_line_start, line, true, @font_style)
              first_line_start = lines.last.end
            end

            # break up long words
            w = @font_style.string_width(word.rstrip)
            # TODO: make this a binary search
            while w > width
              r = word.length - 1
              l = 0
              m = r.idiv(2)
              w = @font_style.string_width(word[0, m].rstrip)
              loop do
                if w == width
                  # Whoa, add this
                  lines << Line.new(lines.length + first_line_number, first_line_start, word[0, m], true, @font_style)
                  first_line_start = lines.last.end
                  word = word[m, word.length]
                  break
                elsif w < width
                  if r - l <= 1
                    lines << Line.new(lines.length + first_line_number, first_line_start, word[0, r], true, @font_style)
                    first_line_start = lines.last.end
                    word = word[r, word.length]
                    break
                  end

                  # go right
                  l = m + 1
                  m = (l + r).idiv(2)
                elsif w > width
                  if r - l <= 1
                    lines << Line.new(lines.length + first_line_number, first_line_start, word[0, l], true, @font_style)
                    first_line_start = lines.last.end
                    word = word[l, word.length]
                    break
                  end

                  # go left
                  r = m - 1
                  m = (l + r).idiv(2)
                end
                w = @font_style.string_width(word[0, m].rstrip)
              end
              w = @font_style.string_width(word.rstrip)
            end
            line = word
          elsif word.start_with?("\n")
            unless line == ''
              lines << Line.new(lines.length + first_line_number, first_line_start, line, false, @font_style)
              first_line_start = lines.last.end
            end
            line = word
          else
            line << word
          end
        end
      end

      lines << Line.new(lines.length + first_line_number, first_line_start, line, false, @font_style)
    end
  end
end

module Input
  module FontStyle
    def self.from(word_chars:, font: nil, size_px: nil, size_enum: nil)
      font ||= ''
      return UsingSizePx.new(font: font, word_chars: word_chars, size_px: size_px) if size_px

      UsingSizeEnum.new(font: font, word_chars: word_chars, size_enum: size_enum)
    end

    class UsingSizeEnum
      attr_reader :font_height

      SIZE_ENUM = {
        small: -1,
        normal: 0,
        large: 1,
        xlarge: 2,
        xxlarge: 3,
        xxxlarge: 4
      }.freeze

      def initialize(font:,  word_chars:, size_enum:)
        @font = font
        @size_enum = SIZE_ENUM.fetch(size_enum || :normal, size_enum)
        _, @font_height = $gtk.calcstringbox(word_chars.join(''), @size_enum, @font)
      end

      def string_width(str)
        $gtk.calcstringbox(str, @size_enum, @font)[0]
      end

      def label(values)
        { font: @font, size_enum: @size_enum, **values }
      end
    end

    class UsingSizePx
      attr_reader :font_height

      def initialize(font:,  word_chars:, size_px:)
        @font = font
        @size_px = size_px
        _, @font_height = $gtk.calcstringbox(word_chars.join(''), font: @font, size_px: @size_px)
      end

      def string_width(str)
        $gtk.calcstringbox(str, font: @font, size_px: @size_px)[0]
      end

      def label(values)
        { font: @font, size_px: @size_px, **values }
      end
    end
  end
end

module Input
  class Base
    attr_sprite
    attr_reader :value, :selection_start, :selection_end, :cursor_x, :cursor_y,
                :content_w, :content_h, :scroll_w, :scroll_h
    attr_accessor :readonly, :scroll_x, :scroll_y

    CURSOR_FULL_TICKS = 30
    CURSOR_FLASH_TICKS = 20

    NOOP = ->(*_args) {}

    # BUG: Modifier keys are broken on the web ()
    META_KEYS = %i[meta_left meta_right meta].freeze
    SHIFT_KEYS = %i[shift_left shift_right shift].freeze
    ALT_KEYS = %i[alt_left alt_right alt].freeze
    CTRL_KEYS = %i[control_left control_right control].freeze
    IGNORE_KEYS = (%i[raw_key char] + META_KEYS + SHIFT_KEYS + ALT_KEYS + CTRL_KEYS).freeze

    @@id = 0

    def initialize(**params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      @x = params[:x] || 0
      @y = params[:y] || 0

      word_chars = (params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-'])
      @font_style = FontStyle.from(word_chars: word_chars, **params.slice(:font, :size_enum, :size_px))
      @font_height = @font_style.font_height
      @word_chars = Hash[word_chars.map { [_1, true] }]
      @punctuation_chars = Hash[(params[:punctuation_chars] || %w[! % , . ; : ' " ` ) \] } * &]).map { [_1, true] }]
      @crlf_chars = { "\r" => true, "\n" => true }

      @padding = params[:padding] || 2

      @w = params[:w] || 256
      @h = params[:h] || @font_height + @padding * 2

      @text_color = (parse_color_nilable(params, :text) || {
        r: params[:r] || 0,
        g: params[:g] || 0,
        b: params[:b] || 0,
        a: params[:a] || 255,
      }).merge(vertical_alignment_enum: 0)
      @background_color = parse_color_nilable(params, :background)
      @blurred_background_color = parse_color_nilable(params, :blurred) || @background_color

      @prompt = params[:prompt] || ''
      @prompt_color = parse_color(params, :prompt, 128, 128, 128).merge(vertical_alignment_enum: 0)

      @max_length = params[:max_length] || false

      @selection_start = params[:selection_start] || params.fetch(:value, '').length
      @selection_end = params[:selection_end] || @selection_start

      @selection_color = parse_color(params, :selection, 102, 178, 255, 128)
      @blurred_selection_color = parse_color(params, :blurred_selection, 112, 128, 144, 128)

      # To manage the flashing cursor
      @cursor_color = parse_color(params, :cursor)
      @cursor_width = params[:cursor_width] || 2
      @cursor_ticks = 0
      @cursor_dir = 1
      @ensure_cursor_visible = true

      @key_repeat_delay = params[:key_repeat_delay] || 20
      @key_repeat_debounce = params[:key_repeat_debounce] || 4

      # Mouse focus for seletion
      @mouse_down = false
      @mouse_wheel_speed = params[:mouse_wheel_speed] || @font_height

      # Render target for text scrolling
      @path = "__input_#{@@id += 1}"

      @scroll_x = 0
      @scroll_y = 0
      @content_w = @w
      @content_h = @h

      @scroll_x = 0
      @scroll_y = 0
      @scroll_w = @w
      @scroll_h = @h

      @readonly = params[:readonly] || false
      @focussed = params[:focussed] || false
      @will_focus = false # Get the focus at the end of the tick

      @on_clicked = params[:on_clicked] || NOOP
      @on_unhandled_key = params[:on_unhandled_key] || NOOP

      @value_changed = true
    end

    def parse_color(params, name, dr = 0, dg = 0, db = 0, da = 255)
      cp = params["#{name}_color".to_sym]
      if cp
        case cp
        when Array
          { r: cp[0] || dr, g: cp[1] || dg, b: cp[2] || db, a: cp[3] || da }
        when Hash
          { r: cp.r || dr, g: cp.g || dg, b: cp.b || db, a: cp.a || da }
        when Integer
          if cp > 0xFFFFFF
            { r: (cp & 0xFF000000) >> 24, g: (cp & 0xFF0000) >> 16, b: (cp & 0xFF00) >> 8, a: cp & 0xFF }
          else
            { r: (cp & 0xFF0000) >> 16, g: (cp & 0xFF00) >> 8, b: cp & 0xFF, a: da }
          end
        else
          raise ArgumentError, "Color #{name} should be an Array or Hash"
        end
      else
        {
          r: params["#{name}_r".to_sym] || dr,
          g: params["#{name}_g".to_sym] || dg,
          b: params["#{name}_b".to_sym] || db,
          a: params["#{name}_a".to_sym] || da,
        }
      end
    end

    def parse_color_nilable(params, name)
      return parse_color(params, name) if params["#{name}_color".to_sym] || params["#{name}_r".to_sym] || params["#{name}_g".to_sym] || params["#{name}_b".to_sym] || params["#{name}_a".to_sym]

      nil
    end

    def draw_override(_ffi)
      return unless @will_focus

      @will_focus = false
      @focussed = true
      @ensure_cursor_visible = true
    end

    def draw_cursor(rt)
      return unless @focussed || @will_focus
      return if @readonly

      @cursor_ticks += @cursor_dir
      alpha = if @cursor_ticks == CURSOR_FULL_TICKS
                @cursor_dir = -1
                255
              elsif @cursor_ticks == 0
                @cursor_dir = 1
                0
              elsif @cursor_ticks < CURSOR_FULL_TICKS
                $args.easing.ease(0, @cursor_ticks, CURSOR_FLASH_TICKS, :quad) * 255
              else
                255
              end
      rt.primitives << {
        x: (@cursor_x - 1).greater(0) - @scroll_x,
        y: @cursor_y - @padding - @scroll_y,
        w: @cursor_width,
        h: @font_height + @padding * 2
      }.solid!(**@cursor_color, a: alpha)
    end

    def tick
      if @focussed
        prepare_special_keys
        handle_keyboard
      end
      handle_mouse
      prepare_render_target
    end

    def focussed?
      @focussed
    end

    def focus
      @will_focus = true
    end

    def blur
      @focussed = false
    end

    def value=(text)
      text = text[0, @max_length] if @max_length
      @value.replace(text)
      @selection_start = @selection_start.lesser(text.length)
      @selection_end = @selection_end.lesser(text.length)
    end

    def selection_start=(index)
      @selection_start = index.cap_min_max(0, @value.length)
    end

    def selection_end=(index)
      @selection_end = index.cap_min_max(0, @value.length)
    end

    def insert(str)
      @selection_end, @selection_start = @selection_start, @selection_end if @selection_start > @selection_end
      insert_at(str, @selection_start, @selection_end)

      @selection_start += str.length
      @selection_end = @selection_start
    end
    alias replace insert

    def insert_at(str, start_at, end_at = start_at)
      end_at, start_at = start_at, end_at if start_at > end_at
      if @max_length && @value.length - (end_at - start_at) + str.length > @max_length
        str = str[0, @max_length - @value.length + (end_at - start_at) - str.length]
        return if str.nil? # too long
      end

      @value.insert(start_at, end_at, str)
    end
    alias replace_at insert_at

    def append(str)
      insert_at(str, @value.length)
    end

    def find(text)
      index = @value.index(text)
      return unless index

      @selection_start = index
      @selection_end = index + text.length
    end

    def current_selection
      return nil if @selection_start == @selection_end

      if @selection_start < @selection_end
        @value[@selection_start, @selection_end - @selection_start]
      else
        @value[@selection_end, @selection_start - @selection_end]
      end
    end

    def current_word
      return nil if @selection_end == 0
      return nil unless @word_chars[@value[@selection_end - 1]]

      left = find_word_break_left
      right = @word_chars[@value[@selection_end]] ? find_word_break_right : @selection_end
      @value[left, right - left]
    end

    def find_next
      text = current_selection
      return if text.nil?

      index = @value.index(text, @selection_end.greater(@selection_start)) || @value.index(text)

      @selection_start = index
      @selection_end = index + text.length
    end

    def find_prev
      text = current_selection
      return if text.nil?

      index = @value.rindex(text, (@selection_start - 1).lesser(@selection_end - 1)) ||
              @value.rindex(text, @value.length)

      @selection_start = index
      @selection_end = index + text.length
    end

    def find_word_break_left # rubocop:disable Metrics/MethodLength
      return 0 if @selection_end == 0

      index = @selection_end
      value = @value.to_s

      loop do
        index -= 1
        return 0 if index == 0
        break if @word_chars[value[index]]
      end

      loop do
        index -= 1
        return 0 if index == 0
        return index + 1 unless @word_chars[value[index]]
      end
    end

    def find_word_break_right(index = @selection_end) # rubocop:disable Metrics/MethodLength
      value = @value.to_s
      length = value.length
      return length if index >= length

      loop do
        return length if index == length
        break if @word_chars[value[index]]
        index += 1
      end

      loop do
        index += 1
        return length if index == length
        return index unless @word_chars[value[index]]
      end
    end

    def select_all
      @selection_start = 0
      @selection_end = @value.length
    end

    def select_to_start
      @selection_end = 0
    end

    def move_to_start
      @selection_start = @selection_end = 0
    end

    def select_to_end
      @selection_end = @value.length
    end

    def move_to_end
      @selection_start = @selection_end = @value.length
    end

    def select_word_left
      @selection_end = find_word_break_left
    end

    def select_word_right
      @selection_end = find_word_break_right
    end

    def select_char_left
      @selection_end = (@selection_end - 1).greater(0)
    end

    def select_char_right
      @selection_end = (@selection_end + 1).lesser(@value.length)
    end

    def move_word_left
      index = find_word_break_left
      @selection_start = @selection_end = find_word_break_left
    end

    def move_word_right
      @selection_start = @selection_end = find_word_break_right
    end

    def move_char_left
      @selection_end = if @selection_end > @selection_start
                         @selection_start
                       elsif @selection_end < @selection_start
                         @selection_end
                       else
                         (@selection_start - 1).greater(0)
                       end
      @selection_start = @selection_end
    end

    def move_char_right
      @selection_end = if @selection_end > @selection_start
                         @selection_end
                       elsif @selection_end < @selection_start
                         @selection_start
                       else
                         (@selection_start + 1).lesser(@value.length)
                       end
      @selection_start = @selection_end
    end

    def copy
      return if @selection_start == @selection_end

      $clipboard = current_selection
    end

    def cut
      copy
      insert('')
    end

    def delete_back
      @selection_start -= 1 if @selection_start == @selection_end
      insert('')
    end

    def delete_forward
      @selection_start += 1 if @selection_start == @selection_end
      insert('')
    end

    def paste
      insert($clipboard)
    end

    def prepare_special_keys # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      keyboard = $args.inputs.keyboard

      tick_count = $args.tick_count
      repeat_keys = keyboard.key_held.truthy_keys.select do |key|
        ticks = tick_count - keyboard.key_held.send(key).to_i
        ticks > @key_repeat_delay && ticks % @key_repeat_debounce == 0
      end
      @down_keys = keyboard.key_down.truthy_keys.concat(repeat_keys) - IGNORE_KEYS

      # Find special keys
      special_keys = keyboard.key_down.truthy_keys + keyboard.key_held.truthy_keys
      @meta = (special_keys & META_KEYS).any?
      @alt = (special_keys & ALT_KEYS).any?
      @shift = (special_keys & SHIFT_KEYS).any?
      @ctrl = (special_keys & CTRL_KEYS).any?
    end

    def rect
      { x: @x, y: @y, w: @w, h: @h }
    end

    def content_rect
      { x: @scroll_x, y: @scroll_y, w: @content_w, h: @content_h }
    end

    def scroll_rect
      { x: @scroll_x, y: @scroll_y, w: @scroll_w, h: @scroll_h }
    end
  end
end

module Input
  class Text < Base
    def initialize(**params)
      @value = TextValue.new(params[:value] || '')
      super
    end

    def draw_override(ffi)
      # The argument order for ffi_draw.draw_sprite_3 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h
      ffi.draw_sprite_3(
        @x, @y, @w, @h,
        @path,
        0, 255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        0, 0, @w, @h
      )
      super # handles focus
    end

    def handle_keyboard
      text_keys = $args.inputs.text

      if @meta || @ctrl
        # TODO: undo/redo
        if @down_keys.include?(:a)
          select_all
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:c)
          copy
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:x)
          @readonly ? copy : cut
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:v)
          paste unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:left)
          @shift ? select_to_start : move_to_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:right)
          @shift ? select_to_end : move_to_end
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:g)
          @shift ? find_prev : find_next
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif text_keys.empty?
        if @down_keys.include?(:delete)
          delete_forward unless @readonly
        elsif @down_keys.include?(:backspace)
          delete_back unless @readonly
        elsif @down_keys.include?(:left) || @down_keys.include?(:left_arrow)
          if @shift
            @alt ? select_word_left : select_char_left
            @ensure_cursor_visible = true
          else
            @alt ? move_word_left : move_char_left
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:right) || @down_keys.include?(:right_arrow)
          if @shift
            @alt ? select_word_right : select_char_right
            @ensure_cursor_visible = true
          else
            @alt ? move_word_right : move_char_right
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:home)
          @shift ? select_to_start : move_to_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:end)
          @shift ? select_to_end : move_to_end
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      else
        insert(text_keys.join('')) unless @readonly
        @ensure_cursor_visible = true
      end
    end

    # TODO: Word selection (double click), All selection (triple click)
    def handle_mouse # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      mouse = $args.inputs.mouse

      if mouse.wheel && mouse.inside_rect?(self)
        d = mouse.wheel.x == 0 ? mouse.wheel.y : mouse.wheel.x
        @scroll_x += d * @mouse_wheel_speed
        @ensure_cursor_visible = false
      end

      return unless @mouse_down || (mouse.down && mouse.inside_rect?(self))

      if @mouse_down # dragging
        index = find_index_at_x(mouse.x - @x + @scroll_x)
        @selection_end = index
        @mouse_down = false if mouse.up
      else
        @on_clicked.call(mouse, self)
        return unless @focussed || @will_focus

        @mouse_down = true

        index = find_index_at_x(mouse.x - @x + @scroll_x)
        if @shift
          @selection_end = index
        else
          @selection_start = @selection_end = index
        end
      end

      @ensure_cursor_visible = true
    end

    def find_index_at_x(x, str = @value) # rubocop:disable Metrics/MethodLength
      return 0 if x < @padding

      l = 0
      r = @value.length - 1
      loop do
        return l if l > r

        m = ((l + r) / 2).floor
        px = @font_style.string_width(str[0, m].to_s)
        if px == x
          return m
        elsif px < x
          l = m + 1
        else
          r = m - 1
        end
      end
    end

    def prepare_render_target
      # TODO: handle padding correctly
      if @focussed || @will_focus
        bg = @background_color
        sc = @selection_color
      else
        bg = @blurred_background_color
        sc = @blurred_selection_color
      end

      @scroll_w = @font_style.string_width(@value.to_s).ceil
      @content_w = @w.lesser(@scroll_w)
      @scroll_h = @content_h = @h

      rt = $args.outputs[@path]
      rt.w = @w
      rt.h = @h
      rt.background_color = bg
      # TODO: implement sprite background
      rt.transient!

      if @value.empty?
        @cursor_x = 0
        @cursor_y = 0
        @scroll_x = 0
        rt.primitives << @font_style.label(x: 0, y: @padding, text: @prompt, **@prompt_color)
      else
        # CURSOR AND SCROLL LOCATION
        @cursor_x = @font_style.string_width(@value[0, @selection_end].to_s)
        @cursor_y = 0

        if @content_w < @w
          @scroll_x = 0
        elsif @ensure_cursor_visible
          if @cursor_x > @scroll_x + @content_w
            @scroll_x = @cursor_x - @content_w
          elsif @cursor_x < @scroll_x
            @scroll_x = @cursor_x
          end
        else
          @scroll_x = @scroll_x.cap_min_max(0, @scroll_w - @w)
        end

        # SELECTION
        if @selection_start != @selection_end
          if @selection_start < @selection_end
            left = (@font_style.string_width(@value[0, @selection_start].to_s) - @scroll_x).cap_min_max(0, @w)
            right = (@font_style.string_width(@value[0, @selection_end].to_s) - @scroll_x).cap_min_max(0, @w)
          elsif @selection_start > @selection_end
            left = (@font_style.string_width(@value[0, @selection_end].to_s) - @scroll_x).cap_min_max(0, @w)
            right = (@font_style.string_width(@value[0, @selection_start].to_s) - @scroll_x).cap_min_max(0, @w)
          end

          rt.primitives << { x: left, y: @padding, w: right - left, h: @font_height + @padding * 2 }.solid!(sc)
        end

        # TEXT
        f = find_index_at_x(@scroll_x)
        l = find_index_at_x(@scroll_x + @content_w) + 2
        rt.primitives << @font_style.label(x: 0, y: @padding, text: @value[f, l - f], **@text_color)
      end

      draw_cursor(rt)
    end
  end
end

module Input
  class Multiline < Base
    def initialize(**params)
      value = params[:value] || ''

      super

      word_wrap_chars = @word_chars.merge(@punctuation_chars)
      @value = MultilineValue.new(value, word_wrap_chars, @crlf_chars, @w, font_style: @font_style)
      @fill_from_bottom = params[:fill_from_bottom] || false
    end

    def lines
      @value.lines
    end

    def draw_override(ffi)
      # The argument order for ffi_draw.draw_sprite_3 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h
      ffi.draw_sprite_3(
        @x, @y, @w, @h,
        @path, 0,
        255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        0, 0, @w, @h
      )
      super # handles focus
    end

    def handle_keyboard
      text_keys = $args.inputs.text
      # On a Mac:
      # Home is Cmd + ↑ / Fn + ←
      # End is Cmd + ↓ / Fn + →
      # PageUp is Fn + ↑
      # PageDown is Fn + ↓
      if @meta || @ctrl
        # TODO: undo/redo
        if @down_keys.include?(:a)
          select_all
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:c)
          copy
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:x)
          @readonly ? copy : cut
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:v)
          paste unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:g)
          @shift ? find_prev : find_next
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:left) || @down_keys.include?(:left_arrow)
          @shift ? select_to_line_start : move_to_line_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:right) || @down_keys.include?(:right_arrow)
          @shift ? select_to_line_end : move_to_line_end
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:up) || @down_keys.include?(:up_arrow)
          @shift ? select_to_start : move_to_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:down) || @down_keys.include?(:down_arrow)
          @shift ? select_to_end : move_to_end
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif text_keys.empty?
        if @down_keys.include?(:delete)
          delete_forward unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:backspace)
          delete_back unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:left) || @down_keys.include?(:left_arrow)
          if @shift
            @alt ? select_word_left : select_char_left
            @ensure_cursor_visible = true
          else
            @alt ? move_word_left : move_char_left
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:right) || @down_keys.include?(:right_arrow)
          if @shift
            @alt ? select_word_right : select_char_right
            @ensure_cursor_visible = true
          else
            @alt ? move_word_right : move_char_right
            @ensure_cursor_visible = true
          end
        # TODO: Retain a original_cursor_x when moving up/down to try stay generally in the same x range
        elsif @down_keys.include?(:up) || @down_keys.include?(:up_arrow)
          if @shift
            select_line_up
            @ensure_cursor_visible = true
          else
            # TODO: beginning of previous paragraph with alt
            move_line_up
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:down) || @down_keys.include?(:down_arrow)
          if @shift
            select_line_down
            @ensure_cursor_visible = true
          else
            # TODO: end of next paragraph with alt
            move_line_down
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:enter)
          insert("\n") unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:pageup)
          @shift ? select_page_up : move_page_up
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:pagedown)
          @shift ? select_page_down : move_page_down
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:home)
          @shift ? select_to_start : move_to_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:end)
          @shift ? select_to_end : move_to_end
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      else
        insert(text_keys.join('')) unless @readonly
        @ensure_cursor_visible = true
      end
    end

    def select_to_line_start
      line = @value.lines.line_at(@selection_end)
      index = line.new_line? ? line.start + 1 : line.start
      @selection_end = index
    end

    def move_to_line_start
      line = @value.lines.line_at(@selection_end)
      index = line.new_line? ? line.start + 1 : line.start
      @selection_start = @selection_end = index
    end

    def find_line_end
      line = @value.lines.line_at(@selection_end)
      if line.wrapped?
        if @selection_end == line.end
          if @value.lines.length > line.number
            line = @value.lines[line.number + 1]
            line.wrapped? ? line.end - 1 : line.end
          else
            line.end
          end
        else
          line.end - 1
        end
      else
        line.end
      end
    end

    def select_to_line_end
      @selection_end = find_line_end
    end

    def move_to_line_end
      @selection_start = @selection_end = find_line_end
    end

    def select_line_up
      @selection_end = selection_end_up_index
    end

    def move_line_up
      @selection_end = @selection_start = selection_end_up_index
    end

    def select_line_down
      @selection_end = selection_end_down_index
    end

    def move_line_down
      @selection_end = @selection_start = selection_end_down_index
    end

    def selection_end_up_index
      return 0 if selection_end == 0

      line = @value.lines.line_at(@selection_end)
      if line.wrapped? && line.end == @selection_end
        line.new_line? ? line.start + 1 : line.start
      elsif line.number == 0
        @selection_end
      elsif line.new_line? && @selection_end == line.start + 1
        line = @value.lines[line.number - 1]
        line.new_line? ? line.start + 1 : line.start
      elsif @selection_end == line.start
        @value.lines[line.number - 1].start
      else
        @value.lines[line.number - 1].index_at(@cursor_x + @scroll_x)
      end
    end

    def selection_end_down_index
      line = @value.lines.line_at(@selection_end)
      if line.number == @value.lines.length - 1
        @selection_end
      elsif line.new_line? && @selection_end == line.start + 1
        line = @value.lines[line.number + 1]
        line.new_line? ? line.start + 1 : line.start
      elsif @selection_end == line.start
        @value.lines[line.number + 1].start
      elsif line.wrapped? && line.end == @selection_end && line.number < @value.lines.length - 2
        line = @value.lines[line.number + 2]
        line.new_line? ? line.start + 1 : line.start
      else
        @value.lines[line.number + 1].index_at(@cursor_x + @scroll_x)
      end
    end

    def move_page_up
      (@h / @font_height).floor.times { @selection_start = @selection_end = selection_end_up_index }
    end

    def move_page_down
      (@h / @font_height).floor.times { @selection_start = @selection_end = selection_end_down_index }
    end

    def select_page_up
      (@h / @font_height).floor.times { @selection_end = selection_end_up_index }
    end

    def select_page_down
      (@h / @font_height).floor.times { @selection_end = selection_end_down_index }
    end

    def current_line
      @value.lines&.line_at(@selection_end)
    end

    # TODO: Word selection (double click), All selection (triple click)
    def handle_mouse # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      mouse = $args.inputs.mouse
      inside = mouse.inside_rect?(self)

      if mouse.wheel && inside
        @scroll_y += mouse.wheel.y * @mouse_wheel_speed
        @ensure_cursor_visible = false
      end

      return unless @mouse_down || (mouse.down && inside)

      if @fill_from_bottom
        relative_y = @content_h < @h ? @y - mouse.y + @content_h : @scroll_h - (mouse.y - @y + @scroll_y)
      else
        relative_y = @scroll_h - (mouse.y - @y + @scroll_y)
        relative_y += @h - @content_h if @content_h < @h
      end
      line = @value.lines[relative_y.idiv(@font_height).cap_min_max(0, @value.lines.length - 1)]
      index = line.index_at(mouse.x - @x + @scroll_x)

      if @mouse_down # dragging
        @selection_end = index
        @mouse_down = false if mouse.up
      else # clicking
        @on_clicked.call(mouse, self)
        return unless (@focussed || @will_focus) && mouse.button_left

        if @shift
          @selection_end = index
        else
          @selection_start = @selection_end = index
        end
        @mouse_down = true
      end

      @ensure_cursor_visible = true
    end

    # @scroll_w - The `scroll_w` read-only property is a measurement of the width of an element's content,
    #             including content not visible on the screen due to overflow. For this control `scroll_w == w`
    # @content_w - The `content_w` read-only property is the inner width of the content in pixels.
    #              It includes padding. For this control `content_w == w`
    # @scroll_h - The `scroll_h` read-only property is a measurement of the height of an element's content,
    #             including content not visible on the screen due to overflow.
    #             http://developer.mozilla.org/en-US/docs/Web/API/Element/scrollHeight
    # @content_h - The `content_h` read-only property is the inner height of the content in pixels.
    #              It includes padding. It is the lesser of `h` and `scroll_h`
    # @cursor_line - The Line (Object) the cursor is on
    # @cursor_index - The index of the string on the @cursor_line that the cursor is found
    # @cursor_y - The y location of the cursor in relative to the scroll_h (all content)
    def prepare_render_target # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      if @focussed || @will_focus
        bg = @background_color
        sc = @selection_color
      else
        bg = @blurred_background_color
        sc = @blurred_selection_color
      end

      # TODO: Implement line spacing
      lines = @value.lines
      @scroll_w = @content_w = @w
      @scroll_h = lines.length * @font_height + 2 * @padding
      @content_h = @h.lesser(@scroll_h)

      rt = $args.outputs[@path]
      rt.w = @w
      rt.h = @h
      rt.background_color = bg
      # TODO: implement sprite background
      rt.transient!

      if @value.empty?
        @cursor_line = 0
        @cursor_x = 0
        @scroll_x = 0
        if @fill_from_bottom
          @cursor_y = 0
          rt.primitives << @font_style.label(x: 0, y: 0, text: @prompt, **@prompt_color)
        else
          @cursor_y = @h - @font_height
          rt.primitives << @font_style.label(x: 0, y: @h - @font_height, text: @prompt, **@prompt_color)
        end
      else
        # CURSOR AND SCROLL LOCATION
        @cursor_line = lines.line_at(@selection_end)
        @cursor_index = @selection_end - @cursor_line.start
        # Move the cursor to the beginning of the next line if the line is wrapped and we're at the end of the line
        if @cursor_index == @cursor_line.length && @cursor_line.wrapped? && lines.length > @cursor_line.number
          @cursor_line = lines[@cursor_line.number + 1]
          @cursor_index = 0
        end

        @cursor_y = @scroll_h - (@cursor_line.number + 1) * @font_height
        @cursor_y += @fill_from_bottom ? @content_h : @h - @content_h if @content_h < @h
        if @scroll_h <= @h # total height is less than height of the control
          @scroll_y = @fill_from_bottom ? @scroll_h : 0
        elsif @ensure_cursor_visible
          if @cursor_y + @font_height > @scroll_y + @content_h
            @scroll_y = @cursor_y + @font_height - @content_h
          elsif @cursor_y < @scroll_y
            @scroll_y = @cursor_y
          end
        else
          @scroll_y = @scroll_y.cap_min_max(0, @scroll_h - @h)
        end
        @cursor_x = @cursor_line.measure_to(@cursor_index).lesser(@w)
        @ensure_cursor_visible = false

        selection_start = @selection_start.lesser(@selection_end)
        selection_end = @selection_start.greater(@selection_end)
        selection_visible = selection_start != selection_end

        content_bottom = @scroll_y - @font_height # internal use only, includes font_height, used for draw
        content_top = @scroll_y + @content_h # internal use only, used for draw
        selection_h = @font_height

        b = @scroll_h - @padding - @scroll_y
        if @content_h < @h
          i = -1
          l = lines.length
          b += @fill_from_bottom ? @content_h : @h - @content_h
        else
          i = (@scroll_h - content_top).idiv(@font_height).greater(0) - 1
          l = (@scroll_h - content_bottom).idiv(@font_height).lesser(lines.length)
        end
        while (i += 1) < l
          line = lines[i]
          y = b - (i + 1) * @font_height

          # SELECTION
          if selection_visible && selection_start <= line.end && selection_end >= line.start
            left = line.measure_to((selection_start - line.start).greater(0))
            right = line.measure_to((selection_end - line.start).lesser(line.length))
            rt.primitives << { x: left, y: y, w: right - left, h: selection_h }.solid!(sc)
          end

          # TEXT FOR LINE
          rt.primitives << @font_style.label(x: 0, y: y, text: line.clean_text, **@text_color)
        end
      end

      draw_cursor(rt)
    end
  end
end

module Input
  def self.replace_console!
    GTK::Console.prepend(Input::Console)
  end

  class Prompt < Text
    def render(args, x:, y:)
      @x = x
      @y = y
      args.outputs.reserved << self
    end

    def str_len
      101 # to short circuit hint logic
    end

    def clear
      self.value = ''
    end

    def paste
      insert($gtk.ffi_misc.getclipboard)
    end

    def tick
      super

      # prevent keys from reaching game
      $args.inputs.text.clear
      $args.inputs.keyboard.key_down.clear
      $args.inputs.keyboard.key_up.clear
      $args.inputs.keyboard.key_held.clear
    end

    # the following methods are modified copies from console_prompt.rb
    # https://github.com/marcheiligers/dragonruby-game-toolkit-contrib/blob/master/dragon/console_prompt.rb
    def autocomplete
      if !@last_autocomplete_prefix
        @last_autocomplete_prefix = calc_autocomplete_prefix
        @next_candidate_index = 0
      else
        candidates = method_candidates(@last_autocomplete_prefix)
        return if candidates.empty?

        candidate = candidates[@next_candidate_index]
        candidate = candidate[0..-2] + " = " if candidate.end_with? '='
        @next_candidate_index += 1
        @next_candidate_index = 0 if @next_candidate_index >= candidates.length
        self.value = display_autocomplete_candidate(candidate)
        self.selection_end = self.value.length
      end
    rescue Exception => e
      puts "* BUG: Tab autocompletion failed. Let us know about this.\n#{e}"
      puts e.backtrace
    end

    def last_period_index
      value.rindex('.')
    end

    def calc_autocomplete_prefix
      if last_period_index
        value[last_period_index + 1, value.length] || ''
      else
        value
      end
    end

    def current_object
      return GTK::ConsoleEvaluator unless last_period_index

      GTK::ConsoleEvaluator.eval(value[0, last_period_index])
    rescue NameError
      nil
    end

    def method_candidates(prefix)
      current_object.autocomplete_methods.map(&:to_s).select { |m| m.start_with? prefix }
    end

    def display_autocomplete_candidate(candidate)
      if last_period_index
        value[0, last_period_index + 1] + candidate.to_s
      else
        candidate.to_s
      end
    end

    def reset_autocomplete
      @last_autocomplete_prefix = nil
      @next_candidate_index = 0
    end
  end

  module Console
    def process_inputs args
      if console_toggle_key_down? args
        args.inputs.text.clear
        toggle
        args.inputs.keyboard.clear if !@visible
      end

      return unless visible?

      mouse_wheel_scroll args

      @log_offset = 0 if @log_offset < 0
    end

    def on_unhandled_key(key, input)
      if $args.inputs.keyboard.key_down.enter
        if slide_progress > 0.5
          # in the event of an exception, the console window pops up
          # and is pre-filled with $gtk.reset.
          # there is an annoying scenario where the exception could be thrown
          # by pressing enter (while playing the game). if you press enter again
          # quickly, then the game is reset which closes the console.
          # so enter in the console is only evaluated if the slide_progress
          # is atleast half way down the page.
          eval_the_set_command
        end
      elsif $args.inputs.keyboard.key_down.up
        if @command_history_index == -1
          @nonhistory_input = current_input_str
        end
        if @command_history_index < (@command_history.length - 1)
          @command_history_index += 1
          self.current_input_str = @command_history[@command_history_index].dup
        end
      elsif $args.inputs.keyboard.key_down.down
        if @command_history_index == 0
          @command_history_index = -1
          self.current_input_str = @nonhistory_input
          @nonhistory_input = ''
        elsif @command_history_index > 0
          @command_history_index -= 1
          self.current_input_str = @command_history[@command_history_index].dup
        end
      elsif inputs_scroll_up_full? $args
        scroll_up_full
      elsif inputs_scroll_down_full? $args
        scroll_down_full
      elsif inputs_scroll_up_half? $args
        scroll_up_half
      elsif inputs_scroll_down_half? $args
        scroll_down_half
      elsif inputs_clear_command? $args
        prompt.clear
        @command_history_index = -1
        @nonhistory_input = ''
      elsif $args.inputs.keyboard.key_down.tab
        prompt.autocomplete
      end
    end

    def prompt
      @prompt ||= Input::Prompt.new(
        x: 0,
        y: 00,
        w: 1280,
        prompt: 'Press CTRL+g or ESCAPE to clear the prompt.',
        text_color: 0xFFFFFF,
        background_color: 0x000000,
        cursor_color: [219, 182, 104],
        on_unhandled_key: method(:on_unhandled_key),
        focussed: true
      )
    end

    def current_input_str
      prompt.value.to_s
    end

    def current_input_str=(str)
      prompt.value = str
      prompt.move_to_end
    end
  end
end
