def init
  @objects.delete(Registry.root)
  sections :files, :root, :modules_and_classes
end

def files
  files = options.files
  files.reject! { |x| x.filename.end_with?("docsify.json") }
  links = files.map { |x| "- [#{x.title}](#{path_for(x)})" }

  <<~MARKDOWN
    - [Home](/)
    #{links.join("\n")}
  MARKDOWN
end

def root
  <<~MARKDOWN
    - [Global Namespace](/namespaces/$global)
  MARKDOWN
end

def modules_and_classes
  link_descendants_of(Registry.root)
end

def link_descendants_of(obj)
  links = obj.children.map do |child|
    next unless child.is_a?(YARD::CodeObjects::NamespaceObject)

    self_link = "- [#{child.name}](#{path_for(child)})"
    child_links = link_descendants_of(child)
    child_links.empty? ? self_link : "#{self_link}\n#{child_links.gsub(/^/, "  ")}"
  end

  links.compact.join("\n")
end
