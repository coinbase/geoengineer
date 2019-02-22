class GeoEngineer::GPS::YamlTag
  attr_reader :nodes, :constants, :node, :environment
  attr_reader :type, :value, :block

  def self.add_tag_values(values, nodes: nil, constants: nil, node: nil, environment: nil)
    HashUtils.map_values(values) do |a|
      a.nodes = nodes if nodes && a.respond_to?(:nodes=)
      a.node = node if node && a.respond_to?(:node=)
      a.constants = constants if constants && a.respond_to?(:constants=)
      a.environment = environment if environment && a.respond_to?(:environment=)
      a
    end
  end

  def initialize(type, value, &block)
    @type = type
    @value = value
    @block = block
  end

  def environment=(environment)
    raise "Cannot change Tag Environemtn from #{@environment} to #{environment}" if @environment
    GeoEngineer::GPS::YamlTag.add_tag_values(@value, environment: environment) # Recursive for Tags in Tags
    @environment = environment
  end

  def constants=(constants)
    GeoEngineer::GPS::YamlTag.add_tag_values(@value, constants: constants) # Recursive for Tags in Tags
    @constants = constants
  end

  def nodes=(nodes)
    GeoEngineer::GPS::YamlTag.add_tag_values(@nodes, nodes: nodes) # Recursive for Tags in Tags
    @nodes = nodes
  end

  def node=(node)
    GeoEngineer::GPS::YamlTag.add_tag_values(@node, node: node) # Recursive for Tags in Tags
    @node = node
  end

  def to_json(options = nil)
    instance_exec(value, &block)
  end

  def self.empty_str(str)
    return nil if str == ""
    str
  end

  def finder
    context = if node
      {
        project: node.project,
        environment: node.environment,
        configuration: node.configuration,
        node_type: node.node_type,
        node_name: node.node_name
      }
    else
      { environment: environment }
    end
    @finder ||= GeoEngineer::GPS::Finder.new(nodes, constants, context)
  end

  # Force the dup
  def dup
    new_value = HashUtils.deep_dup(value)
    GeoEngineer::GPS::YamlTag.new(type, new_value, &block)
  end
end


# Ref takes a query as input and replaces it with the value
YAML.add_domain_type("", "Ref") do |type, reference|
  GeoEngineer::GPS::YamlTag.new(type, reference) do |value|
    finder.dereference!(reference).to_json
  end
end

YAML.add_domain_type("", "Flatten") do |type, reference|
  raise "!Flatten must be on an Array" unless reference.is_a?(Array)
  GeoEngineer::GPS::YamlTag.new(type, reference) do |value|
    # to_json -> ruby (for embedded tags) -> flatten -> json
    HashUtils.json_dup(value).flatten.to_json
  end
end