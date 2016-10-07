Hanami::Model.migration do
  change do
    create_table :jtb_state do
      primary_key [:prefix]

      column :prefix,    String, null: false, size: 40
      column :file_name, String, size: 80
    end
  end
end