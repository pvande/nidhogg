def path_for(obj)
  case obj
  when options.readme
    "README.md"
  when String
    obj
  when YARD::CodeObjects::RootObject
    "namespaces/$global.md"
  when YARD::CodeObjects::ExtraFileObject
    "files/#{obj.filename}"
  when YARD::CodeObjects::NamespaceObject
    "namespaces/#{obj.path.gsub("::", "/")}.md"
  when YARD::CodeObjects::Proxy
    nil
  else
    raise "HEY! #{obj.class}"
  end
end

def link_object(object, title = nil, anchor = nil, relative = true)
  link = path_for(object)
  link ? "[#{title || object.path}](#{link}#{anchor})" : (title || object.path)
end

def link_url(url, title = nil, params = {})
  "[#{title || url}](#{url})"
end

def signature(meth)
  # use first overload tag if it has a return type and method itself does not
  if !meth.tag(:return) && meth.tag(:overload) && meth.tag(:overload).tag(:return)
    meth = meth.tag(:overload)
  end

  type = options.default_return || ""
  rmeth = meth
  if !rmeth.has_tag?(:return) && rmeth.respond_to?(:object)
    rmeth = meth.object
  end
  if rmeth.tag(:return) && rmeth.tag(:return).types
    types = rmeth.tags(:return).map {|t| t.types ? t.types : [] }.flatten.uniq
    first = types.first
    if types.size == 2 && types.last == 'nil'
      type = first + '?'
    elsif types.size == 2 && types.last =~ /^(Array)?<#{Regexp.quote types.first}>$/
      type = first + '+'
    elsif types.size > 2
      type = [first, '...'].join(', ')
    elsif types == ['void'] && options.hide_void_return
      type = ""
    else
      type = types.join(", ")
    end
  end
  type = "(#{type})" if type.include?(',')
  type = " -> #{type} " unless type.empty?
  scope = meth.scope == :class ? "#{meth.namespace.name}." : "#{meth.namespace.name.to_s.downcase}."
  name = meth.name
  blk = format_block(meth)
  args = format_args(meth)
  extras = []
  extras_text = ''
  rw = meth.namespace.attributes[meth.scope][meth.name]
  if rw
    attname = [rw[:read] ? 'read' : nil, rw[:write] ? 'write' : nil].compact
    attname = attname.size == 1 ? attname.join('') + 'only' : nil
    extras << attname if attname
  end
  extras << meth.visibility if meth.visibility != :public
  extras_text = '(' + extras.join(", ") + ')' unless extras.empty?
  title = "%s%s%s %s%s%s" % [scope, name, args, blk, type, extras_text]
  title.gsub(/\s+/, ' ')
end

def resolve_links(text)
  text.gsub(/(\\|!)?\{(?!\})(\S+?)(?:\s([^\}]*?\S))?\}(?=[\W]|$)/m) do
    escape = $1
    name = $2
    title = $3
    match = $&
    next(match[1..-1]) if escape
    next(match) if name[0, 1] == '|'
    linkify(name, title)
  end
end
