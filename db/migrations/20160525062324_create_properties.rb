Hanami::Model.migration do
  change do
    create_table :properties do
      primary_key :id
      foreign_key :host_id, :hosts, on_delete: :set_null, null: false

      column :identifier, String,  null: false
      column :data,       JSON,    null: false

      column :created_at, Time,    null: false
      column :updated_at, Time,    null: false

      # we want to be able to quickly find a property by its supplier identifier
      # when checking whether it exists or not.
      index :identifier

      # there should not exist two properties for the same host with the
      # same identifier
      index [:host_id, :identifier], unique: true
    end
  end
end
