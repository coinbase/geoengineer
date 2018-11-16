require 'json-schema'

# Node is a description of 1-many resources formally using GPS and JSON schema
class GeoEngineer::GPS::Node
  class NodeError < StandardError; end

  attr_reader :project, :environment, :configuration, :node_type, :node_name, :attributes
  attr_accessor :all_nodes

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
    class_name = self.class.name.split('::').last
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
  rescue JSON::Schema::ValidationError => e
    attrs = "\nwith attributes:\n#{JSON.pretty_generate(attributes)}"
    schema = "\nfor schema \n#{JSON.pretty_generate(json_schema)}"

    raise NodeError, "\nSchema Error #{e} for #{node_id} #{attrs} #{schema}  "
  end

  def node_id
    [project, environment, configuration, node_type, node_name].compact.join("::")
  end

  # define_resource create three helper methods
  # 1. read method similar to attr_reader
  # 2. ref method which can be used
  # 3. create method which sets the resource with the correct ref
  def self.define_resource(type, name, id_lambda = nil)
    id_lambda = -> { resource_id(name) } if id_lambda.nil?
    read_method = name.to_s
    ref_method = "#{name}_ref"
    create_method = "create_#{name}"

    define_method(read_method) do
      instance_variable_get("@#{name}")
    end

    define_method(create_method) do |project|
      id = instance_exec(&id_lambda)
      resource = project.resource(type, id) {}
      instance_variable_set("@#{name}", resource)
      resource
    end

    define_method(ref_method) do |attribute = "id"|
      id = instance_exec(&id_lambda)
      "${#{type}.#{id}.#{attribute}}"
    end
  end

  # If the config is the same an environment we can truncate some values
  # production_production is superflous in ids and such
  def default_config?
    configuration == environment
  end

  # A unique id for resources for this node
  def resource_id(prefix)
    if default_config?
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

  ###
  # Query
  ###
  def query_schema(node_type="[a-zA-Z0-9\\-_\\/\\*]*")
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
end
