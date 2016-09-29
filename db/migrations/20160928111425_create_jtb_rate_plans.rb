Hanami::Model.migration do
  change do
    create_table :jtb_rate_plans do
      primary_key [:language, :city_code, :hotel_code, :rate_plan_id]
      column :language,       String, null: false, size: 5
      column :city_code,      String, null: false, size: 3
      column :hotel_code,     String, null: false, size: 3
      column :rate_plan_id,   String, null: false, size: 16
      column :room_code,      String, null: false, size: 16
      column :meal_plan_code, String, null: false, size: 3
      column :occupancy,      Integer, null: false
    end
  end
end
