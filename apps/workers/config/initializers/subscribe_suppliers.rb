Concierge::Announcer.on("sync.AtLeisure") do |host|
  Workers::Suppliers::AtLeisure.new(host).perform
end
