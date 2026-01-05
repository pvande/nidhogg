def init
  return if object.docstring.blank? && !object.has_tag?(:api)
  sections :index, [:private, :deprecated, :abstract, :todo, :note, :returns_void, :text]#, T('tags')
end

def index
  yieldall
end

def private
  return unless object.tag(:api)&.text == "private"
  "> [!IMPORTANT] This #{object.type} is part of a private API.\n"
end

def deprecated
  return unless object.has_tag?(:deprecated)

  if object.tag(:deprecated).text.empty?
    "> [!WARNING] Deprecated.\n"
  else
    "> [!WARNING] Deprecated. #{object.tag(:deprecated).text}\n"
  end
end

def abstract
  return unless object.has_tag?(:abstract)

  if object.tag(:abstract).text.empty?
    "> Abstract.\n"
  else
    "> Abstract. #{object.tag(:abstract).text}\n"
  end
end

def todo
  return unless object.has_tag?(:todo)
  object.tags(:todo).map { |tag| "> [TODO] #{tag.text}\n" }.join("\n")
end

def note
  return unless object.has_tag?(:note)
  object.tags(:note).map { |tag| "> [!NOTE] #{tag.text}\n" }.join("\n")
end

def returns_void
  return unless object.type == :method
  return if object.name == :initialize && object.scope == :instance
  return unless object.tags(:return).size == 1 && object.tag(:return).types == ['void']
  "This method returns an undefined value.\n"
end

def text
  text = ""
  unless object.tags(:overload).size == 1 && object.docstring.empty?
    text = object.docstring
  end

  if text.strip.empty? && object.tags(:return).size == 1 && object.tag(:return).text
    text = object.tag(:return).text.gsub(/\A([a-z])/, &:downcase)
    text = "Returns #{text.sub(/\.\Z/, '')}." unless text.empty? || text =~ /^\s*return/i
    text = text.gsub(/\A([a-z])/, &:upcase)
  end

  text.strip
end
