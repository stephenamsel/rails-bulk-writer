module RailsBulkWriter
    module CacheConcern
        extends ActiveSupport::CacheConcern

        included do
            around_save :save_to_cache, unless: { CacheConcern.changing_keys(self) }
            around_destroy :mark_to_destroy
            before_commit :send_cache_to_db
            before_commit :delete_marked
            before_update :mark_update, if: { CacheConcern.changing_keys(self) }

            FOREIGN_KEY_FIELDS = reflections.
                select{ |n, r| r.macro == :belongs_to }.
                map{ |name, reflection| reflection.foreign_key.to_sym }


            def load
                from_primary = super
                from_cache = nil
                use_primary = (DeleteMarker.to_delete[self.class.name] || []) | 
                    (UpdateKeyMarker.updated[self.class.name] || [])

                AbstractCache.connected_to(role: writing, database: AbstractCache.thread_shard) do
                    from_cache = AbstractCache.execute(self.to_sql)
                        .where.not(id: use_primary)
                        .group_by{ |m| m[self.primary_key.to_sym] }
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

            def mark_update
                UpdateKeyMarker.updated[self.class.name] ||= []
                UpdateKeyMarker.updated[self.class.name].push(self.id)
            end

            def delete_marked
                self.class.where(id: DeleteMarker.to_delete[self.class.name]).delete_all
            end

            def cache_class
                "#{RailsBulkWriter.CACHE_NAMESPACE}::#{self.name}".constantize
            end
        end

        def changing_keys(obj)
            return true unless obj.class::FOREIGN_KEY_FIELDS.defined?

            (
                obj.changes.keys.map{ |attr| attr.to_sym } &
                obj.class::FOREIGN_KEY_FIELDS
            ).present?
        end

        module_function :changing_keys

    end
end