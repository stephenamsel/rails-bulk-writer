module RailsBulkWriter
    module CacheConcern
        extends ActiveSupport::CacheConcern

        included do
            around_save :save_to_cache
            around_destroy :mark_to_destroy
            before_commit :send_cache_to_db

            def load
                from_primary = super
                from_cache = nil
                AbstractCache.connected_to(role: writing, database: AbstractCache.thread_shard) do
                    from_cache = AbstractCache.execute(self.to_sql).group_by{ |m| m[self.primary_key.to_sym] }
                end
                    
                from_cache.each do |key, value|
                    # they should be 1-element arrays
                    from_cache[key] = value.first 
                end

                # replace values with new ones when reading values written in the same transaction
                from_primary.select(|m| m[self.primary_key]).each do |model|
                    model.attributes = model.attributes.merge(from_cache[model[self.primary_key]].attributes)
                end
            end

            def save_to_cache
                # NO YIELD! THIS MUST COME LAST IN THE around_save CHAIN!
                cache_class.new(self.attributes).save
            end

            def send_cache_to_db
                
            end

            def cache_class
                "#{RailsBulkWriter.CACHE_NAMESPACE}::#{self.name}".constantize
            end
        end

    end
end