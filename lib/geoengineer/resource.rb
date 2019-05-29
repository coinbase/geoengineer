########################################################################
# Resources are the core of GeoEngineer and are mapped 1:1 to terraform resources
#
# {https://www.terraform.io/docs/configuration/resources.html Terraform Docs}
#
# For example, +aws_security_group+ is a resource
#
# A Resource can have arbitrary attributes, validation rules and lifecycle hooks
########################################################################
class GeoEngineer::Resource
  DEFAULT_PROVIDER = "default_provider".freeze

  include HasAttributes
  include HasSubResources
  include HasValidations
  include HasLifecycle

  attr_accessor :environment, :project, :template

  attr_reader :_type, :id

  before :validation, :merge_parent_tags

  validate -> { validate_required_attributes([:_geo_id]) }

  def initialize(type, id, &block)
    @_type = type
    @id = id

    # Remembering parents, grand parents ...
    @environment = nil
    @project = nil
    @template = nil

    # Most resources will have the same _geo_id and _terraform_id
    # Each resource must define _terraform_id
    _geo_id -> { _terraform_id }
    instance_exec(self, &block) if block_given?
    execute_lifecycle(:after, :initialize)
  end

  def remote_resource
    return @_remote if @_remote_searched
    @_remote = _find_remote_resource
    @_remote_searched = true
    @_remote
  end

  def depends_on(list_or_item)
    self[:depends_on] ||= []
    self[:depends_on].concat([list_or_item].flatten.compact)
  end

  # Look up the resource remotly to see if it exists
  # This method will not work within a resource definition
  def new?
    !remote_resource
  end

  ## Terraform methods
  def to_terraform
    sb = ["resource #{@_type.inspect} #{@id.inspect} { "]

    sb.concat terraform_attributes.map { |k, v|
      "  #{k.to_s.inspect} = #{v.inspect}"
    }

    sb.concat subresources.map(&:to_terraform)
    sb << " }"
    sb.join("\n")
  end

  def to_terraform_json
    json = terraform_attributes
    subresources.map(&:to_terraform_json).each do |k, v|
      json[k] ||= []
      json[k] << v
    end

    json["tags"] = json["tags"].reduce({}, :merge) if json["tags"] # tags not a list
    json
  end

  def to_terraform_state
    {
      type: @_type,
      primary: {
        id: _terraform_id
      }
    }
  end

  def terraform_name
    "#{_type}.#{id}"
  end

  # Override to_s
  def to_s
    terraform_name
  end

  def to_ref(attribute = "id")
    "${#{terraform_name}.#{attribute}}"
  end

  # This tries to return the terraform ID, if that is nil, then it will return the ref
  def to_id_or_ref
    _terraform_id || to_ref
  end

  def reset
    reset_attributes
    @_remote_searched = false
    @_remote = nil
    self
  end

  def duplicate(new_id, &block)
    parent = @project || @environment
    return unless parent

    duplicated = duplicate_resource(parent, self, new_id)
    duplicated.reset
    duplicated.instance_exec(duplicated, &block) if block_given?
    duplicated.execute_lifecycle(:after, :initialize)

    duplicated
  end

  def duplicate_resource(parent, progenitor, new_id)
    parent.resource(progenitor._type, new_id) do
      # We want to set all attributes from the parent, EXCEPT _geo_id and _terraform_id
      # Which should be set according to the init logic
      progenitor.attributes.each do |key, value|
        self[key] = value unless %w(_geo_id _terraform_id).include?(key)
      end

      progenitor.subresources.each do |subresource|
        duplicated_subresource = GeoEngineer::SubResource.new(self, subresource._type) do
          subresource.attributes.each do |key, value|
            self[key] = value
          end
        end
        self.subresources << duplicated_subresource
      end
    end
  end

  # REMOTE METHODS

  # This method will fetch the remote resource that has the same _geo_id as the codified resource.
  # This method will:
  # 1. return resource individually if class has defined how to do so
  # 2. return nil if no resource is found
  # 3. return an instance of Resource with the remote attributes
  # 4. throw an error if more than one resource has the same _geo_id
  def _find_remote_resource
    return GeoEngineer::Resource.build(remote_resource_params) if find_remote_as_individual?

    matches = matched_remote_resource
    throw "ERROR:\"#{_type}.#{id}\" has #{matches.length} remote resources" if matches.length > 1

    matches.first
  end

  # By default, remote resources are bulk-retrieved. In order to fetch a remote resource as an
  # individual, the child-class over-write 'find_remote_as_individual?' and 'remote_resource_params'
  def find_remote_as_individual?
    false
  end

  def remote_resource_params
    {}
  end

  def build_individual_remote_resource
    self.class.build(remote_resource_params)
  end

  def matched_remote_resource
    self.class.fetch_remote_resources(fetch_provider).select { |r| r._geo_id == _geo_id }
  end

  # There are two types of provider, the string given to a resource, and the object with attributes
  # this method takes the string on the resource and returns the object
  def fetch_provider
    # provider is the explictly defined provider
    # otherwise look at the type to find the default provider, e.g. "aws"
    environment&.find_provider(provider || _type.split("_").first)
  end

  def self.fetch_remote_resources(provider)
    # The cache key is the provider
    # no provider no resource
    provider_id = provider&.terraform_id || DEFAULT_PROVIDER
    @_rr_cache ||= {}
    return @_rr_cache[provider_id] if @_rr_cache[provider_id]
    @_rr_cache[provider_id] = _fetch_remote_resources(provider)
                              .reject { |resource| _ignore_remote_resource?(resource) }
                              .map { |resource| build(resource) }
  end

  # This method must be implemented for each resource type
  # it must return a list of hashes with at least the key
  def self._fetch_remote_resources(provider)
    throw "NOT IMPLEMENTED ERROR for #{name}"
  end

  def self._paginate(response, attribute)
    resources = []

    resources += response[attribute]
    while response.next_page?
      response = response.next_page
      resources += response[attribute]
    end

    resources
  end

  # This method allows you to specify certain remote resources that for whatever reason,
  # cannot or should not be codified. It expects a list of `_geo_ids`, and can be overriden
  # in child classes.
  def self._resources_to_ignore
    []
  end

  def self._ignore_remote_resource?(resource)
    geo_id = _deep_symbolize_keys(resource)[:_geo_id]
    _resources_to_ignore.any? do |string_or_regex|
      case string_or_regex
      when Regexp
        geo_id.match?(string_or_regex)
      else
        string_or_regex == geo_id
      end
    end
  end

  def self._deep_symbolize_keys(obj)
    case obj
    when Hash then
      obj.each_with_object({}) do |(key, value), hash|
        hash[key.to_sym] = _deep_symbolize_keys(value)
      end
    when Array then obj.map { |value| _deep_symbolize_keys(value) }
    else obj
    end
  end

  def self.build(resource_hash)
    return nil unless resource_hash
    GeoEngineer::Resource.new(type_from_class_name, resource_hash['_geo_id']) {
      resource_hash.each { |k, v| self[k] = v }
    }
  end

  def self.clear_remote_resource_cache
    @_rr_cache = nil
  end

  # VIEW METHODS
  def short_type
    _type
  end

  # strip project information if project
  def short_id
    si = id.to_s.tr('-', "_")
    si = si.gsub(project.full_id_name, '') if project
    si.gsub('__', '_').gsub(/^_|_$/, '')
  end

  def short_name
    "#{short_type}.#{short_id}"
  end

  def in_project
    project.nil? ? "" : "in project \"#{project.full_name}\""
  end

  def for_resource
    "for resource \"#{_type}.#{id}\" #{in_project}"
  end

  def setup_tags_if_needed
    tags {} unless tags
  end

  def merge_parent_tags
    return unless support_tags?

    %i(project environment).each do |source|
      parent = send(source)
      next unless parent
      next unless parent.methods.include?(:attributes)
      next unless parent&.tags
      merge_tags(source)
    end
  end

  def merge_tags(source)
    setup_tags_if_needed

    send(source).all_tags.map(&:attributes).reduce({}, :merge)
                .each { |key, value| tags.attributes[key] ||= value }
  end

  # VALIDATION METHODS
  def support_tags?
    true
  end

  def validate_required_subresource(subresource)
    "Subresource '#{subresource}'' required #{for_resource}" if send(subresource.to_sym).nil?
  end

  def validate_subresource_required_attributes(subresource, keys)
    send("all_#{subresource}".to_sym).map do |sr|
      keys.map do |key|
        "#{key} attribute on subresource #{subresource} nil #{for_resource}" if sr[key].nil?
      end
    end.flatten.compact
  end

  def validate_has_tag(tag)
    errs = []
    errs << validate_required_subresource(:tags)
    errs.concat(validate_subresource_required_attributes(:tags, [tag]))
    errs
  end

  # CLASS METHODS
  def self.type_from_class_name
    # from http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
    name.split('::').last
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr("-", "_").downcase
  end
end
