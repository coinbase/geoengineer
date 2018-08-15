########################################################################
# Override to define recommended patterns of resource use
########################################################################
class GeoEngineer::Template
  include HasAttributes
  include HasResources

  class MissingRequiredParameters < StandardError; end
  class MalformedParameters < StandardError; end
  class EmptyParameters < StandardError; end
  ALPHABET = ("a".."z").to_a

  attr_accessor :name, :parameters, :parent

  def initialize(name, parent, parameters = {})
    @name = name
    @parameters = parameters
    @parent = parent

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

  ####
  # Helper Methods
  ####

  def validate_required_parameters(parameters, required_parameters)
    missing_parameters = required_parameters.reject { |param| parameters.key?(param) }

    error_msg = "#{missing_parameters.join(', ')} are required parameters for #{self.class.name}"
    raise MissingRequiredParameters, error_msg unless missing_parameters.empty?
  end

  def validate_parameter_length(parameters, list_parameters, length)
    malformed_parameters = list_parameters.reject do |param|
      parameters[param]&.count == length
    end

    error_msg = "Expected #{malformed_parameters.join(', ')} to have #{length} elements each"
    raise MalformedParameters, error_msg unless malformed_parameters.empty?
  end

  def validate_not_empty(parameters, list_parameters)
    empty_parameters = list_parameters.select { |param| parameters[param].empty? }
    error_msg = "#{empty_parameters.join(', ')} cannot be empty"
    raise EmptyParameters, error_msg unless empty_parameters.empty?
  end

  def find_resource_by_name(name)
    template_resources.first[name.to_sym] if template_resources.first.key?(name.to_sym)
  end

  def find_resource(name)
    template_resources.first[name.to_sym] if template_resources.first.key?(name.to_sym)
  end

  def generate_resource_id(aws_service, config = nil, service = nil)
    [aws_service, @project.full_id_name, service, config].compact.join("_").tr("-", "_")
  end

  # Resource names are often character limited, so put the config and service first
  def generate_resource_name(config = nil, service = nil)
    [config, service, @project.full_id_name].compact.join("_").tr("-", "_")
  end

  def generate_name_tag(aws_service, config = nil, service = nil)
    [aws_service, @project.full_name, config, service].compact.join("::").tr("_", "-")
  end

  # Strips any unsupported characters, and replaces with dashes
  def normalize_id(id)
    id.to_s.gsub(/[^a-zA-Z0-9\-_]/, '-')
  end

  def _assume_policy(service)
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": service
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }.to_json
  end
end
