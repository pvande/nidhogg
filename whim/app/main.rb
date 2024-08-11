$gtk.disable_nil_punning!
$gtk.ffi_misc.gtk_dlopen("menufix") if $gtk.platform?("Mac OS X")

require "lib/input"
require "lib/ui"

TRANSPARENT = { a: 0 }
SIDEBAR_BG_COLOR = { r: 50, g: 50, b: 50 }
EDITOR_BG_COLOR = { r: 20, g: 20, b: 20 }
SCROLLBAR_BG_COLOR = { r: 255, g: 255, b: 255, a: 20 }
BORDER_COLOR = { r: 100, g: 100, b: 100 }
TEXT_COLOR = { r: 230, g: 230, b: 230 }
SELECTION_COLOR = { r: 80, g: 100, b: 160 }

module GTK
  class Mouse
    def double_click
      return unless @click && @previous_click
      (0..15) === (@click.created_at - @previous_click.created_at)
    end
  end

  class Runtime
    def set_clipboard(text)
      case @platform
      when "Linux"
        IO.popen("echo -n \"#{text}\" | xclip -sel c").close
      when "Windows"
        `cmd /c \"echo | set /p dummy=#{text}| clip\"`
      when "Mac OS X"
        `bash -c 'echo -n "#{text}" | pbcopy'`
      end
    end
  end
end

class File
  def self.ls(path)
    case $gtk.platform
    when "Windows"
      `cmd /c "dir /b \"#{path}\""`.split("\r\n")
    when "Linux", "Mac OS X"
      `ls "#{path}"`.split("\n")
    else
      []
    end
  end
end

module Input
  class Base
    def copy
      return if @selection_start == @selection_end

      $clipboard = current_selection
      $gtk.set_clipboard($clipboard)
    end

    def paste
      $clipboard = $gtk.ffi_misc.getclipboard
      insert($clipboard)
    end
  end
end

class EditorBuffers
  attr_reader :active

  def initialize
    @buffers = [Buffer.new(active: true)]
    @active = @buffers.first
    @updated_at = Kernel.global_tick_count
  end

  def refresh?() = @active.refresh || Kernel.global_tick_count == @updated_at

  def new
    @buffers << Buffer.new
    activate(-1)
  end

  def open(name, path)
    buffer = Buffer.new(name: name, file: path, contents: File.open(path).read)
    @buffers.insert(active_index + 1, buffer)
    activate(active_index + 1)
  end

  def each(&block)
    @buffers.each(&block)
  end

  def activate(idx)
    @updated_at = Kernel.global_tick_count
    @active.active = false if @active
    @active = @buffers[idx]
    @active.active = true if @active
  end

  def activate_if_open(file)
    idx = @buffers.find_index { |buffer| buffer.file == file }
    activate(idx) if idx
    idx
  end

  def delete(idx)
    @updated_at = Kernel.global_tick_count
    @buffers.delete_at(idx)
    activate(idx) || activate(-1) || new
  end

  def close
    delete(active_index)
  end

  def active_index
    @buffers.index(@active)
  end

  class Buffer
    attr_accessor :name, :file, :contents, :active, :dirty
    attr_accessor :scroll_x, :scroll_y

    def initialize(name: "*untitled*", file: nil, contents: "", active: false)
      @name = name
      @file = file
      @contents = contents
      @mtime = File.open(file).mtime if file
      @active = active
      @scroll_x = 0
      @scroll_y = 0
      @dirty = false
    end

    def refresh
      return unless @file
      return if @dirty

      file = File.open(@file)
      return if @mtime == file.mtime

      @contents = file.read
      @mtime = file.mtime
    end
  end
end

