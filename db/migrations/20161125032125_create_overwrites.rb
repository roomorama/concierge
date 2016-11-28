Hanami::Model.migration do
  change do
    create_table :overwrites do
      primary_key :id
      foreign_key :host_id,     :hosts,     on_delete: :set_null, null: false

      column :property_identifier, String
      column :data,                JSON, null: false

      column :created_at, Time,    null: false
      column :updated_at, Time,    null: false

      # there should not exist two overwrites for the same host with the
      # same property identifier
      index [:host_id, :property_identifier], unique: true
    end
  end
end
