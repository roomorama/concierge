Hanami::Model.migration do
  change do
    # this changes the +background_workers+ table to now have two foreign keys:
    #
    # * +host_id+
    # * +supplier_id+
    #
    # For every record, one (exactly one) of the IDs above must be set. Therefore,
    # the non-null constraint on the existing +host_id+ column must be dropped.
    # The enforcement of having at least one non-null column among the two foreign
    # keys has to be performed at the application level (no longer at the database
    # level.)
    #
    # This is to support aggregated-type suppliers, where a single background
    # worker is created for the supplier, and the implementation is responsible
    # for synchronising all existing hosts - as opposed to the traditional,
    # recommended model where each host can be synchronised independently.

    alter_table :background_workers do
      set_column_allow_null :host_id
      add_foreign_key       :supplier_id, :suppliers
    end
  end
end
