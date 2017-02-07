########################################################################
# AwsLambdaPermission is the +aws_lambda_function+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lambda_permission.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLambdaPermission < GeoEngineer::Resource
  validate -> { validate_required_attributes([:action, :function_name, :principal, :statement_id]) }

  after :initialize, -> { _terraform_id -> { statement_id } }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'function_name' => self.function_name,
      'statement_id' => self.statement_id
    }
    tfstate
  end

  def self._fetch_functions
    AwsClients
      .lambda
      .list_functions['functions']
      .map(&:to_h)
  end

  def self._fetch_policy(function)
    policy = AwsClients.lambda.get_policy({ function_name: function[:function_name] })&.policy
    parsed = _parse_policy(policy) if policy
    function.merge({ policy: parsed }) if parsed
  end

  def self._parse_policy(policy)
    _deep_symbolize_keys(JSON.parse(policy))
  rescue JSON::ParserError
    nil
  end

  def self._create_permission(function)
    policy = function[:policy]
    policy[:Statement].map do |statement|
      # Note that the keys for a statement object are all CamelCased
      # Whereas most other keys in this repo are snake_cased
      statement.merge(
        {
          _terraform_id: statement[:Sid],
          function_name: function[:function_name],
          function_version: function[:version],
          qualifer: function[:qualifer] || "$LATEST",
          statement_id: statement[:Sid]
        }
      )
    end
  end

  # Right now, this only fetches policies for the $LATEST version
  # If you want to fetch the policy for a version other than $LATEST
  # set `find_remote_as_individual?` to `true` for that resource
  def self._fetch_remote_resources
    _fetch_functions
      .map { |function| _fetch_policy(function) }
      .compact
      .map { |function| _create_permission(function) }
      .flatten
      .compact
  end

  def remote_resource_params
    params = { function_name: function_name }
    params[:qualifier] = qualifier if qualifier

    begin
      policy = _fetch_policy(params)[:policy]
      return {} if policy.nil?
    rescue Aws::Lambda::Errors::ResourceNotFoundException
      return {}
    end

    permission = _create_permission(policy).find do |statement|
      statement[:_terraform_id] == statement_id
    end

    permission || {}
  end
end
