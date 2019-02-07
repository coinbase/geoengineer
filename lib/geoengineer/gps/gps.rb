require 'yaml'
###
# GPS Geo Planning System
# This module is designed as a higher abstration above the "resources" level
# The abstration is built for engineers to use so is in their vocabulary
# As each engineering team is different GPS is only building blocks
# GPS is not a complete solution
###
class GeoEngineer::GPS
  class NotFoundError < StandardError; end
  class NotUniqueError < StandardError; end
  class BadQueryError < StandardError; end
  class GPSProjetNotFound < StandardError; end
  class NodeTypeNotFound < StandardError; end
  class MetaNodeError < StandardError; end

  ###
  # HASH METHODS
  ###

  # remove_ removes all keys starting with `_`
  def self.remove_(hash)
    hash = hash.dup
    hash.each_pair do |key, value|
      hash.delete(key) && next if key.to_s.start_with?("_")
      hash[key] = remove_(value) if value.is_a?(Hash)
    end
    hash
  end

  def self.deep_dup(object)
    JSON.parse(object.to_json)
  end

  ###
  # END OF HASH METHODS
  ###

  ###
  # Search Methods
  ###

  # where returns multiple nodes
  def self.where(nodes, query = "*:*:*:*:*")
    search(nodes, query)
  end

  # find a node from nodes
  def self.find(nodes, query = "*:*:*:*:*")
    query_nodes = search(nodes, query)
    raise NotFoundError, "for query #{query}" if query_nodes.empty?
    raise NotUniqueError, "for query #{query}" if query_nodes.length > 1
    query_nodes.first
  end

  def self.split_query(query)
    query_parts = query.split(":")
    raise BadQueryError, "for query #{query}" if query_parts.length != 5
    query_parts
  end

  def self.search(nodes, query)
    project, environment, config, node_type, node_name = split_query(query)
    nodes.select { |n| n.match(project, environment, config, node_type, node_name) }
  end

  ###
  # End of Search Methods
  ###

  def self.json_schema
    node_names = {
      "type":  "object",
      "additionalProperties" => {
        "type":  "object"
      }
    }

    node_types = {
      "type":  "object",
      "additionalProperties" => node_names
    }

    configurations = {
      "type":  "object",
      "additionalProperties" => node_types
    }

    environments = {
      "type":  "object",
      "additionalProperties" => configurations,
      "minProperties": 1
    }

    environments
  end

  # Load
  def self.load_gps_file(gps_instance, gps_file)
    raise "The file \"#{gps_file}\" does not exist" unless File.exist?(gps_file)

    # partial file name is the
    partial_file_name = gps_file.gsub(".gps.yml", ".rb")

    if File.exist?(partial_file_name)
      # if the partial file exists we load the file directly
      # This will create the GPS resources
      require "#{Dir.pwd}/#{partial_file_name}"
    else
      # otherwise initalize for the partial directly here
      gps_instance.partial_of(partial_file_name)
    end
  end

  def load_gps_file(gps_file)
    GeoEngineer::GPS.load_gps_file(self, gps_file)
  end

  # Parse
  def self.parse_dir(dir)
    base_hash = {}

    extension = ".gps.yml"

    # Load, expand then merge all yml files
    Dir["#{dir}**/*#{extension}"].each do |gps_file|
      # Merge Keys don't work with YAML.safe_load
      # since we are also loading Ruby safe_load is not needed

      gps_text = ERB.new(File.read(gps_file)).result(binding).to_s
      gps_hash = YAML.load(gps_text)
      # remove all keys starting with `_` to remove paritals
      gps_hash = remove_(gps_hash)
      JSON::Validator.validate!(json_schema, gps_hash)

      # project name it the path + file
      project_name = gps_file.sub(dir, "")[0...-extension.length]

      # assign to the base_hash the
      base_hash[project_name.to_s] = gps_hash
    end

    GeoEngineer::GPS.new(base_hash)
  end

  attr_reader :nodes
  def initialize(base_hash)
    # Base Hash is the unedited input, useful for debugging
    @base_hash = base_hash

    # First Deep Dup to ensure seperate objects
    # Dup to ensure string keys and to expeand
    projects_hash = GeoEngineer::GPS.deep_dup(base_hash)

    # expand meta nodes, this takes nodes and expands them
    projects_hash = expand_meta_nodes(projects_hash)

    # build the node instances and add them to all nodes
    @nodes = build_nodes(projects_hash)

    # validate all nodes
    @nodes.each(&:validate) # this will validate and expand based on their json schema
  end

  def find(query)
    GeoEngineer::GPS.find(@nodes, query)
  end

  def where(query)
    GeoEngineer::GPS.where(@nodes, query)
  end

  def to_h
    GeoEngineer::GPS.deep_dup(@base_hash)
  end

  def expanded_hash
    expanded_hash = {}
    @nodes.each do |n|
      proj = expanded_hash[n.project] ||= {}
      env = proj[n.environment] ||= {}
      conf = env[n.configuration] ||= {}
      nt = conf[n.node_type] ||= {}
      nt[n.node_name] ||= n.attributes
    end
    expanded_hash
  end

  def loop_projects_hash(projects_hash)
    # TODO: validate the strucutre before this
    projects_hash.each_pair do |project, environments|
      environments.each_pair do |environment, configurations|
        configurations.each_pair do |configuration, nodes|
          nodes.each_pair do |node_type, node_names|
            node_names.each_pair do |node_name, attributes|
              node_type_class = find_node_class(node_type)
              node = node_type_class.new(project, environment, configuration, node_name, attributes)
              yield environments, configurations, nodes, node_names, node
            end
          end
        end
      end
    end
  end

  def expand_meta_nodes(projects_hash)
    # Bit of a hack just execute expand thre times to support meta-meta-meta nodes
    ret, = expand_meta_node_layer(
      *expand_meta_node_layer(
        *expand_meta_node_layer(projects_hash, [])
      )
    )
    ret
  end

  def expand_meta_node_layer(projects_hash, previously_built_nodes)
    all_built_nodes = []
    # We dup the original hash because we cannot edit and loop over it at the same time
    loop_projects_hash(GeoEngineer::GPS.deep_dup(projects_hash)) do |_, _, _, _, node|
      next unless node.meta?
      node.validate # ensures that the meta node has expanded and has correct attributes

      # find the hash to edit
      nodes = projects_hash.dig(node.project, node.environment, node.configuration)

      # node_type => node_name => attrs
      built_nodes = GeoEngineer::GPS.deep_dup(node.build_nodes) # dup to ensure string keys

      built_nodes.each_pair do |built_node_type, built_node_names|
        built_node_names.each_pair do |built_node_name, built_attributes|
          built_node = Node.new(node.project, node.environment, node.configuration, built_node_name, built_attributes)
          built_node.node_type = built_node_type

          add_built_node(nodes, node, built_node, all_built_nodes, previously_built_nodes)
        end
      end
    end

    [projects_hash, (all_built_nodes + previously_built_nodes)]
  end

  def add_built_node(nodes, node, built_node, all_built_nodes, built_nodes)
    nodes[built_node.node_type] ||= {}

    # Error if the meta-node is overwriting an existing node and not a previously built node
    already_built_error = "\"#{node.node_name}\" overwrites node \"#{built_node.node_name}\""
    should_error = nodes[built_node.node_type].key?(built_node.node_name) && !built_nodes.include?(built_node.node_id)
    raise MetaNodeError, already_built_error if should_error

    # append to the hash
    nodes[built_node.node_type][built_node.node_name] = built_node.attributes
    all_built_nodes << built_node.node_id
  end

  def build_nodes(projects_hash)
    all_nodes = []
    # This is a lot of assumptions

    loop_projects_hash(projects_hash) do |_, _, _, _, node|
      all_nodes << node
    end

    all_nodes
  end

  # This method takes the file name of the geoengineer project file
  # it calculates the location of the gps file
  def partial_of(file_name, &block)
    org_name, project_name = file_name.gsub(".rb", "").split("/")[-2..-1]
    full_name = "#{org_name}/#{project_name}"

    @created_projects ||= {}
    return if @created_projects[full_name] == true
    @created_projects[full_name] = true

    create_project(org_name, project_name, env, &block)
  end

  def create_project(org, name, environment, &block)
    project_name = "#{org}/#{name}"
    environment_name = environment.name
    project_environments = project_environments(project_name)

    raise GPSProjetNotFound, "project not found \"#{project_name}\"" unless project?(project_name)

    project = environment.project(org, name) do
      environments project_environments
    end

    # create all resources for projet
    project_nodes = GeoEngineer::GPS.where(@nodes, "#{project_name}:#{environment_name}:*:*:*")
    project_nodes.each do |n|
      n.all_nodes = @nodes
      n.create_resources(project) unless n.meta?
    end

    project_configurations(project_name, environment_name).each do |configuration|
      # yeild to the given block nodes per-config
      nw = GeoEngineer::GPS::NodesContext.new(project_name, environment_name, configuration, @nodes)
      yield(project, configuration, nw) if block_given? && project_nodes.any?
    end

    project
  end

  def project?(project)
    !!@base_hash[project]
  end

  def project_environments(project)
    @base_hash.dig(project)&.keys || []
  end

  def project_configurations(project, environment)
    @base_hash.dig(project, environment)&.keys || []
  end

  # find node type
  def find_node_class(type)
    clazz_name = type.split('_').collect(&:capitalize).join
    module_clazz = "GeoEngineer::GPS::Nodes::#{clazz_name}"
    return Object.const_get(module_clazz) if Object.const_defined? module_clazz

    raise NodeTypeNotFound, "not found node type '#{type}' for '#{clazz_name}' or '#{module_clazz}'"
  end
end
