Hanami::Model.migration do
  change do
    alter_table :sync_processes do
      add_column :stats, JSON,   null: false, default: Sequel.pg_json({})
      add_column :type,  String, null: false
    end
  end
end
