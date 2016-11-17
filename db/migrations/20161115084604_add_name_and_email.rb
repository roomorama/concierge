Hanami::Model.migration do
  change do
    alter_table(:hosts) do
      add_column :email, String
      add_column :name,  String
      add_column :phone, String
    end
  end
end
