Hanami::Model.migration do
  change do
    create_table :jtb_room_prices do
      primary_key [:city_code, :hotel_code, :rate_plan_id, :date]
      column :city_code,    String, null: false, size: 3
      column :hotel_code,   String, null: false, size: 3
      column :rate_plan_id, String, null: false, size: 16
      column :date,         Date, null: false
      column :room_rate,    Float, null: false
    end
  end
end
