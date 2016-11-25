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

  # Overridden By Project and Environment
  def all_resources
    resources
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

  def resources_grouped_by
    all_resources.each_with_object({}) do |r, c|
      value = yield r
      c[value] ||= []
      c[value] << r
      c
    end
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
