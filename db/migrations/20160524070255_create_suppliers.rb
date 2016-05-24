Hanami::Model.migration do
  change do
    create_table :suppliers do
      primary_key :id

      column :name, String, null: false
    end
  end
end
