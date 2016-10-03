Hanami::Model.migration do
  change do
    create_table :jtb_room_stocks do
      primary_key [:city_code, :hotel_code, :rate_plan_id, :service_date]
      column :city_code,                String, null: false, size: 3
      column :hotel_code,               String, null: false, size: 3
      column :rate_plan_id,             String, null: false, size: 16
      column :service_date,             Date, null: false
      column :number_of_units,          Integer, null: false
      column :closing_date,             String, null: false, size: 8
      column :sale_status,              String, null: false, size: 1
      column :reservation_closing_date, String, size: 8

      index :rate_plan_id
    end
  end
end
