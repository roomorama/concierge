Hanami::Model.migration do
  change do
    alter_table(:hosts) do
      add_column :payment_terms,  String, size: 1024
    end
  end
end

