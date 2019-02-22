
class Tag
  attr_accessor :environment
  attr_reader :nodes, :constants, :node
  attr_reader :type, :value, :block

  def initialize(type, value, &block)
    @type = type
    @value = value
    @block = block
  end

  def environment=(environment)
    raise "Cannot change Tag Environemtn from #{@environment} to #{environment}" if @environment
    # Recursive for Tags in Tags
    HashUtils.map_values(@value) do |a|
      a.environment = environment if a.respond_to?(:environment=)
      a
    end

    @environment = environment
  end

  def constants=(constants)
    # Recursive for Tags in Tags
    HashUtils.map_values(value) do |a|
      a.constants = constants if a.respond_to?(:constants=)
      a
    end

    @constants = constants
  end

  def nodes=(nodes)
    # Recursive for Tags in Tags
    HashUtils.map_values(value) do |a|
      a.nodes = nodes if a.respond_to?(:nodes=)
      a
    end

    @nodes = nodes
  end

  def node=(node)
    # Recursive for Tags in Tags
    HashUtils.map_values(value) do |a|
      a.node = node if a.respond_to?(:node=)
      a
    end

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
    if node
      @finder ||= GeoEngineer::GPS::Finder.new(nodes, constants, {
                                               project: node.project,
                                               environment: node.environment,
                                               configuration: node.configuration,
                                               node_type: node.node_type,
                                               node_name: node.node_name
                                             })
    else
      @finder ||= GeoEngineer::GPS::Finder.new(nodes, constants, {
        environment: environment
      })
    end
  end

  # Force the dup
  def dup
    new_value = HashUtils.deep_dup(value)
    Tag.new(type, new_value, &block)
  end
end


# Ref takes a query as input and replaces it with the value
YAML.add_domain_type("", "Ref") do |type, reference|
  Tag.new(type, reference) do |value|
    finder.dereference!(reference).to_json
  end
end

YAML.add_domain_type("", "Flatten") do |type, reference|
  raise "!Flatten must be on an Array" unless reference.is_a?(Array)
  Tag.new(type, reference) do |value|
    # to_json -> ruby (for embedded tags) -> flatten -> json
    HashUtils.json_dup(value).flatten.to_json
  end
end