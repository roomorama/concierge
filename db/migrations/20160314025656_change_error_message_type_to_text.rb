Hanami::Model.migration do
  change do
    alter_table :external_errors do
      set_column_type :message, String, text: true
    end
  end
end
