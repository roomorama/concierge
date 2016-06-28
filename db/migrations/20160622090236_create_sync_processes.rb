Hanami::Model.migration do
  change do
    create_table :sync_processes do
      primary_key :id
      foreign_key :host_id, :hosts, on_delete: :set_null, null: false

      column :started_at,         Time,      null: false
      column :finished_at,        Time,      null: false
      column :properties_created, Integer,   null: false
      column :properties_updated, Integer,   null: false
      column :properties_deleted, Integer,   null: false
      column :successful,         TrueClass, null: false

      column :created_at, Time, null: false
      column :updated_at, Time, null: false
    end
  end
end
