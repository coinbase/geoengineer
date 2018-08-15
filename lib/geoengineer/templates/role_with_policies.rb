# Template for Role with multiple Policies
class GeoEngineer::Templates::RoleWithPolicies < GeoEngineer::Template
  class NoAssumePolicyError < StandardError; end

  attr_reader :role, :policies

  # parameters are:
  # {
  #   role_name: Name of the role (Required)
  #   role_description: Description of the role (Optional)
  #   policy_description: Description of the policy (Optional)
  #   service: Name of service to allow assumption of role (Optional)
  #   path: Path for the policy (Optional)
  #   assume_policy: JSON assume policy (Optional)
  #   policies: { Hash of <policy_name>: <path to policy file> } (Required)
  #   include_read_roles: Whether or not to create read-a and read-b policies
  #                       for this role (Default: false)
  # }
  def initialize(name, project, parameters)
    validate_required_parameters(parameters, %i[role_name policies])
    validate_not_empty(parameters, %i[policies])
    super(name, project, parameters)
    @role = create_role(parameters)
    @policies = create_policies(parameters)
    create_policy_attachments(@role, @policies)
  end

  def create_role(parameters)
    assume_policy = if parameters[:service]
                      _assume_policy(parameters[:service])
                    elsif parameters[:assume_policy]
                      parameters[:assume_policy]
                    else
                      raise NoAssumePolicyError, "Must provide :service or :assume_policy"
                    end

    resource('aws_iam_role', parameters[:role_name]) {
      name parameters[:role_name]
      description parameters[:role_description] || ''
      path parameters[:role_path] || '/'
      assume_role_policy assume_policy
    }
  end

  def create_policies(parameters)
    context = parameters[:context] || binding

    parameters[:policies].map do |(policy_name, policy_file)|
      resource('aws_iam_policy', normalize_id(policy_name)) {
        name policy_name
        description parameters[:policy_description] || ''
        path parameters[:policy_path] || '/'
        _policy_file policy_file, context
      }
    end
  end

  def create_policy_attachments(role, policies)
    policies.map do |policy|
      attachment_name = normalize_id("#{role.name}-#{policy.name}")
      resource('aws_iam_policy_attachment', attachment_name) {
        name attachment_name
        roles [role]
        _policy -> { policy }
      }
    end
  end
end
