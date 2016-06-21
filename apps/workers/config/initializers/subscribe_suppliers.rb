path  = Hanami.root.join("config", "suppliers.yml").to_s
suppliers = YAML.load_file(path) || [] # if the file is empty, +load_file+ returns +false+
suppliers.each do |supplier|
  Concierge::Announcer.on("sync.#{supplier}") do |host|
    Workers::Suppliers::AtLeisure.new(host).perform
  end
end
