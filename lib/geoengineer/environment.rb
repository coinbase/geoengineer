
########################################################################
# An Environment is a group of projects, resources and attributes,
# build to create a terraform file.
# The goal of GeoEngineer is to build an environment that can be created.
#
# An environment has resources, has arbitrary attributes, validations and lifecycle hooks
########################################################################
class GeoEngineer::Environment
  include HasAttributes
  include HasResources
  include HasValidations
  include HasLifecycle

  attr_reader :name, :projects

  validate -> { validate_required_attributes([:region, :account_id]) }

  # Validate resources have unique attributes
  validate -> {
    resources = resources_of_type_grouped_by(&:terraform_name)

    resources.map do |klass, grouped_resources|
      grouped_resources
        .select { |k, v| v.length > 1 }
        .map { |k, v| "Non-unique type.id #{v.first.for_resource}" }
    end.flatten
  }

  validate -> {
    resources = resources_of_type_grouped_by(&:_terraform_id)

    resources.map do |klass, grouped_resources|
      grouped_resources
        .select { |k, v| v.length > 1 && !v.first._terraform_id.nil? }
        .map { |k, v| "Non-unique _terraform_id #{v.first._terraform_id} #{v.first.for_resource}" }
    end.flatten
  }

  validate -> {
    resources = resources_of_type_grouped_by(&:_geo_id)

    resources.map do |klass, grouped_resources|
      grouped_resources
        .select { |k, v| v.length > 1 }
        .map { |k, v| "Non-unique _geo_id #{v.first._geo_id} #{v.first.for_resource}" }
    end.flatten
  }

  # Validate all resources
  validate -> { resources.map(&:errors).flatten }

  # Validate all projects (which validate resources)
  validate -> { projects.map(&:errors).flatten }

  before :validation, -> { self.region = self.region || ENV['AWS_REGION'] }

  def initialize(name, &block)
    @name = name
    @projects = []
    @outputs = []
    self.send("#{name}?=", true) # e.g. staging?
    instance_exec(self, &block) if block_given?
  end

  def resource(type, id, &block)
    return find_resource(type, id) unless block_given?
    resource = create_resource(type, id, &block)
    resource.environment = self
    resource
  end

  def output(id, value, &block)
    output = GeoEngineer::Output.new(id, value, &block)
    @outputs << output
    output
  end

  def all_resources
    reses = resources
    @projects.each { |project| reses += project.all_resources }
    reses
  end

  # Factory for creating projects inside an environment
  def project(org, name, &block)
    # do not add the project a second time
    exists = @projects.select { |p| p.org == org && p.name == name }.first
    return exists if exists

    project = GeoEngineer::Project.new(org, name, self, &block)

    supported_environments = [project.environments].flatten
    # do not add the project if the project is not supported by this environment
    return NullObject.new unless supported_environments.include? @name

    @projects << project
    project
  end

  # DOT Methods
  # Given an attribute it tries to identify a dependency and return it
  def extract_dependencies(x)
    if x.is_a? Array
      x.map { |y| extract_dependencies(y) }.flatten
    elsif x.is_a?(String)
      res = self.find_resource_by_ref(x)
      return [res] if res
    elsif x.is_a?(GeoEngineer::Resource)
      return [x]
    end
    []
  end

  def depends_on(res)
    all_attributes = []
    all_attributes.concat res.attributes.values
    all_attributes.concat res.subresources.map { |sr| sr.attributes.values }.flatten
    dependencies = Set.new(all_attributes.map { |x| extract_dependencies(x) }.flatten)
    dependencies.delete(nil)
    dependencies
  end

  def to_dot
    str = ["digraph {"]
    str.concat(projects.map(&:to_dot))
    all_resources.each do |res|
      str << depends_on(res).map { |r| "  #{res.to_ref.inspect} -> #{r.to_ref.inspect}" }
    end
    str << " }"
    str.join("\n")
  end

  # Terraform Methods
  def to_terraform
    # Force preventing the destruction of any resource unless explicitly set
    # Hopefully this will stop accidentally the environment
    unless self.allow_destroy
      all_resources.each { |r|
        r.lifecycle {} unless r.lifecycle
        r.lifecycle.prevent_destroy = true
      }
    end

    tf_resources = all_resources.map(&:to_terraform)
    tf_resources += @outputs.compact.map(&:to_terraform)
    tf_resources.join("\n\n")
  end

  def to_terraform_json
    unless self.allow_destroy
      all_resources.each { |r|
        r.lifecycle {} unless r.lifecycle
        r.lifecycle.prevent_destroy = true
      }
    end

    h = { resource: json_resources }
    h[:output] = @outputs.map(&:to_terraform_json) unless @outputs.empty?
    h
  end

  def json_resources
    all_resources.each_with_object({}) do |r, c|
      c[r.type] ||= {}
      c[r.type][r.id] = r.to_terraform_json
      c
    end
  end

  def to_terraform_state
    reses = all_resources.select(&:_terraform_id) # _terraform_id must not be nil

    reses = reses.map { |r| { "#{r.type}.#{r.id}" => r.to_terraform_state() } }.reduce({}, :merge)

    {
      version: 1,
      serial: 1,
      modules: [
        {
          path: [:root],
          outputs: {},
          resources: reses
        }
      ]
    }
  end

  # This method looks into AWS for resources that are not yet codified
  def codified_resources(type)
    # managed resources have a remote resource
    res = self.resources_of_type(type).select { |r| !r.remote_resource.nil? }
    res.sort_by(&:terraform_name)
  end

  def uncodified_resources(type)
    # unmanaged resources have a remote resource without local_resource
    clazz = self.class.get_resource_class_from_type(type)
    res = clazz.fetch_remote_resources.select { |r| r.local_resource.nil? }
    res.sort_by(&:terraform_name)
  end
end
