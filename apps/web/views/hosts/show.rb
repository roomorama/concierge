module Web::Views::Hosts
  class Show
    include Web::View
    include Web::Views::BackgroundWorkersHelper

    def overwrite_count_for(host)
      count = OverwriteRepository.for_host_id(host.id).count
      "#{count} overwrite#{'s' if count > 1}"
    end
  end
end

