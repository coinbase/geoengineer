# Deref is a class that contains the dereferning logic
class GeoEngineer::GPS::Deref
  NODE_REFERENCE_SYNTAX = %r{
    ^(?!arn:aws:)                           # Make sure we do not match AWS ARN's
    (?<project>[a-zA-Z0-9\-_/*]*):         # Match the project name (optional)
    (?<environment>[a-zA-Z0-9\-_*]*):      # Match the environment (optional)
    (?<configuration>[a-zA-Z0-9\-_*]*):    # Match the configuration (optional)
    (?<node_type>[a-zA-Z0-9\-_]+):         # Match the node_type (required), does not support `*`
    (?<node_name>[a-zA-Z0-9\-_/*.]+)       # Match the node_name (required)
    (                                       # The #<resource>.<attribute> is optional
      [#](?<resource>[a-zA-Z0-9_]+)         # Match the node resource (optional)
      ([.](?<attribute>[a-zA-Z0-9_]+))?     # Match the resource attribute, requires resource (optional)
    )?
    $
  }

  attr_reader :nodes, :constants
  def initialize(nodes, constants)
    @nodes = nodes
    @constants = constants
  end

  # dereference takes a node or constant reference and returns the value described as a list
  def dereference(reference)
    components = reference.match(NODE_REFERENCE_SYNTAX)
    return reference unless components

    query = query_from_reference(reference)
    nodes = GeoEngineer::GPS.where(nodes, query)
    raise NotFoundError, "for reference: #{reference}" if nodes.empty?

    nodes.map do |node|
      next node unless components["resource"]
      method_name = "#{components['resource']}_ref"
      attribute = components["attribute"] || 'id'

      unless node.respond_to?(method_name)
        raise BadReferenceError, "#{query} does not have resource: #{components['resource']}"
      end

      node.send(method_name, attribute)
    end
  end

  # dereference! returns exactly one value to a reference and errors if none exist
  def dereference!(reference)
    dereferenced = dereference(reference)
    raise BadReferenceError, "Reference #{reference} not found" if dereferenced.empty?
    raise BadReferenceError, "Reference #{reference} found to many items (#{dereferenced.size})" unless dereferenced.size == 1
    dereferenced.first
  end

  def query_from_reference(reference)
    components = reference.match(NODE_REFERENCE_SYNTAX)
    [
      components["project"],
      components["environment"],
      components["configuration"],
      components["node_type"],
      components["node_name"]
    ].join(":")
  end
end