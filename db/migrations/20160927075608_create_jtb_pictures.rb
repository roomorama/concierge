Hanami::Model.migration do
  change do
    create_table :jtb_pictures do
      primary_key [:language, :city_code, :hotel_code, :sequence]
      column :language,   String, null: false, size: 5
      column :city_code,  String, null: false, size: 3
      column :hotel_code, String, null: false, size: 16
      column :sequence,   Integer, null: false
      column :category,   String, null: false, size: 3
      column :room_code,  String, size: 16
      column :url,        String, null: false, size: 80
      column :comments,   String, text: true
    end
  end
end
