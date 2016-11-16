module Concierge::SupplierRoutes
  @@config = YAML.load_file(Hanami.root.join("config", "suppliers.yml").to_s)

  def self.load(path)
    @@config = YAML.load_file(path)
  end
  # ["Avantio", "Kigo", ...] declared at config/suppliers.yml
  def self.declared_suppliers
    @@config.keys
  end

  # returns a String, the "path" node of a supplier declared at config/suppliers.yml
  def self.sub_path(supplier_name)
    @@config[supplier_name]["path"]
  end

  # returns a String, the "controller" node of a supplier declared at config/suppliers.yml
  def self.controller_name(supplier_name)
    @@config[supplier_name]["controller"]
  end
end
