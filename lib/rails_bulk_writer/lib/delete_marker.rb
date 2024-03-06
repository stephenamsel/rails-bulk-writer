module RailsBulkWriter

    class DeleteMarker < ActiveSupport::CurrentAttributes
        attribute :to_delete

        resets { to_delete = {} }
    end

    class CacheConfig < ActiveSupport::CurrentAttributes
        # using CurrentAttributes to keep it specific to sequential requests
        # With current Rails, this is equivalent to a sub-hash within the Thread.current

        attribute :cache_db_name

        resets {} # do not erase this data upon reset
    end
end