include T("default/module/html")

def init
  sections(
    :header,
    :extends,
    :includes,
    :docstring, [T("docstring")],
    :class_methods_list, [T("method")],
    :instance_methods_list, [T("method")]
  )
end

def header
  if object.name == :root
    "# Global Namespace\n"
  else
    "# #{object.path}\n"
  end
end

def docstring
  docstring = yieldall
  erb(:docstring) { docstring } unless docstring.empty?
end

def extends
  erb(:extends) if object.mixins(:class).any?
end

def includes
  erb(:includes) if object.mixins(:instance).any?
end

def class_methods_list
  @class_methods ||= method_listing.select { |o| o.scope == :class }
  erb(:class_methods_list) if @class_methods.any?
end

def instance_methods_list
  @instance_methods ||= method_listing.select { |o| o.scope == :instance }
  erb(:instance_methods_list) if @instance_methods.any?
end
