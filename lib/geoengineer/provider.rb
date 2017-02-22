########################################################################
# Outputs are mapped 1:1 to terraform outputs
#
# {https://www.terraform.io/docs/providers/aws/ Terraform Docs}
########################################################################
class GeoEngineer::Provider
  attr_reader :id
  include HasAttributes

  def initialize(id, &block)
    @id = id
    instance_exec(self, &block) if block_given?
  end

  def terraform_id
    if self.alias
      "#{id}.#{self.alias}"
    else
      id
    end
  end

  ## Terraform methods
  def to_terraform
    sb = ["provider #{@id.inspect} { "]

    sb.concat terraform_attributes.map { |k, v|
      "  #{k.to_s.inspect} = #{v.inspect}"
    }

    sb << " }"
    sb.join("\n")
  end

  def to_terraform_json
    { id.to_s => terraform_attributes }
  end
end
