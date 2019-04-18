require 'yaml'

# YamlTag allows use of Tags in GPS
class GeoEngineer::GPS::YamlTag
  include Comparable

  attr_reader :nodes, :constants, :context
  attr_reader :type, :value

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

  def initialize(type, value)
    @type = type
    @value = value
  end

  def context=(context)
    raise "Cannot change Tag Context from #{@context} to #{context}" if @context && @context != context
    GeoEngineer::GPS::YamlTag.add_tag_context(@value, { context: context }) # Recursive for Tags in Tags
    @context = context
  end

  def constants=(constants)
    GeoEngineer::GPS::YamlTag.add_tag_context(@value, { constants: constants }) # Recursive for Tags in Tags
    @constants = constants
  end

  def nodes=(nodes)
    GeoEngineer::GPS::YamlTag.add_tag_context(@value, { nodes: nodes }) # Recursive for Tags in Tags
    @nodes = nodes
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
    self.class.new(type, new_value)
  end

  # Override Methods
  def to_json(options = nil)
    raise NotImplementedError
  end

  def tag_name
    "!#{type.split('::')[1]}"
  end

  def encode_with(coder)
    coder.tag = tag_name
    coder.scalar = value
    coder
  end

  def ==(other)
    to_s == other.to_s
  end

  def <=>(other)
    return 0 if self == other
    self.to_s > other.to_s ? 1 : -1
  end

  def to_s
    value
  end

  def references
    raise NotImplementedError
  end
end

# !sub class
class GeoEngineer::GPS::YamlTag::Sub < GeoEngineer::GPS::YamlTag
  def all_queries
    value.scan(/{{(.*?)}}/).flatten.uniq
  end

  def to_json(options = nil)
    result_value = value.dup
    all_queries.each do |query|
      result = finder.dereference!(query, { auto_load: false })

      # Process result differently per type
      case result
      when Array
        result = result.to_json
      when Hash
        result = result.to_json
      end
      result_value.gsub!(/{{\s*#{query}\s*}}/, result)
    end

    result_value.to_json
  end

  def references
    all_queries.map do |query|
      components = query.match(GeoEngineer::GPS::Finder::NODE_REFERENCE_SYNTAX)
      next unless components
      finder.search_node_components(components)
    end.flatten.compact
  end
end

# !ref class
class GeoEngineer::GPS::YamlTag::Ref < GeoEngineer::GPS::YamlTag
  def to_json(options = nil)
    # do not automatically load the nodes referenced
    finder.dereference!(value, { auto_load: false }).to_json
  end

  def references
    components = value.match(GeoEngineer::GPS::Finder::NODE_REFERENCE_SYNTAX)
    return [] unless components
    finder.search_node_components(components)
  end
end

# !refs class
class GeoEngineer::GPS::YamlTag::Refs < GeoEngineer::GPS::YamlTag
  def to_json(options = nil)
    finder.dereference(value, { auto_load: false }).to_json
  end

  def references
    components = value.match(GeoEngineer::GPS::Finder::NODE_REFERENCE_SYNTAX)
    return [] unless components
    finder.search_node_components(components)
  end
end

# !flatten class
class GeoEngineer::GPS::YamlTag::Flatten < GeoEngineer::GPS::YamlTag
  def to_json(options = nil)
    # to_json -> ruby (for embedded tags) -> flatten -> json
    HashUtils.json_dup(value).flatten.to_json
  end

  def encode_with(coder)
    coder.tag = tag_name
    coder.seq = value
    coder
  end

  def ==(other)
    self.to_yaml == other.to_yaml
  end

  def <=>(other)
    return 0 unless other.is_a?(self.class) || other.is_a?(Array)
    return 0 if value.size == other.value.size
    value.size > other.value.size ? 1 : -1
  end

  def references
    refs = []
    value.each do |a|
      next unless a.is_a? GeoEngineer::GPS::YamlTag
      refs += a.references()
    end
    refs.flatten.uniq
  end
end

# sub takes a string as input that contains queries in {{}} and replaces with their value
YAML.add_domain_type("", "sub") do |type, str|
  # If a string starts with `:` in ruby it treats it as a symbol
  # to make references we add back a `:` to the string
  str = ":#{str}" if str.is_a?(Symbol)
  GeoEngineer::GPS::YamlTag::Sub.new(type, str)
end

# Ref takes a query as input and replaces it with the value
YAML.add_domain_type("", "ref") do |type, reference|
  # If a string starts with `:` in ruby it treats it as a symbol
  # to make references we add back a `:` to the string
  reference = ":#{reference}" if reference.is_a?(Symbol)
  GeoEngineer::GPS::YamlTag::Ref.new(type, reference)
end

YAML.add_domain_type("", "refs") do |type, reference|
  # If a string starts with `:` in ruby it treats it as a symbol
  # to make references we add back a `:` to the string
  reference = ":#{reference}" if reference.is_a?(Symbol)
  GeoEngineer::GPS::YamlTag::Refs.new(type, reference)
end

YAML.add_domain_type("", "flatten") do |type, list|
  raise "!flatten must be on an Array" unless list.is_a?(Array)
  GeoEngineer::GPS::YamlTag::Flatten.new(type, list)
end
