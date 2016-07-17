Hanami::Model.migration do
  change do
    alter_table :reservations do
      add_column :supplier, String
    end
  end
end
