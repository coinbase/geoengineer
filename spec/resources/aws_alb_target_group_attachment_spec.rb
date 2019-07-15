require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsAlbTargetGroupAttachment do
  let(:aws_client) { AwsClients.alb }

  let(:default_lambda_arn) { 'arn:aws:lambda:us-east-1:12345678:function:test-lambda' }
  let(:default_target_group_arn) { "arn:aws:elasticloadbalancing:us-east-1:12345678:targetgroup/test-tg/c4ae064d" }

  let(:target_group) do
    GeoEngineer::Resources::AwsAlbTargetGroup.new('aws_alb_target_group', 'target_group') {
      target_type 'lambda'
      name 'some target group'
    }
  end

  let(:alb_target_group_attachment) do
    lambda_arn = default_lambda_arn
    GeoEngineer::Resources::AwsAlbTargetGroupAttachment.new('aws_alb_target_group_attachment', 'attachment') {
      target_group_arn default_target_group_arn
      target_id lambda_arn
      _target_group target_group
    }
  end

  # common_resource_tests(described_class, described_class.type_from_class_name, false)

  describe '#remote_resource' do
    before do
      aws_client.stub_responses(
        :describe_target_groups,
        {
          "target_groups": [
            {
              "health_check_path": "/",
              "health_check_interval_seconds": 35,
              "target_group_arn": default_target_group_arn,
              "target_type": "lambda",
              "matcher": {
                "http_code": "200"
              },
              "load_balancer_arns": [
                "arn:aws:elasticloadbalancing:us-east-1:12345678:loadbalancer/app/test/12345abc"
              ],
              "healthy_threshold_count": 5,
              "health_check_timeout_seconds": 30,
              "health_check_enabled": false,
              "unhealthy_threshold_count": 2,
              "target_group_name": "target_group"
            }
          ]
        }
      )
      aws_client.stub_responses(
        :describe_target_health,
        {
          "target_health_descriptions": [
            {
              "target": {
                "availability_zone": "all",
                "id": default_lambda_arn
              },
              "target_health": {
                "state": "unused",
                "reason": "Target.NotInUse",
                "description": "Target group is not configured to receive traffic from the load balancer"
              }
            }
          ]
        }
      )
    end

    it 'should create a hash from the response' do
      expect(target_group).to receive(:target_group_arn).and_return(default_target_group_arn).at_least(:once)
      expect(alb_target_group_attachment._target_group).to receive(:remote_resource).and_return(target_group).at_least(:once)

      remote_resource = alb_target_group_attachment.remote_resource_params

      expect(remote_resource[:_terraform_id]).to eq("#{default_target_group_arn}/#{default_lambda_arn}")
      expect(remote_resource[:_geo_id]).to eq("#{default_target_group_arn}:#{default_lambda_arn}")
      expect(remote_resource[:target_group_arn]).to eq(default_target_group_arn)
      expect(remote_resource[:target_id]).to eq(default_lambda_arn)
    end
  end
end
