# Role Template
class GeoEngineer::Templates::UsersWithPolicies < GeoEngineer::Template
  attr_reader :users, :policies

  # parameters are:
  # {
  #   users: [List of <name> of the users to create] (Required)
  #   policies: { Hash of <policy_name>: <path to policy file> } (Required)
  # }
  def initialize(name, project, parameters)
    validate_required_parameters(parameters, %i[users policies])
    validate_not_empty(parameters, %i[users policies])
    super(name, project, parameters)
    @users = create_users(parameters)
    @policies = create_policies(parameters)
    create_policy_attachments(@users, @policies)
  end

  def create_users(parameters)
    parameters[:users].map do |user_name|
      resource('aws_iam_user', normalize_id(user_name)) { name user_name }
    end
  end

  def create_policies(parameters)
    context = parameters[:context] || binding

    parameters[:policies].map do |(policy_name, policy_file)|
      resource('aws_iam_policy', normalize_id(policy_name)) {
        name policy_name
        _policy_file policy_file, context
      }
    end
  end

  def create_policy_attachments(users, policies)
    user_names = users.map(&:name)

    policies.map do |policy|
      attachment_name = normalize_id("#{policy.name}-#{user_names.join('-')}")
      resource('aws_iam_policy_attachment', attachment_name) {
        name attachment_name
        self['users'] = user_names
        _policy -> { policy }
      }
    end
  end
end
