module Concierge::SupplierRoutes
  CONFIG = YAML.load_file(Hanami.root.join("config", "suppliers.yml").to_s)

  # ["Avantio", "Kigo", ...] declared at config/suppliers.yml
  def self.declared_suppliers
    CONFIG.keys
  end

  # returns a String, the "path" node of a supplier declared at config/suppliers.yml
  def self.sub_path(supplier_name)
    CONFIG[supplier_name]["path"]
  end

  # returns a String, the "controller" node of a supplier declared at config/suppliers.yml
  def self.controller_name(supplier_name)
    CONFIG[supplier_name]["controller"]
  end
end
