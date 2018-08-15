# Template for building lambdas
class GeoEngineer::Templates::Lambda < GeoEngineer::Template
  attr_reader :lambda_function

  def initialize(name, project, params)
    super(name, project, params)
    @project = project
    require_dependencies
    validate_required_parameters(params, %i[name role_name])
    throw "Error: AWS Lambdas must be defined for a project" if @project.nil?
    @lambda_function = create_function(params)
  end

  def create_function(params)
    project = @project
    role_arn = "arn:aws:iam::#{env.account_id}:role/#{params[:role_name]}"
    name_tag = "lambda::#{project.full_name}::#{params[:name_tag] || 'app'}"

    resource("aws_lambda_function", params[:name]) {
      function_name params[:name]
      description params[:name]

      role role_arn
      handler params[:handler] || "index.handle"
      memory_size params[:memory] || 128
      runtime params[:runtime] || "nodejs6.10"
      timeout params[:timeout] || "300"

      unless params[:reserved_concurrent_executions].nil?
        reserved_concurrent_executions params[:reserved_concurrent_executions]
      end

      vpc_config(params[:vpc_config]) if params[:vpc_config]

      filename "#{__dir__}/empty-lambda.zip"
      publish "true"

      lifecycle {
        ignore_changes ["environment"]
      }

      tags {
        Name name_tag
        ProjectName project.full_name
        self[:org] = project.org
        self[:project] = project.name
      }
    }
  end
end
