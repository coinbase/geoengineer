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
  attr_reader :initial_attributes, :depends_on

  attr_accessor :all_nodes, :node_type, :constants

  def initialize(project, environment, configuration, node_name, attributes)
    @node_type = build_node_type
    @project = project
    @environment = environment
    @configuration = configuration
    @node_name = node_name
    @attributes = attributes
    @initial_attributes = HashUtils.deep_dup(attributes)

    # depends_on is a list of nodes that are to be loaded if this node is loaded
    @depends_on = []
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

  def set_values(nodes, constants)
    self.all_nodes = nodes
    self.constants = constants
    GeoEngineer::GPS::YamlTag.add_tag_context(self.attributes, { nodes: nodes, constants: constants, context: {
                                                project: project,
                                                environment: environment,
                                                configuration: configuration,
                                                node_type: node_type,
                                                node_name: node_name
                                              } })

    @depends_on += references
    @depends_on = @depends_on.flatten.uniq

    @attributes = HashUtils.json_dup(attributes)
  rescue StandardError => e
    # adding context to error
    raise [self.node_id, e.message].join(": ")
  end

  def references
    refs = []

    # calculate references from YAML tags
    HashUtils.map_values(attributes) do |a|
      next a unless a.respond_to?(:references)
      refs += a.references
      a
    end

    # remove self from reference
    refs -= [self]

    # TODO: try get references from terraform_ids -> node
    refs.flatten.uniq
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
    @node_id ||= [project, environment, configuration, node_type, node_name].compact.join(":")
  end

  def load_gps_file
    # TODO: stop circular referencing
    depends_on.each(&:load_gps_file)
    gps.load_gps_file("projects/#{project}.gps.yml")
  end

  # define_resource create three helper methods
  # 1. read method similar to attr_reader
  # 2. ref method which can be used
  # 3. create method which sets the resource with the correct ref
  def self.define_resource(type, name, id_lambda = nil)
    load_gps_file = -> { load_gps_file() }
    id_lambda = -> { resource_id(name) } if id_lambda.nil?
    read_method = name.to_s
    ref_method = "#{name}_ref"
    create_method = "create_#{name}"

    define_method(read_method) do
      instance_exec(&load_gps_file)
      instance_variable_get("@#{name}")
    end

    define_method(ref_method) do |attribute = "id", auto_load = true|
      instance_exec(&load_gps_file) if auto_load
      id = instance_exec(&id_lambda)
      "${#{type}.#{id}.#{attribute}}"
    end

    define_method(create_method) do |project|
      id = instance_exec(&id_lambda)
      resource = project.resource(type, id) {}
      instance_variable_set("@#{name}", resource)
      resource
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
  rescue StandardError => e
    raise ["ERB error for file #{path}", e.message].join(": ")
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

  def finder
    @finder ||= GeoEngineer::GPS::Finder.new(all_nodes, constants, {
                                               project: @project,
                                               environment: @environment,
                                               configuration: @configuration,
                                               node_type: @node_type,
                                               node_name: @node_name
                                             })
  end

  def where_all(queries)
    queries.map { |q| where(q) }.flatten.uniq
  end

  def where(query)
    finder.where(query)
  end

  def find(query)
    finder.find(query)
  end

  def dereference(reference)
    finder.dereference(reference)
  end
end
