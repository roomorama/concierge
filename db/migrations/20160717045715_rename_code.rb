Hanami::Model.migration do
  change do
    alter_table(:reservations) do
      rename_column :code, :reference_number
    end
  end
end
