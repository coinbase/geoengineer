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

  def self._deep_symbolize_keys(obj)
    if obj.is_a?(Hash)
      obj.each_with_object({}) do |(key, value), hash|
        hash[key.to_sym] = _deep_symbolize_keys(value)
      end
    elsif obj.is_a?(Array)
      obj.map { |value| _deep_symbolize_keys(value) }
    else
      obj
    end
  end

  def self._create_permission(function)
    policy = function[:policy]
    policy[:Statement].map do |statement|
      # Note that the keys for a statement objection are all CamelCased
      # Whereas most other keys in this repo are snake_cased
      statement.merge(
        {
          _terraform_id: statement[:Sid],
          function_name: function[:function_name],
          function_version: function[:version]
        }
      )
    end
  end

  # Right now, this only fetches policies for the $LATEST version
  # If we want to support fetching the permissions for all of the aliases as well,
  # We'll need to add another call per function, bring total calls to 2N+1...
  # Same deal if we need to support older versions...
  # (excluding any extra calls for pagination). Less than ideal...
  def self._fetch_remote_resources
    _fetch_functions
      .map { |function| _fetch_policy(function) }
      .compact
      .map { |function| _create_permission(function) }
      .flatten
      .compact
  end
end
