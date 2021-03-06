Hanami::Model.migration do
  change do
    create_table :background_workers do
      primary_key :id

      foreign_key :host_id, :hosts, null: false

      column :next_run_at, Time
      column :interval,    Integer, null: false
      column :type,        String,  null: false
      column :status,      String,  null: false

      column :created_at, Time, null: false
      column :updated_at, Time, null: false

      # only one worker type per host should exist
      index [:host_id, :type], unique: true
    end
  end
end
