Hanami::Model.migration do
  change do
    create_table :hosts do
      primary_key :id

      foreign_key :supplier_id,  :suppliers, on_delete: :set_null, null: false

      column :identifier,   String,  null: false
      column :username,     String,  null: false
      column :access_token, String,  null: false

      column :created_at, Time, null: false
      column :updated_at, Time, null: false

      # we want to be able to quickly find hosts for a given supplier
      index :supplier_id

      # we want the supplier/host identifier combination to be unique,
      # to avoid accidentally adding the same host account for the same
      # supplier twice.
      index [:supplier_id, :identifier], unique: true
    end
  end
end
