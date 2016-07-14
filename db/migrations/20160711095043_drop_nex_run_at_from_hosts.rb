Hanami::Model.migration do
  up do
    alter_table :hosts do
      drop_column :next_run_at
    end
  end

  down do
    alter_table :hosts do
      add_column :next_run_at, Time
    end
  end
end
