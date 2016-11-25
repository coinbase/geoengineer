########################################################################
# Override to define recommended patterns of resource use
########################################################################
class GeoEngineer::Template
  include HasAttributes
  include HasResources

  def initialize(name, project, parameters = {})
    @project = project
    @name = name
    @environment = @project.environment
  end

  def resource(type, id, &block)
    return find_resource(type, id) unless block_given?
    resource = create_resource(type, id, &block)
    resource.template = self
    resource.project = @project
    resource.environment = @environment
    resource
  end

  # The resources that are passed to the block on instantiation
  # This can be overridden to specify the order of the templates resources
  def template_resources
    resources
  end
end
