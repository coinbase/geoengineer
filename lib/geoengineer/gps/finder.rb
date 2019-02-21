# Finder is a class that contains all the logic to find a GPS coordinate
class GeoEngineer::GPS::Finder
  class NotFoundError < StandardError; end
  class NotUniqueError < StandardError; end
  class BadQueryError < StandardError; end
  class BadReferenceError < StandardError; end

  NODE_QUERY_SYNTAX = %r{
    ^
    (?<project>[a-zA-Z0-9\-_/*]*):         # Match the project name (optional)
    (?<environment>[a-zA-Z0-9\-_*]*):      # Match the environment (optional)
    (?<configuration>[a-zA-Z0-9\-_*]*):    # Match the configuration (optional)
    (?<node_type>[a-zA-Z0-9\-_*]+):         # Match the node_type (required), does not support `*`
    (?<node_name>[a-zA-Z0-9\-_/*.]*)       # Match the node_name (required)
    $
  }x

  NODE_REFERENCE_SYNTAX = %r{
    ^(?!arn:aws:)                           # Make sure we do not match AWS ARN's
    (?<project>[a-zA-Z0-9\-_/*]*):         # Match the project name (optional)
    (?<environment>[a-zA-Z0-9\-_*]*):      # Match the environment (optional)
    (?<configuration>[a-zA-Z0-9\-_*]*):    # Match the configuration (optional)
    (?<node_type>[a-zA-Z0-9\-_]+):         # Match the node_type (required), does not support `*`
    (?<node_name>[a-zA-Z0-9\-_/*.]+)       # Match the node_name (required)
    [#](?<resource>[a-zA-Z0-9_]+)         # Match the node resource (optional)
    ([.](?<attribute>[a-zA-Z0-9_]+))?     # Match the resource attribute, requires resource (optional)
    $
  }x

  attr_reader :nodes
  attr_reader :project, :environment, :configuration, :node_type, :node_name

  def initialize(nodes, context = {})
    @nodes = nodes
    # extract the context
    @project = context[:project]
    @environment = context[:environment]
    @configuration = context[:configuration]
    @node_type = context[:node_type]
    @node_name = context[:node_name]
  end

  # where returns multiple nodes
  def where(query)
    components = query.match(NODE_QUERY_SYNTAX)

    raise BadReferenceError, "for reference: #{query}" unless components
    search_nodes(
      components["project"],
      components["environment"],
      components["configuration"],
      components["node_type"],
      components["node_name"]
    )
  end

  # find a node from nodes
  def find(query)
    query_nodes = where(query)
    raise NotFoundError, "for query #{query}" if query_nodes.empty?
    raise NotUniqueError, "for query #{query}" if query_nodes.length > 1
    query_nodes.first
  end

  def dereference(reference)
    components = reference.match(NODE_REFERENCE_SYNTAX)
    raise BadReferenceError, "for reference: #{reference}" unless components

    nodes = search_nodes(
      components["project"],
      components["environment"],
      components["configuration"],
      components["node_type"],
      components["node_name"]
    )

    raise NotFoundError, "for reference: #{reference}" if nodes.empty?
    method_name = "#{components['resource']}_ref"
    attribute = components["attribute"] || 'id'

    nodes.map do |node|
      unless node.respond_to?(method_name)
        raise BadReferenceError, "#{reference} does not have resource: #{components['resource']}"
      end

      node.send(method_name, attribute)
    end
  end

  def search_nodes(project, environment, configuration, node_type, node_name)
    project = @project             if project.empty?
    environment = @environment     if environment.empty?
    configuration = @configuration if configuration.empty?
    node_type = @node_type         if node_type.empty?
    node_name = @node_name         if node_name.empty?

    nodes.select { |n| n.match(project, environment, configuration, node_type, node_name) }
  end
end
