require 'yaml'
###
# GPS Geo Planning System
# This module is designed as a higher abstration above the "resources" level
# The abstration is built for engineers to use so is in their vocabulary
# As each engineering team is different GPS is only building blocks
# GPS is not a complete solution
###
class GeoEngineer::GPS
  class GPSProjetNotFound < StandardError; end
  class NodeTypeNotFound < StandardError; end
  class MetaNodeError < StandardError; end
  class LoadError < StandardError; end

  GPS_FILE_EXTENSTION = ".gps.yml".freeze

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
  # rubocop:disable Metrics/AbcSize
  def self.parse_dir(dir)
    # Load, expand then merge all yml files
    base_hash = Dir["#{dir}**/*#{GPS_FILE_EXTENSTION}"].reduce({}) do |projects, gps_file|
      begin
        # Merge Keys don't work with YAML.safe_load
        # since we are also loading Ruby safe_load is not needed
        gps_text = ERB.new(File.read(gps_file)).result(binding).to_s
        gps_hash = YAML.load(gps_text)
        # remove all keys starting with `_` to remove paritals
        gps_hash = HashUtils.remove_(gps_hash)
        JSON::Validator.validate!(json_schema, gps_hash)

        # project name is the path + file
        project_name = gps_file.sub(dir, "")[0...-GPS_FILE_EXTENSTION.length]

        projects.merge({ project_name.to_s => gps_hash })
      rescue StandardError => e
        raise LoadError, "Could not load #{gps_file}: #{e.message}"
      end
    end

    GeoEngineer::GPS.new(base_hash)
  end

  attr_reader :base_hash
  def initialize(base_hash)
    # Base Hash is the unedited input, useful for debugging
    @base_hash = base_hash

    # expand meta nodes, this takes nodes and expands them
    @projects_hash = expand_meta_nodes(HashUtils.deep_dup(base_hash))
  end

  def nodes
    return @_nodes if @_nodes

    @_nodes = []
    loop_projects_hash(@projects_hash) do |node|
      @_nodes << node
    end

    # validate all nodes
    @_nodes.each(&:validate) # this will validate all nodes
    @_nodes
  end

  def finder
    @finder ||= GeoEngineer::GPS::Finder.new(nodes)
  end

  def find(query)
    finder.find(query)
  end

  def where(query)
    finder.where(query)
  end

  def dereference(reference)
    finder.dereference(reference)
  end

  def to_h
    HashUtils.json_dup(@base_hash)
  end

  def expanded_hash
    expanded_hash = {}
    nodes.each do |n|
      proj = expanded_hash[n.project] ||= {}
      env = proj[n.environment] ||= {}
      conf = env[n.configuration] ||= {}
      nt = conf[n.node_type] ||= {}
      nt[n.node_name] ||= n.attributes
    end
    HashUtils.json_dup(expanded_hash)
  end

  def loop_projects_hash(projects_hash)
    projects_hash.each_pair do |project, environments|
      environments.each_pair do |environment, configurations|
        configurations.each_pair do |configuration, nodes|
          nodes.each_pair do |node_type, node_names|
            node_names.each_pair do |node_name, attributes|
              node_type_class = find_node_class(node_type)
              yield node_type_class.new(project, environment, configuration, node_name, attributes)
            end
          end
        end
      end
    end
  end

  def expand_meta_node(node)
    node.validate # ensures that the meta node has expanded and has correct attributes
    children_nodes = HashUtils.deep_dup(node.build_nodes)

    children_nodes.reduce(children_nodes.clone) do |expanded, (node_type, node_names)|
      node_names.reduce(expanded.clone) do |inner_expanded, (node_name, attributes)|
        node_type_class = find_node_class(node_type)
        node = node_type_class.new(node.project, node.environment, node.configuration, node_name, attributes)
        next inner_expanded unless node.meta?

        HashUtils.deep_merge(inner_expanded, expand_meta_node(node))
      end
    end
  end

  def expand_meta_nodes(projects_hash)
    # We dup the original hash because we cannot edit and loop over it at the same time
    loop_projects_hash(HashUtils.deep_dup(projects_hash)) do |node|
      next unless node.meta?

      # find the hash to edit
      nodes = projects_hash.dig(node.project, node.environment, node.configuration)

      # node_type => node_name => attrs
      built_nodes = expand_meta_node(node)

      built_nodes.each_pair do |built_node_type, built_node_names|
        nodes[built_node_type] ||= {}
        built_node_names.each_pair do |built_node_name, built_attributes|
          # Error if the meta-node is overwriting an existing node
          already_built_error = "\"#{node.node_name}\" overwrites node \"#{built_node_name}\""
          raise MetaNodeError, already_built_error if nodes[built_node_type].key?(built_node_name)
          # append to the hash
          nodes[built_node_type][built_node_name] = built_attributes
        end
      end
    end

    projects_hash
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
    project_nodes = where("#{project_name}:#{environment_name}:*:*:*")
    project_nodes.each do |n|
      n.all_nodes = nodes
      n.create_resources(project) unless n.meta?
    end

    project_configurations(project_name, environment_name).each do |configuration|
      # yeild to the given block nodes per-config
      nw = GeoEngineer::GPS::NodesContext.new(project_name, environment_name, configuration, nodes)
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
