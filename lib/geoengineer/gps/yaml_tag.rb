
# YamlTag allows use of Tags in GPS
class GeoEngineer::GPS::YamlTag
  attr_reader :nodes, :constants, :context
  attr_reader :type, :value, :block

  def self.add_tag_context(values, nodes: nil, constants: nil, context: nil)
    HashUtils.map_values(values) do |a|
      next a unless a.is_a? GeoEngineer::GPS::YamlTag
      # Only overide values if provided
      a.nodes = nodes if nodes
      a.constants = constants if constants
      a.context = context if context
      a
    end
  end

  def initialize(type, value, &block)
    @type = type
    @value = value
    @block = block
  end

  def context=(context)
    raise "Cannot change Tag Context from #{@context} to #{context}" if @context
    GeoEngineer::GPS::YamlTag.add_tag_context(@value, { context: context }) # Recursive for Tags in Tags
    @context = context
  end

  def constants=(constants)
    GeoEngineer::GPS::YamlTag.add_tag_context(@value, { constants: constants }) # Recursive for Tags in Tags
    @constants = constants
  end

  def nodes=(nodes)
    GeoEngineer::GPS::YamlTag.add_tag_context(@nodes, { nodes: nodes }) # Recursive for Tags in Tags
    @nodes = nodes
  end

  def to_json(options = nil)
    instance_exec(value, &block)
  end

  def self.empty_str(str)
    return nil if str == ""
    str
  end

  def finder
    @finder ||= GeoEngineer::GPS::Finder.new(nodes, constants, context || {})
  end

  # Force the dup
  def dup
    new_value = HashUtils.deep_dup(value)
    GeoEngineer::GPS::YamlTag.new(type, new_value, &block)
  end
end

# Ref takes a query as input and replaces it with the value
YAML.add_domain_type("", "ref") do |type, reference|
  # If a string starts with `:` in ruby it treats it as a symbol
  # to make references we add back a `:` to the string
  reference = ":#{reference}" if reference.is_a?(Symbol)
  GeoEngineer::GPS::YamlTag.new(type, reference) do |value|
    finder.dereference!(reference).to_json
  end
end

YAML.add_domain_type("", "refs") do |type, reference|
  # If a string starts with `:` in ruby it treats it as a symbol
  # to make references we add back a `:` to the string
  reference = ":#{reference}" if reference.is_a?(Symbol)
  GeoEngineer::GPS::YamlTag.new(type, reference) do |value|
    finder.dereference(reference).to_json
  end
end

YAML.add_domain_type("", "flatten") do |type, reference|
  raise "!Flatten must be on an Array" unless reference.is_a?(Array)
  GeoEngineer::GPS::YamlTag.new(type, reference) do |value|
    # to_json -> ruby (for embedded tags) -> flatten -> json
    HashUtils.json_dup(value).flatten.to_json
  end
end
