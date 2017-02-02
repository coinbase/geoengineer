########################################################################
# Override to define recommended patterns of resource use
########################################################################
class GeoEngineer::Template
  include HasAttributes
  include HasResources

  attr_accessor :name, :parameters

  def initialize(name, parent, parameters = {})
    @name = name
    @parameters = parameters
    case parent
    when GeoEngineer::Project then add_project_attributes(parent)
    when GeoEngineer::Environment then add_env_attributes(parent)
    end
  end

  # Helper method to accomodate different parents
  def add_project_attributes(project)
    @project = project
    @environment = project.environment
  end

  def add_env_attributes(environment)
    @environment = environment
  end

  def resource(type, id, &block)
    return find_resource(type, id) unless block_given?
    resource = create_resource(type, id, &block)
    resource.template = self
    resource.environment = @environment
    resource.project = @project if @project
    resource
  end

  def all_resources
    resources
  end

  # The resources that are passed to the block on instantiation
  # This can be overridden to specify the order of the templates resources
  def template_resources
    resources
  end
end
