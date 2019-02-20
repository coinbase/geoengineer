require 'json-schema'

# Node is a description of 1-many resources formally using GPS and JSON schema
class GeoEngineer::GPS::Node
  class NodeError < StandardError; end

  def self.meta?
    false
  end

  def meta?
    false
  end

  attr_reader :project, :environment, :configuration, :node_name, :attributes
  attr_accessor :all_nodes, :node_type

  def initialize(project, environment, configuration, node_name, attributes)
    @node_type = build_node_type
    @project = project
    @environment = environment
    @configuration = configuration
    @node_name = node_name
    @attributes = attributes
  end

  def match(project, environment, config, node_type, node_name)
    project_match(project, environment, config) && node_match(node_type, node_name)
  end

  def project_match(project, environment, config)
    (@project == project || project == "*") &&
      (@environment == environment || environment == "*") &&
      (@configuration == config || config == "*")
  end

  def node_match(node_type, node_name)
    (@node_type == node_type || node_type == "*") &&
      (@node_name == node_name || node_name == "*")
  end

  # from ActiveSupport
  def build_node_type
    self.class.node_type
  end

  def self.node_type
    class_name = self.name.split('::').last
    class_name.gsub(/::/, '/')
              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr("-", "_")
              .downcase
  end

  def project_org
    project.split("/")[0]
  end

  def project_name
    project.split("/")[1]
  end

  def validate
    # First we inject all the defaults
    # This errors because if an object is invalid it will not insert_defaults
    JSON::Validator.validate!(json_schema, attributes, { insert_defaults: true })

    # The node can then change/set some attributes
    defaults!

    # Must still conform to schema
    JSON::Validator.validate!(json_schema, attributes, { insert_defaults: true })
    validate_attributes
    # If it makes it this far it is true
    true
  rescue JSON::Schema::ValidationError => e
    attrs = "\nwith attributes:\n#{JSON.pretty_generate(attributes)}"
    schema = "\nfor schema \n#{JSON.pretty_generate(json_schema)}"

    raise NodeError, "\nSchema Error #{e} for #{node_id} #{attrs} #{schema}  "
  end

  def node_id
    [project, environment, configuration, node_type, node_name].compact.join(":")
  end

  def load_gps_file
    self.class.load_gps_file(project)
  end

  def self.load_gps_file(project)
    GeoEngineer::GPS.load_gps_file(GeoEngineer::GPS.singleton, "projects/#{project}.gps.yml")
  end

  # define_resource create three helper methods
  # 1. read method similar to attr_reader
  # 2. ref method which can be used
  # 3. create method which sets the resource with the correct ref
  def self.define_resource(type, name, id_lambda = nil)
    if id_lambda.nil?
      id_lambda = ->(prefix, project, environment, configuration, node_name) do
        resource_id(prefix, project, environment, configuration, node_name)
      end
    end

    self.define_ref_methods(type, name, id_lambda)
    self.define_read_methods(type, name, id_lambda)

    # Create Method
    create_method = "create_#{name}"
    define_method(create_method) do |project_obj|
      id = self.class.class_exec(name, project, environment, configuration, node_name, &id_lambda)
      resource = project_obj.resource(type, id) {}
      instance_variable_set("@#{name}", resource)
      resource
    end
  end

  def self.define_read_methods(type, name, id_lambda)
    read_method = name.to_s
    load_gps_file = ->(project) { load_gps_file(project) }

    define_method(read_method) do
      self.class.class_exec(project, &load_gps_file)
      instance_variable_get("@#{name}")
    end
  end

  def self.define_ref_methods(type, name, id_lambda)
    ref_method = "#{name}_ref"
    load_gps_file = ->(project) { load_gps_file(project) }

    define_method(ref_method) do |attribute = "id"|
      id = self.class.class_exec(name, project, environment, configuration, node_name, &id_lambda)
      self.class.class_exec(project, &load_gps_file)
      "${#{type}.#{id}.#{attribute}}"
    end

    # We also add this as a class method so we can create references without a node instance
    define_singleton_method(ref_method) do |project, environment, configuration, node_name, attribute = "id"|
      id = instance_exec(name, project, environment, configuration, node_name, &id_lambda)
      instance_exec(project, &load_gps_file)
      "${#{type}.#{id}.#{attribute}}"
    end
  end

  # If the config is the same an environment we can truncate some values
  # production_production is superflous in ids and such
  def default_config?
    self.class.default_config?(self.configuration, self.environment)
  end

  def self.default_config?(configuration, environment)
    configuration == environment
  end

  # A unique id for resources for this node
  def resource_id(prefix)
    self.class.resource_id(prefix, project, environment, configuration, node_name)
  end

  # A unique id for resources for this node
  def self.resource_id(prefix, project, environment, configuration, node_name)
    if default_config?(configuration, environment)
      [prefix, project, node_type, node_name]
    else
      [prefix, project, configuration, node_type, node_name]
    end.compact.join("_").tr("-", '_').tr("/", "_")
  end

  def json_file(path, binding_obj = nil)
    raise "file #{path} not found" unless File.file?(path)

    raw = File.open(path, "rb").read
    interpolated = ERB.new(raw).result(binding_obj).to_s

    # normalized output
    JSON.parse(interpolated)
  end

  ###
  # TO BE IMPLEMENTED BY NODE_TYPES
  ###

  # defines the preconditions and defaults fo use of this node
  def json_schema
    raise NotImplementedError
  end

  # create resources is used to create the resources needed
  def create_resources(project)
    raise NotImplementedError
  end

  # Defaults fills out some fields that require code not just JSON SCHAME
  def defaults!; end

  def validate_attributes; end

  ###
  # Query
  ###
  def query_schema(node_type = "[a-zA-Z0-9\\-_\\/\\*]*")
    qp = "[a-zA-Z0-9\\-_\\/\\*]*"

    {
      "type": "string",
      "pattern": "^(#{qp}):(#{qp}):(#{qp}):#{node_type}:(#{qp})$"
    }
  end

  def where_all(queries)
    queries.map { |q| where(q) }.flatten.uniq
  end

  def where(query)
    GeoEngineer::GPS.where(all_nodes, build_query(query))
  end

  def find(query)
    GeoEngineer::GPS.find(all_nodes, build_query(query))
  end

  def dereference(reference)
    GeoEngineer::GPS.dereference(all_nodes, build_reference(reference))
  end

  # the query can come in with defaults and be filled in
  def build_query(query)
    project, _, configuration, node_type, node_name = query.split(":")

    # Any empty/nil value is defaulted to nodes value
    # e.g/ :::service:main is a reference to the service main in the same project/env/config.
    project = @project             if project.to_s == ""
    # can ONLY query within the same environment

    configuration = @configuration if configuration.to_s == ""
    node_type = @node_type         if node_type.to_s == ""
    node_name = @node_name         if node_name.to_s == ""

    "#{project}:#{@environment}:#{configuration}:#{node_type}:#{node_name}"
  end

  def build_reference(reference)
    query, ref = reference.split("#")
    [build_query(query), ref].compact.join("#")
  end
end
