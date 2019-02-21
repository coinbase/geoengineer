
class Tag
  attr_reader :constants, :environment
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
    if self.node
      self.node.dereference!(reference).to_json
    else
      self.constants.dereference!(reference, @environment).to_json
    end
  end
end

YAML.add_domain_type("", "Flatten") do |type, reference|
  raise "!Flatten must be on an Array" unless reference.is_a?(Array)
  Tag.new(type, reference) do |value|
    # to_json -> ruby (for embedded tags) -> flatten -> json
    HashUtils.json_dup(value).flatten.to_json
  end
end