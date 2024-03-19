module RailsBulkWriter

    class DeleteMarker < ActiveSupport::CurrentAttributes
        attribute :to_delete

        resets { to_delete = {} }
    end


end