def self.init
  $state.text_buffer = Input::Multiline.new(
    background_color: EDITOR_BG_COLOR,
    text_color: TEXT_COLOR,
    cursor_color: TEXT_COLOR,
    selection_color: SELECTION_COLOR,
    size_px: 18,
    on_clicked: -> (mouse, input) { input.focus },
  )

  $state.buffers = EditorBuffers.new

  $state.active_menu = nil

  $state.pwd = File.realpath(".")

  $state.app_ui = UI.build(flex: { direction: :column }, align: { items: :stretch }, color: TEXT_COLOR) do
    node(id: "menu_bar") do
      node(id: "file", padding: [8, 16]) { text("File") }
      node(id: "edit", padding: [8, 16]) { text("Edit") }
      node(id: "view", padding: [8, 16]) { text("View") }
      node(id: "help", padding: [8, 16]) { text("Help") }
    end
    node(grow: 1, align: { items: :stretch }) do
      node(id: "buffers", width: 300, color: :black, background: SIDEBAR_BG_COLOR, flex: { direction: :column }, align: { items: :stretch })
      node(background: EDITOR_BG_COLOR, align: { items: :stretch }, grow: 1, padding: 8) do
        node($state.text_buffer, grow: 1)
      end
      node(id: "scrollbar", background: SCROLLBAR_BG_COLOR, width: 12, flex: { direction: :column }) do
        node(id: "scrollbar-pre", width: 12)
        node(id: "scrollbar-thumb", background: SCROLLBAR_BG_COLOR, width: 12)
      end
    end
    node do
      node(padding: [8, 16]) { text("All good!") }
      node(id: "word-count", padding: [8, 16])
    end
  end

  menu_style = {
    id: "items",
    color: TEXT_COLOR,
    background: EDITOR_BG_COLOR,
    border: { color: BORDER_COLOR },
    flex: { direction: :column },
    align: { items: :stretch },
  }

  $state.menus = {
    file: UI.build(**menu_style) do
      node(id: "new_file", padding: 16) { text("New File") }
      node(id: "open_file", padding: 16) { text("Open…") }
      node(id: "save_file", padding: 16) { text("Save") }
      node(id: "quit", padding: 16) { text("Quit") }
    end,
    edit: UI.build(**menu_style) do
      # node(id: "undo", padding: 16) { text("Undo") }
      # node(id: "redo", padding: 16) { text("Redo") }
      node(id: "cut", padding: 16) { text("Cut") }
      node(id: "copy", padding: 16) { text("Copy") }
      node(id: "paste", padding: 16) { text("Paste") }
    end,
    view: UI.build(**menu_style) do
      node(id: "close", padding: 16) { text("Close Editor") }
    end,
    help: UI.build(**menu_style) do
      node(id: "about", padding: 16) { text("About…") }
    end,
  }

  $state.modal = nil
  $state.modals = {
    open_file: UI.build(border: SELECTION_COLOR, background: EDITOR_BG_COLOR, color: TEXT_COLOR, flex: { direction: :column }) do
      node(padding: 5, background: SELECTION_COLOR, align: { self: :stretch }) { text "Open File…" }
      node(id: "pwd", background: SCROLLBAR_BG_COLOR, padding: 5, align: { self: :stretch })
      node(id: "file_list", grow: 1, flex: { direction: :column })
      node(padding: 5, gap: 10, background: SCROLLBAR_BG_COLOR, justify: { content: :end }) do
        node(id: "cancel", border: { color: BORDER_COLOR }, width: 100, padding: [5, 10], justify: { content: :center }) { text "Cancel" }
        node(id: "accept", border: { color: BORDER_COLOR }, width: 100, padding: [5, 10], justify: { content: :center }) { text "Open" }
      end
    end,
    about: UI.build(border: SELECTION_COLOR, background: EDITOR_BG_COLOR, color: TEXT_COLOR, flex: { direction: :column }) do
      node(padding: 5, background: SELECTION_COLOR, align: { self: :stretch }) { text "About Whim (ALPHA)" }
      node(background: EDITOR_BG_COLOR, grow: 1, flex: { direction: :column }, align: { items: :center }) do
        node({ path: "metadata/icon.png" }, width: 200, height: 200)
        text "Whim is a simple text editor written in DragonRuby."
        text ""
        text "It's not intended to be a production-ready text editor,"
        text "but as a demonstration of the NIDHOGG UI library, and how"
        text "that can be used to build real, complex implementations."
        text ""
        text "Please report any bugs you find, and read the source code!"
      end
      node(padding: 5, gap: 10, background: EDITOR_BG_COLOR, justify: { content: :center }) do
        node(id: "cancel", border: { color: BORDER_COLOR }, width: 100, padding: [5, 10], justify: { content: :center }) { text "OK" }
      end
    end,
  }
end

def self.tick(...)
  init if Kernel.tick_count.zero?

  $outputs.background_color = [10, 10, 10]
  $outputs.primitives << $state.app_ui

  tick_sidebar_updates
  tick_status_bar

  UI::Layout.apply($state.app_ui, target: $grid.allscreen_rect)

  if $state.modal
    tick_modal
    tick_modal_shortcuts
  else
    tick_menu
    tick_sidebar
    tick_scrollbar
    tick_global_shortcuts
  end

  tick_buffer

  unless $state.active_menu || $state.modal
    cursor = "arrow"
    if $inputs.mouse.inside_rect?($state.text_buffer.rect)
      cursor = "ibeam"
    elsif $inputs.mouse.inside_rect?($state.app_ui["buffers"])
      $state.app_ui["buffers"].children.each do |child|
        if $inputs.mouse.inside_rect?(child)
          cursor = "hand"
        end
      end
    end

    $gtk.set_system_cursor(cursor)
  end
end

