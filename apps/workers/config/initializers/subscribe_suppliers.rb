suppliers = SupplierRepository.all
suppliers.each do |supplier|
  Concierge::Announcer.on("sync.#{supplier.name}") do |host|
    Workers::Suppliers::AtLeisure.new(host).perform
  end
end
