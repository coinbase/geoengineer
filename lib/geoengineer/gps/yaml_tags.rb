
# !Ref dereferences value
# e.g. ::::asd#asd.arn will return the terraform value ${type.id.arn}
class Tag
  attr_reader :nodes, :constants
  attr_reader :node, :type, :value, :block

  def initialize(type, value, &block)
    @type = type
    @value = value
    @block = block
  end

  def constants=(constants)
    # Recursive for Tags in Tags
    HashUtils.map_values(@value) do |a|
      a.constants = self if a.respond_to?(:constants=)
      a
    end

    @constants = constants
  end

  def nodes=(nodes)
    # Recursive for Tags in Tags
    HashUtils.map_values(@value) do |a|
      a.nodes = self if a.respond_to?(:nodes=)
      a
    end

    @nodes = nodes
  end

  def to_json(options = nil)
    instance_exec(@value, &block)
  end

  def self.empty_str(str)
    return nil if str == ""
    str
  end
end


# Ref takes a query as input and replaces it with the value
YAML.add_domain_type("", "Ref") do |type, reference|
  Tag.new(type, reference) do |value|
    puts 'reference'
    puts reference
    puts reference.class
    puts "CONSTANTS #{!!@constants}"
    puts "NDOES #{!!self.nodes}"
    reference.to_json

    # # value is a refernce
    # components = reference.match(GeoEngineer::GPS::REFERENCE_SYNTAX)
    # unless components
    #   raise GeoEngineer::GPS::BadReferenceError, "'#{reference}' in #{node.node_id}"
    # end

    # # setup defaults for the values
    # project = Tag.empty_str(components["project"]) || node.project
    # environment = Tag.empty_str(components["environment"]) || node.environment
    # configuration = Tag.empty_str(components["configuration"]) || node.configuration
    # node_type = components["node_type"]
    # node_name = Tag.empty_str(components["node_name"]) || node.node_name
    # attribute = Tag.empty_str(components["attribute"]) || 'id'

    # clazz = GeoEngineer::GPS.find_node_class(components["node_type"])
    # method_name = "#{components['resource']}_ref"
    # unless clazz.respond_to?(method_name)
    #   raise GeoEngineer::GPS::BadReferenceError, "#{reference} does not have resource: #{components['resource']}"
    # end

    # clazz.send(method_name, project, environment, configuration, node_name, attribute)
  end
end

YAML.add_domain_type("", "Flatten") do |type, reference|
  raise "!Flatten must be on an Array" unless reference.is_a?(Array)
  Tag.new(type, reference) do |value|
    # to_json -> ruby (for embedded tags) -> flatten -> json
    HashUtils.json_dup(value).flatten.to_json
  end
end