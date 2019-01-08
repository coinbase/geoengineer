########################################################################
# HasSubResources provides methods for a object to contain subresources
########################################################################
module HasSubResources
  # This overrides assign_block from HasAttributes
  # when a block is passed to an attribute it becomes a SubResource
  def assign_block(name, *args, &block)
    sr = GeoEngineer::SubResource.new(self, name, &block)
    subresources << sr
    sr
  end

  def attribute_missing(name)
    all = false
    if name.start_with?('all_')
      name = name[4..-1]
      all = true
    end
    srl = subresources.select { |s| s._type == name.to_s }

    if srl.empty?
      return [] if all
      return nil
    else
      return srl if all
      return srl.first
    end
  end

  def subresources
    @_subresources = [] unless @_subresources
    @_subresources
  end

  def delete_subresources_where(&block)
    # Only leave sub resources that dont
    @_subresources = subresources.reject(&block)
  end

  def delete_all_subresources(type)
    @_subresources = subresources.select { |s| s._type != type.to_s }
  end
end
