########################################################################
# Projects are groups of resources used to organize and validate.
#
# A Project contains resources, has arbitrary attributes and validation rules
########################################################################
class GeoEngineer::Project
  include HasAttributes
  include HasResources
  include HasValidations

  attr_accessor :org, :name
  attr_reader :templates
  attr_reader :environment

  validate -> { environments.nil? ? "Project #{full_name} must have an environment" : nil }
  validate -> { all_resources.map(&:errors).flatten }

  def initialize(org, name, environment, &block)
    @org = org
    @name = name
    @environment = environment
    @templates = {}
    instance_exec(self, &block) if block_given?
  end

  def full_id_name
    "#{org}_#{name}".tr('-', '_')
  end

  def full_name
    "#{org}/#{name}"
  end

  def resource(type, id, &block)
    return find_resource(type, id) unless block_given?
    resource = create_resource(type, id, &block)
    resource.project = self
    resource.environment = @environment
    resource
  end

  def all_resources
    reses = resources
    @templates.each { |name, template| reses += template.all_resources }
    reses
  end

  def find_template(type)
    clazz_name = type.split('_').collect(&:capitalize).join
    return Object.const_get(clazz_name) if Object.const_defined? clazz_name

    module_clazz = "GeoEngineer::Templates::#{clazz_name}"
    return Object.const_get(module_clazz) if Object.const_defined? module_clazz

    throw "undefined template '#{type}' for '#{clazz_name}' or 'GeoEngineer::#{clazz_name}'"
  end

  def from_template(type, name, parameters = {}, &block)
    throw "Template '#{name}' already defined for project #{full_name}" if @templates[name]
    clazz = find_template(type)
    template = clazz.new(name, self, parameters)
    @templates[name] = template
    template.instance_exec(*template.template_resources, &block) if block_given?
    template
  end

  # dot method
  def to_dot
    str = ["  subgraph \"cluster_#{full_id_name}\" {"]
    str << "    style = filled; color = lightgrey;"
    str << "    label = <<B><FONT POINT-SIZE=\"24.0\">#{full_name}</FONT></B>>"
    nodes = all_resources.map do |res|
      "    node [label=#{res.short_name.inspect}, shape=\"box\"] #{res.to_ref.inspect};"
    end
    str << nodes
    str << "  }"
    str.join(" // #{full_name} \n")
  end
end
