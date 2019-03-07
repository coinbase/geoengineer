require 'securerandom'

def create_api_gateway_rest_api(name)
  {
    id: SecureRandom.hex,
    name: name
  }
end

def create_api_gateway_resource(rest_api_id, path)
  {
    id: SecureRandom.hex,
    parent_id: rest_api_id,
    path: path
  }
end

def create_api_gateway_model(name, content_type: 'application/json')
  {
    id: SecureRandom.hex,
    name: name,
    description: "Model #{SecureRandom.hex}",
    schema: "{}",
    content_type: content_type
  }
end

def create_api_gateway_request_validator(name)
  {
    id: SecureRandom.hex,
    name: name
  }
end

def create_api_gateway_gateway_response(response_type, status_code: 400)
  {
    response_type: response_type,
    status_code: status_code.to_s
  }
end

# Creates an API Gateway and adds some initial route resources to it.
#
# @param api_gateway [Aws::APIGateway::Client] API gateway client to which
#   stubs will be added.
def create_api_with_resources(api_gateway)
  # Create a new Rest API and add some resources
  rest_api = create_api_gateway_rest_api("TestAPI")
  api_root_resource = create_api_gateway_resource(rest_api[:id], "/")
  api_thing_resource = create_api_gateway_resource(rest_api[:id], "/thing")

  api_gateway.stub_responses(
    :get_rest_apis,
    api_gateway.stub_data(
      :get_rest_apis,
      { items: [rest_api] }
    )
  )

  api_gateway.stub_responses(
    :get_resources,
    api_gateway.stub_data(
      :get_resources,
      {
        items: [api_root_resource, api_thing_resource]
      }
    )
  )
end
