every 10.minutes do
  rake "background:scheduler CONCIERGE_APP=workers"
end
