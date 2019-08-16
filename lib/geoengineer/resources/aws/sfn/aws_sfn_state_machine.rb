########################################################################
# AwsSfnStateMachine is the +aws_sfn_state_machine+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/sfn_state_machine.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSfnStateMachine < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :definition, :role_arn]) }

  after :initialize, -> {
    _terraform_id -> {
      "arn:aws:states:#{environment.region}:#{environment.account_id}:stateMachine:#{name}"
    }
  }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.states(provider).list_state_machines.state_machines.map(&:to_h).map do |sm|
      {
        _terraform_id: sm[:state_machine_arn],
        _geo_id: sm[:state_machine_arn],
        name: sm[:name]
      }
    end
  end
end
