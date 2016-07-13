Hanami::Model.migration do
  up do
    alter_table :sync_processes do
      add_column :stats, JSON,   null: false, default: Sequel.pg_json({})
      add_column :type,  String, null: false

      drop_column :properties_created
      drop_column :properties_updated
      drop_column :properties_deleted
    end
  end

  down do
    alter_table :sync_processes do
      drop_column :stats
      drop_column :type

      add_column :properties_created, Integer, null: false
      add_column :properties_updated, Integer, null: false
      add_column :properties_deleted, Integer, null: false
    end
  end
end
