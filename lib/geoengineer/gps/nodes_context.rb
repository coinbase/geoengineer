# NodesContext is a node collection wrapper that provides context to queries
class GeoEngineer::GPS::NodesContext
  def initialize(project, environment, configuration, nodes, constants)
    @project = project
    @environment = environment
    @configuration = configuration
    @nodes = nodes
    @constants = constants
  end

  def finder
    @finder ||= GeoEngineer::GPS::Finder.new(@nodes, @constants, {
                                               project: @project,
                                               environment: @environment,
                                               configuration: @configuration
                                             })
  end

  def where(query)
    finder.where(query)
  end

  def find(query)
    finder.find(query)
  end
end
