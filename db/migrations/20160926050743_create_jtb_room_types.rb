Hanami::Model.migration do
  change do
    create_table :jtb_room_types do
      primary_key [:language, :city_code, :hotel_code, :room_code]
      column :language,       String, null: false, size: 5
      column :city_code,      String, null: false, size: 3
      column :hotel_code,     String, null: false, size: 3
      column :room_code,      String, null: false, size: 16
      column :room_grade,     String, size: 3
      column :room_type_code, String, size: 3
      column :room_name,      String, null: false, size: 240
      column :min_guests,     Integer, null: false
      column :max_guests,     Integer, null: false
      column :extra_bed,      String, size: 1
      column :extra_bed_type, String, size: 1
      column :size1,          String, size: 10
      column :size2,          String, size: 10
      column :size3,          String, size: 10
      column :size4,          String, size: 10
      column :size5,          String, size: 10
      column :size6,          String, size: 10
      column :amenities,      String, size: 100

      index :room_code
    end
  end
end
