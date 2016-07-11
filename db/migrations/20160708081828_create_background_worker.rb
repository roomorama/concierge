Hanami::Model.migration do
  change do
    create_table :background_workers do
      primary_key :id

      foreign_key :supplier_id, :suppliers, null: false

      column :next_run_at, Time,    null: false
      column :interval,    Integer, null: false
      column :type,        String,  null: false
      column :status,      String,  null: false

      column :created_at, Time, null: false
      column :updated_at, Time, null: false
    end
  end
end
