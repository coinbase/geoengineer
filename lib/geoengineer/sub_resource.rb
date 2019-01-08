########################################################################
# SubResources are included in resources with their own rules
#
# For example, +ingress+ in +aws_security_group+ is a subresource.
#
# A SubResource can have arbitrary attributes
########################################################################
class GeoEngineer::SubResource
  include HasAttributes
  include HasSubResources

  attr_reader :_type

  def initialize(resource, type, &block)
    @resource = resource
    @_type = type.to_s
    instance_exec(self, &block) if block_given?
  end

  def _terraform_id
    @resource._terraform_id
  end

  ## Terraform methods
  def to_terraform
    sb = ["  #{@_type} { "]

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
    [@_type, json]
  end
end
