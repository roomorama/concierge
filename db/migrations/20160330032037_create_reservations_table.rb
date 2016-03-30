Hanami::Model.migration do
  change do
    create_table :reservations do
      primary_key :id

      column :property_id, String, null: false
      column :unit_id, String
      column :check_in, Date, null: false
      column :check_out, Date, null: false
      column :guests, Integer, null: false
      column :code, String, null: false
    end
  end
end