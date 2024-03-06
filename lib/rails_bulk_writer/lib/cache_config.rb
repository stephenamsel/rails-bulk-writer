module RailsBulkWriter
    class CacheConfig < ActiveSupport::CurrentAttributes
        # using CurrentAttributes to keep it specific to sequential requests
        # With current Rails, this is equivalent to a sub-hash within the Thread.current

        attribute :cache_db_name
        cache_db_name = SqliteCache.generate_cache_db
        resets {} # do not erase this data upon reset
    end
end