require 'parallel'

########################################################################
# An Environment is a group of projects, resources and attributes,
# build to create a terraform file.
# The goal of GeoEngineer is to build an environment that can be created.
#
# An environment has resources, has arbitrary attributes, validations and lifecycle hooks
########################################################################
class GeoEngineer::Environment
  include HasAttributes
  include HasSubResources
  include HasResources
  include HasProjects
  include HasTemplates
  include HasValidations
  include HasLifecycle

  attr_reader :name

  # Validate resources have unique attributes
  validate -> {
    resources_of_type_grouped_by(&:terraform_name).map do |klass, grouped_resources|
      grouped_resources
        .select { |k, v| v.length > 1 }
        .map { |k, v| "Non-unique type.id #{v.first.for_resource}" }
    end.flatten
  }

  validate -> {
    resources_of_type_grouped_by(&:_terraform_id).map do |klass, grouped_resources|
      grouped_resources
        .select { |k, v| v.length > 1 && !v.first._terraform_id.nil? }
        .map { |k, v| "Non-unique _terraform_id #{v.first._terraform_id} #{v.first.for_resource}" }
    end.flatten
  }

  validate -> {
    resources_of_type_grouped_by(&:_geo_id).map do |klass, grouped_resources|
      grouped_resources
        .select { |k, v| v.length > 1 }
        .map { |k, v| "Non-unique _geo_id #{v.first._geo_id} #{v.first.for_resource}" }
    end.flatten
  }

  # Validate all projects (which validate resources)
  validate -> { projects.values.map(&:errors).flatten }

  # Validate all resources
  validate -> { all_resources.map(&:errors).flatten }

  before :validation, -> { self.region ||= ENV['AWS_REGION'] if ENV['AWS_REGION'] }

  def initialize(name, &block)
    @name = name
    @outputs = []
    @providers = []
    self.send("#{name}?=", true) # e.g. staging?
    instance_exec(self, &block) if block_given?
  end

  def project(org, name, &block)
    project = create_project(org, name, &block)
    supported_environments = [project.environments].flatten
    # do not add the project if the project is not supported by this environment
    return NullObject.new unless supported_environments.include?(@name)

    project
  end

  def resource(type, id, &block)
    return find_resource(type, id) unless block_given?

    resource = create_resource(type, id, &block)
    resource.environment = self
    resource
  end

  def provider(id, &block)
    provider = GeoEngineer::Provider.new(id, &block)
    @providers << provider
    provider
  end

  def find_provider(id_alias)
    @providers.find { |p| p.terraform_id == id_alias }
  end

  def output(id, value, &block)
    output = GeoEngineer::Output.new(id, value, &block)
    @outputs << output
    output
  end

  def all_resources
    [resources, all_template_resources, all_project_resources].flatten
  end

  # DOT Methods
  # Given an attribute it tries to identify a dependency and return it
  def extract_dependencies(x)
    return x.map { |y| extract_dependencies(y) }.flatten if x.is_a? Array
    return [x] if x.is_a?(GeoEngineer::Resource)

    if x.is_a?(String)
      res = find_resource_by_ref(x)
      return [res] if res
    end

    []
  end

  def depends_on(res)
    all_attributes = [res.attributes.values]
    all_attributes
      .concat(res.subresources.map { |sr| sr.attributes.values })
      .map { |attr| extract_dependencies(attr) }
      .flatten
      .compact
      .uniq
  end

  def to_dot
    str = ["digraph {", projects.values.map(&:to_dot)]
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
    tf_resources += @providers.compact.map(&:to_terraform)
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
    h[:provider] = @providers.map(&:to_terraform_json) unless @providers.empty?
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

    reses = Parallel.map(reses, { in_threads: Parallel.processor_count }) do |r|
      { "#{r.type}.#{r.id}" => r.to_terraform_state() }
    end.reduce({}, :merge)

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
    res = clazz.fetch_remote_resources(nil).select { |r| r.local_resource.nil? }
    res.sort_by(&:terraform_name)
  end
end