def self.tick_sidebar_updates
  $state.app_ui["buffers"].children.clear
  $state.buffers.each do |buffer|
    colors = { background: SIDEBAR_BG_COLOR, color: :darkgrey }
    colors = { background: :darkgrey } if buffer.active

    $state.app_ui["buffers"] << UI.build(align: { items: :center }, **colors) do
      node(padding: 10, grow: 1) do
        text buffer.name
        text "*" if buffer.dirty
      end
      node(padding: 10) { text "×" }
    end
  end
end

def self.tick_status_bar
  $state.app_ui["word-count"].children.clear
  $state.app_ui["word-count"] << UI.build { text "#{$state.buffers.active.contents.to_s.split(" ").count} words" }
end

def self.tick_modal_shortcuts
  return if $state.modal.nil?

  if $inputs.keyboard.escape
    $state.modal = nil
  elsif $state.modal["file_list"] && $inputs.keyboard.key_down.up && $state.selected_file.nil?
    $state.selected_file = $state.files.size - 1
  elsif $state.modal["file_list"] && $inputs.keyboard.key_down.up && $state.selected_file > 0
    $state.selected_file -= 1
  elsif $state.modal["file_list"] && $inputs.keyboard.key_down.down && $state.selected_file.nil?
    $state.selected_file = 0
  elsif $state.modal["file_list"] && $inputs.keyboard.key_down.down && $state.selected_file < ($state.files.size - 1)
    $state.selected_file += 1
  elsif $state.modal["file_list"] && $inputs.keyboard.key_down.enter && $state.selected_file
    pick_file($state.files[$state.selected_file])
  end

  $inputs.keyboard.clear
end

def self.tick_modal
  modal = $state.modal
  pwd = modal["pwd"]
  file_list = modal["file_list"]

  if pwd
    pwd.children.clear
    pwd << UI.build { text $state.pwd }
  end

  if file_list
    file_list.children.clear
    $state.files.each_with_index do |file, idx|
      colors = {}
      colors = { background: SELECTION_COLOR } if $state.selected_file == idx

      modal["file_list"] << UI.build(padding: 10, **colors) do
        node({ path: "images/#{file.is_dir ? "folder" : "document"}.png" }, width: 16, height: 16, margin: { right: 10 })
        text(file.name)
      end
    end
  end

  UI::Layout.apply(modal, target: $grid.allscreen_rect.scale_rect(0.6, 0.5, 0.5))

  if file_list
    if $inputs.mouse.double_click
      file_list.children.each_with_index do |child, idx|
        if $inputs.mouse.inside_rect?(child)
          pick_file($state.files[idx])
        end
      end
    elsif $inputs.mouse.down
      file_list.children.each_with_index do |child, idx|
        if $inputs.mouse.inside_rect?(child)
          $state.selected_file = idx
        end
      end
    end
  end

  buttons = [ modal["accept"], modal["cancel"] ].compact
  buttons.each do |button|
    button.style.background = $inputs.mouse.point.inside_rect?(button) ? SELECTION_COLOR : TRANSPARENT
  end

  $outputs.primitives << modal

  if $inputs.mouse.point.inside_rect?(modal["accept"]) && $inputs.mouse.down
    pick_file($state.files[$state.selected_file]) if $state.selected_file
  end

  if $inputs.mouse.point.inside_rect?(modal["cancel"]) && $inputs.mouse.down
    $state.modal = nil
  end
end

def self.tick_global_shortcuts
  if $inputs.keyboard.send($gtk.platform?("Mac OS X") ? :meta_n : :ctrl_n)
    new_buffer
  elsif $inputs.keyboard.send($gtk.platform?("Mac OS X") ? :meta_o : :ctrl_o)
    open_file_modal
  elsif $inputs.keyboard.send($gtk.platform?("Mac OS X") ? :meta_s : :ctrl_s)
    save_file
  elsif $inputs.keyboard.send($gtk.platform?("Mac OS X") ? :meta_w : :ctrl_w)
    close_current_buffer
  end
end

def self.tick_menu
  $state.app_ui["menu_bar"].children.each do |item|
    if $inputs.mouse.point.inside_rect?(item) && ($inputs.mouse.down || $state.active_menu)
      if $state.active_menu == item.id && $inputs.mouse.down
        $state.active_menu = nil
      else
        $state.active_menu = item.id
      end
    end

    item.style.background = $state.active_menu == item.id ? SELECTION_COLOR : TRANSPARENT
  end

  if $state.active_menu
    menu = $state.menus[$state.active_menu]

    UI::Layout.apply(menu, target: {
      left: $state.app_ui[$state.active_menu].x,
      top: $state.app_ui[$state.active_menu].y,
    })

    $outputs.primitives << menu

    menu["items"].children.each do |item|
      item.style.background = TRANSPARENT

      next unless $inputs.mouse.inside_rect?(item)
      item.style.background = SELECTION_COLOR

      if $inputs.mouse.down
        $inputs.mouse.clear

        case item.id
        when :new_file
          new_buffer
        when :open_file
          open_file_modal
        when :save_file
          save_file
        when :close
          close_current_buffer
        when :quit
          $gtk.request_quit
        when :cut
          $state.text_buffer.cut
        when :copy
          $state.text_buffer.copy
        when :paste
          $state.text_buffer.paste
        when :about
          open_about_modal
        end

        $state.active_menu = nil
      end
    end
  end
