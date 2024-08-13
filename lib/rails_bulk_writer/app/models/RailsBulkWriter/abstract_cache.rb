class RailsBulkWriter::AbstractCache < ActiveRecord::Base
    self.abstract_class true

    around_save :connect_to_thread_db
    around_destroy :connect_to_thread_db

    def connect_to_thread_db
        connected_to(database: thread_shard) do
            yield
        end
    end
    def thread_shard
        # get the name of the database for this Thread
        RailsBulkWriter::CacheConfig.cache_db_name
    end

    def dump_data
        out = nil
        connect_to_thread_db do
            out = self.all.map{|records| records.attributes.except(self.primary_key)}
            self.delete_all # uses Truncate optimizer for SQLite
        end
        out
    end
end