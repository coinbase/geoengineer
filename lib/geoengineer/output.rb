########################################################################
# Outputs are mapped 1:1 to terraform outputs
#
# {https://www.terraform.io/docs/configuration/outputs.html Terraform Docs}
########################################################################
class GeoEngineer::Output
  attr_reader :id, :value

  def initialize(id, value, &block)
    @id    = id
    @value = value
  end

  def to_terraform_json
    { id: { value: value } }
  end

  def to_terraform
    sb = ""
    sb += "output #{@id.inspect} { "
    sb += "\n"
    sb += "  value = #{@value.inspect}"
    sb += "\n"
    sb += " }"
    sb
  end
end
