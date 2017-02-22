########################################################################
# AwsProxyProtocolPolicy is the +aws_proxy_protocol_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/proxy_protocol_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsProxyProtocolPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:load_balancer, :instance_ports]) }

  # _terraform_id is the ELB, and the name of the policy, i.e. "TFEnableProxyProtocol"
  after :initialize, -> {
    _terraform_id -> { "#{NullObject.maybe(load_balancer)._terraform_id}:TFEnableProxyProtocol" }
  }

  # The loadbalancer and the instance ports are necessary in the terraform state for the policy
  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'load_balancer' => load_balancer._terraform_id,
      'instance_ports.#' => instance_ports.length.to_s
    }
    instance_ports.each_with_index { |ip, i|
      tfstate[:primary][:attributes]["instance_ports.#{i}"] = ip
    }
    tfstate
  end

  def support_tags?
    false
  end

  def short_type
    "elbppp"
  end

  # This is a weird resource and it is not listed
  def self._fetch_remote_resources(provider)
    []
  end
end
