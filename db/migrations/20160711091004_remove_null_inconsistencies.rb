# alters the foreignkey delcarations to drop the +on_delete: set_null+ option
# since that contradicts the +null: false+ option passed to those columns.

Hanami::Model.migration do
  up do
    alter_table :hosts do
      drop_foreign_key :supplier_id
      add_foreign_key  :supplier_id, :suppliers, null: false
    end

    alter_table :properties do
      drop_foreign_key :host_id
      add_foreign_key  :host_id, :hosts, null: false
    end

    alter_table :sync_processes do
      drop_foreign_key :host_id
      add_foreign_key  :host_id, :hosts, null: false
    end
  end

  down do
    alter_table :hosts do
      drop_foreign_key :supplier_id
      add_foreign_key  :supplier_id, :suppliers, on_delete: :set_null, null: false
    end

    alter_table :properties do
      drop_foreign_key :host_id
      add_foreign_key  :host_id, :hosts, on_delete: :set_null, null: false
    end

    alter_table :sync_processes do
      drop_foreign_key :host_id
      add_foreign_key  :host_id, :hosts, on_delete: :set_null, null: false
    end
  end

end
