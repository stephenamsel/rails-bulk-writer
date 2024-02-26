class RailsBulkWriter::AbstractCache < ActiveRecord::Base
    self.abstract_class true

    connects_to database: {reading: thread_shard, writing: thread_shard}

    def thread_shard
        # get the name of the database for this Thread
        ("#{RailsBulkWriter::CACHE_PREFIX}_#{}")
    end
end