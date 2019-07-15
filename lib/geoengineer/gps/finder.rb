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
    (?<node_type>[a-zA-Z0-9\-_*]+):        # Match the node_type (required)
    (?<node_name>[a-zA-Z0-9\-_/*.]*)       # Match the node_name (optional)
    $
  }x

  CONSTANT_REFERENCE_SYNTAX = %r{
    ^
    constant:                             # Hard coding the
    (?<environment>[a-zA-Z0-9\-_*]*):      # Match the environment (optional)
    (?<attribute>[a-zA-Z0-9\-_/?*.]+)       # Match the node_name (required)
    $
  }x

  CONTEXT_REFERENCE_SYNTAX = %r{
    ^
    context:
    (?<value>(project|environment|configuration|node_type|node_name)) # Match the context value (required)
    $
  }x

  NODE_REFERENCE_SYNTAX = %r{
    ^(?!arn:aws:)                          # Make sure we do not match AWS ARN's
    (?<project>[a-zA-Z0-9\-_/*]*):         # Match the project name (optional)
    (?<environment>[a-zA-Z0-9\-_*]*):      # Match the environment (optional)
    (?<configuration>[a-zA-Z0-9\-_*]*):    # Match the configuration (optional)
    (?<node_type>[a-zA-Z0-9\-_]+):         # Match the node_type (required), does not support `*`
    (?<node_name>[a-zA-Z0-9\-_/*.]+)       # Match the node_name (required)
    [#](?<resource>[a-zA-Z0-9_]+)          # Match the node resource (required)
    ([.](?<attribute>[a-zA-Z0-9_]+))?      # Match the resource attribute, requires resource (optional)
    $
  }x

  attr_reader :nodes, :constants
  attr_reader :project, :environment, :configuration, :node_type, :node_name

  def self.build_nodes_lookup_hash(nodes_list)
    nodes_id_hash = {}
    nodes_list.each { |node| nodes_id_hash[node.node_id] = node }
    nodes_id_hash
  end

  def initialize(nodes, constants, context = {})
    @nodes = if nodes.is_a?(Array)
               GeoEngineer::GPS::Finder.build_nodes_lookup_hash(nodes)
             else
               nodes
             end

    @constants = constants

    # extract the context
    @context = context
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
    search_node_components(components)
  end

  # find a node from nodes
  def find(query)
    query_nodes = where(query)
    raise NotFoundError, "for query #{query}" if query_nodes.empty?
    raise NotUniqueError, "for query #{query}" if query_nodes.length > 1
    query_nodes.first
  end

  def dereference!(reference, auto_load: true)
    refs = dereference(reference, { auto_load: auto_load })
    raise NotFoundError, "for reference #{reference}" if refs.empty?
    raise NotUniqueError, "for reference #{reference}" if refs.length > 1
    refs.first
  end

  def dereference(reference, auto_load: true)
    nodes_components = reference.match(NODE_REFERENCE_SYNTAX)
    constants_components = reference.match(CONSTANT_REFERENCE_SYNTAX)
    context_components = reference.match(CONTEXT_REFERENCE_SYNTAX)

    return node_dereference(reference, nodes_components, { auto_load: auto_load }) if nodes_components
    return constants_dereference(reference, constants_components) if constants_components
    return context_dereference(reference, context_components) if context_components

    raise BadReferenceError, "for reference: #{reference}"
  end

  def node_dereference(reference, components, auto_load: true)
    nodes = search_node_components(components)

    return [] if nodes.empty?
    method_name = "#{components['resource']}_ref"
    attribute = components["attribute"] || 'id'

    nodes.map do |node|
      unless node.respond_to?(method_name)
        raise BadReferenceError, "#{reference} does not have resource: #{components['resource']}"
      end
      node.send(method_name, attribute, auto_load)
    end
  end

  def constants_dereference(reference, components)
    environment = components["environment"]
    environment = @environment if environment.empty?

    attribute = components["attribute"]
    con = constants.dereference(environment, attribute)
    raise NotFoundError, "#{reference} not found" if con.nil?
    [con] # required return of array
  end

  def context_dereference(reference, components)
    value = components["value"]
    con = @context[value.to_sym]
    raise NotFoundError, "#{reference} not found" if con.nil? || con.empty?
    [con]
  end

  def search_node_components(components)
    search_nodes_with_defaults(
      components["project"],
      components["environment"],
      components["configuration"],
      components["node_type"],
      components["node_name"]
    )
  end

  def search_nodes_with_defaults(project, environment, configuration, node_type, node_name)
    project = @project             if project.empty?
    environment = @environment     if environment.empty?
    configuration = @configuration if configuration.empty?
    node_type = @node_type         if node_type.empty?
    node_name = @node_name         if node_name.empty?

    search_nodes(project, environment, configuration, node_type, node_name)
  end

  def search_nodes(project, environment, configuration, node_type, node_name)
    node_id = [project, environment, configuration, node_type, node_name].compact.join(":")

    if node_id.include?("*")
      # TODO: allow lookup hash to also *
      nodes.values.select { |n| n.match(project, environment, configuration, node_type, node_name) }
    else
      # if we have an exact query without * we can use a lookup hash
      [nodes[node_id]].compact # must return list
    end
  end
end
