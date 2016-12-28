########################################################################
# HasResources provides methods for a class to contain and query a set of resources
########################################################################
module HasResources
  def self.included(base)
    base.extend(ClassMethods)
  end

  # ClassMethods
  module ClassMethods
    def get_resource_class_from_type(type)
      c_name = type.split('_').collect(&:capitalize).join
      c_name = "GeoEngineer::Resources::#{c_name}"
      clazz = Object.const_defined?(c_name) ? Object.const_get(c_name) : GeoEngineer::Resource
      clazz
    end
  end

  def resources
    @_resources = [] unless @_resources
    @_resources
  end

  # Overridden By Template, Project and Environment,
  # requires explicit override to avoid easy mistakes
  def all_resources
    raise NotImplementedError, "Including class must override this method"
  end

  def find_resource(type, id)
    all_resources.select { |r| r.type == type && r.id == id }.first
  end

  def find_resource_by_ref(ref)
    return nil unless ref.start_with?("${")
    ref = ref.delete('${').delete('}')
    type, name = ref.split('.')
    find_resource(type, name)
  end

  # Returns: { value1: [ ], value2: [ ] }
  def resources_grouped_by(resources_to_group = all_resources)
    resources_to_group.each_with_object({}) do |r, c|
      value = yield r
      c[value] ||= []
      c[value] << r
      c
    end
  end

  # Returns: { type1: { value1: [ ] }, type2: { value2: [ ] } }
  def resources_of_type_grouped_by(&block)
    grouped = resources_grouped_by(all_resources, &:type)

    grouped_arr = grouped.map do |type, grouped_resources|
      [type, resources_grouped_by(grouped_resources, &block)]
    end

    grouped_arr.to_h
  end

  def resources_of_type(type)
    all_resources.select { |r| r.type == type }
  end

  # Factory to create resource and attach
  def create_resource(type, id, &block)
    # This will look for a class that is defined by the type so it can override functionality
    # For example, if `type='aws_security_group'` then the class would be `AwsSecurityGroup`
    clazz = self.class.get_resource_class_from_type(type)

    res = clazz.new(type, id, &block)
    resources << res # Add the resource
    res
  end
end
