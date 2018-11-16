# NodesContext is a node collection wrapper that provides context to queries
class GeoEngineer::GPS::NodesContext
  def initialize(project, environment, configuration, nodes)
    @project = project
    @environment = environment
    @configuration = configuration
    @nodes = nodes
  end

  def where(query)
    GeoEngineer::GPS.where(@nodes, build_query(query))
  end

  def find(query)
    GeoEngineer::GPS.find(@nodes, build_query(query))
  end

  # the query can come in with defaults and be filled in
  def build_query(query)
    project, environment, configuration, node_type, node_name = query.split(":")

    # defaults
    project = @project if project.empty?
    environment = @environment if environment.empty?
    configuration = @configuration if configuration.empty?

    "#{project}:#{environment}:#{configuration}:#{node_type}:#{node_name}"
  end
end
