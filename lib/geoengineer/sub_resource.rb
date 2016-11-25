########################################################################
# SubResources are included in resources with their own rules
#
# For example, +ingress+ in +aws_security_group+ is a subresource.
#
# A SubResource can have arbitrary attributes
########################################################################
class GeoEngineer::SubResource
  include HasAttributes

  attr_reader :type

  def initialize(resource, type, &block)
    @resource = resource
    @type = type.to_s
    instance_exec(self, &block) if block_given?
  end

  def _terraform_id
    @resource._terraform_id
  end

  def to_terraform
    sb = ["  #{@type} { "]
    sb.concat terraform_attributes.map { |k, v|
      "    #{k.to_s.inspect} = #{v.inspect}"
    }
    sb << "  }"
    sb.join("\n")
  end

  def to_terraform_json
    [@type, terraform_attributes]
  end
end
