Hanami::Model.migration do
  change do
    create_table :jtb_lookups do
      primary_key [:language, :category, :id]
      column :language,   String, null: false, size: 5
      column :category,   String, null: false, size: 2
      column :id,         String, null: false, size: 40
      column :related_id, String, size: 200
      column :name,       String, text: true
    end
  end
end
