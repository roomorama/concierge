Hanami::Model.migration do
  change do
    create_table :jtb_room_stocks do
      primary_key [:language, :hotel_code, :option_plan_id, :service_date]
      column :language,                 String, null: false, size: 3
      column :hotel_code,               String, null: false, size: 3
      column :option_plan_id,           String, null: false, size: 16
      column :service_date,             String, null: false, size: 8
      column :number_of_units,          Integer, null: false
      column :closing_date,             String, null: false, size: 8
      column :sale_status,              String, null: false, size: 1
      column :reservation_closing_date, String, size: 8
    end
  end
end
