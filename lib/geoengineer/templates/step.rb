# Step Templates
module StepNames
  def step_name
    "#{project.org}-#{project.name}"
  end

  def lambda_role_name
    "#{step_name}-lambda-role"
  end

  def lambda_fn_name
    step_name
  end

  def step_role_name
     "#{step_name}-step-function-role"
  end

  def s3_bucket_name
    "#{step_name}-#{env.account_id}"
  end

  def build_context(context = {})
    TemplateContext.build(
      context.merge({
        step_name: step_name,
        lambda_role_name: lambda_role_name,
        lambda_fn_name: lambda_fn_name,
        step_role_name: step_role_name,
        s3_bucket_name: s3_bucket_name
      })
    )
  end
end

class GeoEngineer::Templates::Step < GeoEngineer::Template
  include StepNames

  attr_accessor :project
  # Create a Step Framework Project
  # Parameters:
  # {
  #   lambda_policy_file: path to policy template file
  #   lambda_policy_context: Hash of context passed to the policy template
  # }
  #
  # Most of the configuration is in the policies that you must define
  def initialize(name, project, params)
    super(name, project, params)
    @project = project
    validate_required_parameters(params, %i[lambda_policy_file lambda_policy_context])

    step_function(params[:lambda_policy_file], params[:lambda_policy_context])
  end

  def step_function(lambda_policy_file, lambda_policy_context)
    project = self.project
    step_role_name = self.step_role_name
    lambda_fn_name = self.lambda_fn_name
    lambda_role_name = self.lambda_role_name
    step_name        = self.step_name

    # Step Function
    project.resource("aws_sfn_state_machine", step_name) {
      name       step_name
      role_arn   "arn:aws:iam::#{env.account_id}:role/step/#{project.org}/#{project.name}/#{env.name}/#{step_role_name}"
      definition '{
        "StartAt": "Noop",
        "States": {
          "Noop": {
            "Type": "Pass",
            "End": true
          }
        }
      }'

      lifecycle {
        ignore_changes ["definition"] # Ignore changes here
      }
    }

    # Lambda
    project.from_template('lambda', "#{step_name}-lambda", {
      name: lambda_fn_name,
      role_name: lambda_role_name,
      runtime: "go1.x",
      handler: "lambda",
      memory: 512
    })

    # Step Function Role
    project.from_template('role_with_policies', step_role_name, {
      role_name: step_role_name,
      role_path: "/step/#{project.org}/#{project.name}/#{env.name}/",
      context: build_context(),
      policies: {
        "#{step_role_name}": "#{__dir__}/step_policy.json.erb"
      },
      assume_policy: {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Service": "states.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
          }
        ]
      }.to_json
    })

    # Lambda Role
    project.from_template('role_with_policies', lambda_role_name, {
      role_name: lambda_role_name,
      service: "lambda.amazonaws.com",
      policies: {
        "#{lambda_role_name}": lambda_policy_file
      },
      context: build_context(lambda_policy_context)
    })
  end
end

class GeoEngineer::Templates::BifrostDeployer < GeoEngineer::Template
  include StepNames

  attr_accessor :project

  # Create a Step Framework Project
  # Parameters:
  # {
  #   lambda_policy_file: path to policy template file
  #   lambda_policy_context: Hash of context passed to the policy template
  #   s3_policy_file: path to policy template file
  #   s3_policy_context: Hash of context passed to the policy template
  # }
  #
  # Most of the configuration is in the policies that you must define
  def initialize(name, project, params)
    super(name, project, params)

    @project = project

    params[:lambda_policy_context] ||= {}
    params[:s3_policy_context] ||= {}

    validate_required_parameters(params, %i[lambda_policy_file])

    bifrost_deployer(
      params[:lambda_policy_file],
      params[:lambda_policy_context],
      params[:s3_policy_file],
      params[:s3_policy_context]
    )
  end

  # This function will create the actual deployer in the account
  def bifrost_deployer(lambda_policy_file, lambda_policy_context, s3_policy_file, s3_policy_context)
    project = self.project
    step_name        = self.step_name
    s3_bucket_name   = self.s3_bucket_name

    # Create Step Function
    project.from_template('step', "#{step_name}_step", {
      lambda_policy_file: lambda_policy_file,
      lambda_policy_context: lambda_policy_context
    })

    s3_context = build_context(s3_policy_context)
    # s3 bucket
    project.resource('aws_s3_bucket', step_name) {
      bucket s3_bucket_name

      acl("private")

      if s3_policy_file
        _policy_file s3_policy_file, s3_context
      end

      tags {
        Name s3_bucket_name
      }
    }
  end
end

class GeoEngineer::Templates::StepAssumed < GeoEngineer::Template
  include StepNames

  attr_accessor :project

  # Create a Step Framework Project
  # Parameters:
  # {
  #   assumed_role_name: Name of role to assume
  #   assumable_from: [account_id] that can assume the role
  #   assumed_policy_file: path to policy template file
  # }
  #
  # Most of the configuration is in the policies that you must define
  def initialize(name, project, params)
    super(name, project, params)
    @project = project

    validate_required_parameters(params, %i[assumed_role_name assumable_from assumed_policy_file])

    step_assumed_role(params[:assumed_role_name], params[:assumable_from], params[:assumed_policy_file])
  end

    # This function will create the assumed role for the deployer in an environment
  def step_assumed_role(lambda_assumed_role_name, trusted_accounts, policy_file)
    project = self.project
    lambda_role_name = self.lambda_role_name

    # Role Assumed by Lambda (deployed to all accounts)
    project.from_template('role_with_policies', lambda_assumed_role_name, {
      role_name: lambda_assumed_role_name,
      policies: {
        "#{lambda_assumed_role_name}": policy_file
      },
      assume_policy: {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "AWS": trusted_accounts.map{ |account| "arn:aws:iam::#{account}:role/#{lambda_role_name}" }
            },
            "Action": "sts:AssumeRole"
          }
        ]
      }.to_json
    })
  end
end