end

def self.tick_sidebar
  $state.app_ui["buffers"].children.each_with_index do |child, idx|
    if $state.active_menu.nil? && $inputs.mouse.inside_rect?(child)
      if $inputs.mouse.down
        if $inputs.mouse.inside_rect?(child.children.last)
          $state.buffers.delete(idx)
        else
          $state.buffers.activate(idx)
        end
      end
    else
      child.children.pop
    end
  end
end

def self.tick_scrollbar
  scrollbar = $state.app_ui["scrollbar"]
  thumb = $state.app_ui["scrollbar-thumb"]
  pre = $state.app_ui["scrollbar-pre"]

  content_h = $state.text_buffer.content_h
  scroll_h = $state.text_buffer.scroll_h
  offscreen_area = scroll_h - content_h
  pct_offscreen = offscreen_area / scroll_h

  $state.dragging_thumb &&= $inputs.mouse.held
  if $inputs.mouse.held && ($state.dragging_thumb ||= $inputs.mouse.inside_rect?(thumb))
    $state.text_buffer.scroll_y += $inputs.mouse.relative_y.fdiv(content_h).mult(scroll_h).round
  elsif $inputs.mouse.down && $inputs.mouse.inside_rect?(scrollbar)
    if $inputs.mouse.y < thumb.y
      $state.text_buffer.scroll_y -= $state.text_buffer.content_h
    elsif $inputs.mouse.y > thumb.y + thumb.h
      $state.text_buffer.scroll_y += $state.text_buffer.content_h
    end
  end

  scroll_y = $state.text_buffer.scroll_y
  scroll_offset = 0
  scroll_offset = (offscreen_area - scroll_y) / offscreen_area unless offscreen_area.zero?

  thumb.style.margin = { top: scrollbar.h.mult(pct_offscreen * scroll_offset).round }
  thumb.style.height = scrollbar.h.mult(content_h).fdiv(scroll_h).round
end

def self.tick_buffer
  if $state.buffers.refresh?
    $state.text_buffer.value = $state.buffers.active.contents
    $state.text_buffer.scroll_x = $state.buffers.active.scroll_x
    $state.text_buffer.scroll_y = $state.buffers.active.scroll_y
  end

  $state.text_buffer.tick

  $state.buffers.active.dirty ||= $state.buffers.active.contents != $state.text_buffer.value.to_s
  $state.buffers.active.contents = $state.text_buffer.value.to_s
  $state.buffers.active.scroll_x = $state.text_buffer.scroll_x
  $state.buffers.active.scroll_y = $state.text_buffer.scroll_y
end

def self.new_buffer
  $state.buffers.new
end

def self.open_file_modal
  entries = File.ls($state.pwd).map do |name|
    path = File.join($state.pwd, name)
    is_dir = FileTest.directory?(path)
    key = [ is_dir ? 0 : 1, name.downcase, name ]
    { name: name, is_dir: is_dir, path: path, sort_key: key }
  end

  parent = File.dirname($state.pwd)
  if parent != "." && parent != $state.pwd
    entries.unshift({
      name: "..",
      is_dir: true,
      path: parent,
      sort_key: [-1, nil, nil]
    })
  end

  $state.files = entries.sort_by(&:sort_key)
  $state.selected_file = nil
  $state.modal = $state.modals[:open_file]
end

def self.save_file
  if $state.buffers.active.file
    File.open($state.buffers.active.file, "w") do |f|
      f.write($state.buffers.active.contents)
      $state.buffers.active.dirty = false
    end
  end
end

def self.pick_file(file)
  if file.is_dir
    $state.pwd = file.path
    open_file_modal
  elsif $state.buffers.activate_if_open(file.path)
    $state.modal = nil
  else
    active = $state.buffers.active
    idx = $state.buffers.active_index if active.file.nil? && active.contents.empty?
    $state.buffers.open(file.name, file.path)
    $state.buffers.delete(idx) if idx
    $state.modal = nil
  end
end

def self.close_current_buffer
  $state.buffers.close
end

def open_about_modal
  $state.modal = $state.modals[:about]
end

# $gtk.reset
