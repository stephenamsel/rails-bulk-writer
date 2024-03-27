module RailsBulkWriter
    CACHE_NAMESPACE = "Cache"
end

ar_models = ObjectSpace.each_object.select do |obj| 
    obj.is_a?(Class) && obj.ancestors.include?(ActiveRecord::Base) 
end

ar_models.each do |ar_model|
    cache_model = "#{RailsBulkWriter.CACHE_NAMESPACE}::#{ar_model.name}"
    cache_model.constantize = Class.new(RailsBulkWriter::AbstractCache)
end
