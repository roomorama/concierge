Hanami::Model.migration do
  change do
    alter_table :external_errors do
      add_column :description, String, null: true, size: 2048
    end
  end
end
