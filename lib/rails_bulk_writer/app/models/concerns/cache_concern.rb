module RailsBulkWriter
    module CacheConcern
        extends ActiveSupport::CacheConcern

        included do
            around_save :save_to_cache
            around_destroy :mark_to_destroy
            before_commit :send_cache_to_db
            before_commit :delete_marked

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
                # TODO: Make this work with relations if possible. Otherwise, add a warning to use only Nested SQL
                # when write-reads are a concern
            end

            def save_to_cache
                # NO YIELD! THIS MUST COME LAST IN THE around_save CHAIN!
                cache_class.new(self.attributes).save
            end

            def send_cache_to_db
                AbstractCache.connect_to_thread_db do
                    cached_records = cache_class.all
                    self.class.bulk_import cached_records, on_duplicate_key_update: [self.class.primary_key.to_sym]
                    cache_class.delete_all # uses SQLite Truncate optimizer
                end
            end

            def mark_to_destroy
                DeleteMarker.to_delete[self.class.name] ||= []
                DeleteMarker.to_delete[self.class.name].push(self.id)
            end

            def delete_marked
                self.class.where(id: DeleteMarker.to_delete[self.class.name]).delete_all
            end

            def cache_class
                "#{RailsBulkWriter.CACHE_NAMESPACE}::#{self.name}".constantize
            end
        end

    end
end