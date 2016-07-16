Hanami::Model.migration do
  change do
    alter_table :reservations do
      add_column :created_at, Time
      add_column :updated_at, Time
    end
  end
end
