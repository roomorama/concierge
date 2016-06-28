Hanami::Model.migration do
  change do
    alter_table :external_errors do
      drop_column :message
    end
  end
end
