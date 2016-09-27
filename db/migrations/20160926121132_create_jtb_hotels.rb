Hanami::Model.migration do
  change do
    create_table :jtb_hotels do
      primary_key [:language, :city_code, :hotel_code]
      column :language,             String, null: false, size: 5
      column :city_code,            String, null: false, size: 3
      column :hotel_code,           String, null: false, size: 3
      column :jtb_hotel_code,       String, null: false, size: 7
      column :hotel_name,           String, null: false, size: 240
      column :location_code,        String, size: 5
      column :hotel_description,    String, text: true
      column :latitude,             String, size: 15
      column :longitude,            String, size: 15
      column :hotel_type,           String, size: 1
      column :address,              String, text: true
      column :non_smoking_room,     String, size: 1
      column :parking,              String, size: 1
      column :internet,             String, size: 1
      column :wifi,                 String, size: 1
      column :indoor_pool_free,     String, size: 1
      column :indoor_pool_charged,  String, size: 1
      column :outdoor_pool_free,    String, size: 1
      column :outdoor_pool_charged, String, size: 1
      column :indoor_gym_free,      String, size: 1
      column :indoor_gym_charged,   String, size: 1
      column :outdoor_gym_free,     String, size: 1
      column :outdoor_gym_charged,  String, size: 1
      column :wheelchair_access,    String, size: 1
    end
  end
end
