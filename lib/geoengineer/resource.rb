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
  include HasAttributes
  include HasSubResources
  include HasValidations
  include HasLifecycle

  attr_accessor :environment, :project, :template

  attr_reader :type, :id

  before :validation, :merge_project_tags

  validate -> { validate_required_attributes([:_geo_id]) }

  def initialize(type, id, &block)
    @type = type
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
    @_remote&.local_resource = self
    @_remote
  end

  # Look up the resource remotly to see if it exists
  # This method will not work within a resource definition
  def new?
    !remote_resource
  end

  ## Terraform methods
  def to_terraform
    sb = ["resource #{@type.inspect} #{@id.inspect} { "]

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
    json
  end

  def to_terraform_state
    {
      type: @type,
      primary: {
        id: _terraform_id
      }
    }
  end

  def terraform_name
    "#{type}.#{id}"
  end

  # Override to_s
  def to_s
    terraform_name
  end

  def to_ref(attribute = "id")
    "${#{terraform_name}.#{attribute}}"
  end

  # REMOTE METHODS

  # This method will fetch the remote resource that has the same _geo_id as the codified resource.
  # This method will:
  # 1. return nil if no resource is found
  # 2. return an instance of Resource with the remote attributes
  # 3. throw an error if more than one resource has the same _geo_id
  def _find_remote_resource
    aws_resources = self.class.fetch_remote_resources()
    matches = aws_resources.select { |r| r._geo_id == self._geo_id }

    return matches.first if matches.length == 1
    return nil if matches.empty?

    throw "ERROR:\"#{self.type}.#{self.id}\" has #{matches.length} remote resources"
  end

  def self.fetch_remote_resources
    return @_rr_cache if @_rr_cache
    @_rr_cache = []
    resource_hashes = _fetch_remote_resources()

    resource_hashes.each do |res_hash|
      @_rr_cache << GeoEngineer::Resource.new(self.type_from_class_name, res_hash['_geo_id']) {
        # add attributes to the resource
        res_hash.each do |k, v|
          self[k] = v
        end
      }
    end

    @_rr_cache
  end

  def self.clear_remote_resource_cache
    @_rr_cache = nil
  end

  # This method must be implemented for each resource type
  # it must return a list of hashes with at least the key
  def self._fetch_remote_resources
    throw "NOT IMPLEMENTED ERROR for #{self.name}"
  end

  # VIEW METHODS
  def short_type
    type
  end

  # strip project information if project
  def short_id
    si = id.to_s.tr('-', "_")
    si = si.gsub(project.full_id_name, '') if project
    si = si.gsub('__', '_').gsub(/^_|_$/, '')
    si
  end

  def short_name
    "#{short_type}.#{short_id}"
  end

  def in_project
    project.nil? ? "" : "in project \"#{project.full_name}\""
  end

  def for_resource
    "for resource \"#{type}.#{id}\" #{in_project}"
  end

  # VALIDATION METHODS
  def support_tags?
    true
  end

  def merge_project_tags
    return unless self.project
    return unless self.project.tags
    return unless self.support_tags?

    tags {} unless tags # defining tag subresource if it does not exist

    project_tags_hash = self.project.all_tags.map(&:attributes).reduce({}, :merge)
    project_tags_hash.each do |key, value|
      next if tags.attributes[key]
      tags.attributes[key] = value
    end
    tags
  end

  def validate_required_subresource(subresource)
    "Subresource '#{subresource}'' required #{for_resource}" if self.send(subresource.to_sym).nil?
  end

  def validate_subresource_required_attributes(subresource, keys)
    errs = []
    self.send("all_#{subresource}".to_sym).each do |sr|
      keys.each do |key|
        errs << "#{key} attribute on subresource #{subresource} nil #{for_resource}" if sr[key].nil?
      end
    end
    errs
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
    self.name.split('::').last
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr("-", "_")
        .downcase
  end
end
