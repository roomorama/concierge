Hanami::Model.migration do
  up do
    HostRepository.all.each do |host|
      host.fee_percentage = 0.0
      HostRepository.update(host)
    end

    alter_table(:hosts) do
      set_column_not_null :fee_percentage
    end
  end

  down do

  end
end
