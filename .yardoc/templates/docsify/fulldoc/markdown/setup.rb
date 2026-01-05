def init
  options.objects = run_verifier(options.objects)

  generate_index
  generate_sidebar
  generate_assets

  serialize(Registry.root)
  options.files.each { |x| serialize(x) }
  options.objects.each { |x| serialize(x) }
end

def generate_index
  serializer.serialize("index.html", T("index").run(options))
end

def generate_sidebar
  serializer.serialize("_sidebar.md", T("sidebar").run(options))
end

def generate_assets
  Array(assets).each { |asset| serialize(asset) }
end

def serialize(obj)
  contents = case obj
  when String
    file(obj)
  when YARD::CodeObjects::ExtraFileObject
    obj.contents
  else
    obj.format(options.to_hash.slice(:format, :template))
  end

  options.serializer.serialize(path_for(obj), contents)
end

def assets
  [
    "javascripts/docsify.js",
    "javascripts/marked-header-badge.js",
    "stylesheets/marked-alert.css",
  ]
end
