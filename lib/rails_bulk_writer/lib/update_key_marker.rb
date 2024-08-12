module RailsBulkWriter

    class UpdateKeyMarker < ActiveSupport::CurrentAttributes
        attribute :updated

        resets { updated = {} }
    end


end