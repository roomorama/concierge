path  = Hanami.root.join("config", "suppliers.yml").to_s
names = YAML.load_file(path) || [] # if the file is empty, +load_file+ returns +false+
names.each do |supplier|
  Concierge::Announcer.on("sync.#{supplier.name}") do |host|
    Workers::Suppliers::AtLeisure.new(host).perform
  end
end
