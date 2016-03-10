Hanami::Model.migration do
  change do
    create_table :external_errors do
      primary_key :id

      column :operation,   String, null: false, size: 128
      column :supplier,    String, null: false, size: 128
      column :code,        String, null: false, size: 128
      column :message,     String, null: false, size: 2048
      column :happened_at, Time,   null: false

      # we want to be able to quickly filter by operation.
      index :operation

      # we want to be able to quickly filter errors from a specific supplier.
      index :supplier

      # we want to order errors in order of occurrence.
      index :happened_at

      # we want to see all occurrences of a given error.
      index :code
    end
  end
end
