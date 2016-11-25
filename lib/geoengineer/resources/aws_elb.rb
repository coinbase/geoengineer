########################################################################
# AwsElb is the +aws_elb+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/elb.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsElb < GeoEngineer::Resource
  validate :validate_unique_lb_ports
  validate -> { validate_required_attributes([:name]) }
  validate -> { validate_subresource_required_attributes(:access_logs, [:bucket]) }
  validate -> {
    validate_subresource_required_attributes(
      :listener,
      [
        :instance_port,
        :instance_protocol,
        :lb_port,
        :lb_protocol
      ]
    )
  }
  validate -> {
    validate_subresource_required_attributes(
      :health_check,
      [
        :healthy_threshold, :unhealthy_threshold, :target, :interval, :timeout
      ]
    )
  }
  validate -> { validate_required_subresource(:listener) }

  after :initialize, -> { _terraform_id -> { name } }

  def validate_unique_lb_ports
    errors = []
    ports = []
    self.all_listener.each do |listener|
      if ports.include? listener.lb_port
        errors << "AwsElb non-unique listener lb_port #{for_resource}"
      end
      ports << listener.lb_port
    end
    errors
  end

  def short_type
    "elb"
  end

  def self._fetch_remote_resources
    AwsClients.elb.describe_load_balancers['load_balancer_descriptions'].map(&:to_h).map do |elb|
      elb[:_terraform_id] = elb[:load_balancer_name]
      elb[:_geo_id] = elb[:load_balancer_name]
      elb[:name] = elb[:load_balancer_name]
      elb
    end
  end
end
