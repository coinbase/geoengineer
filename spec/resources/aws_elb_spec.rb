require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsElb") do
  common_resource_tests(GeoEngineer::Resources::AwsElb, 'aws_elb')

  describe "validations" do
    it 'should validate unique lb ports for listeners' do
      good_elb = GeoEngineer::Resources::AwsElb.new('type', 'id') {
        name "name"
        listener {
          instance_port 100
          instance_protocol 'tcp'
          lb_port 100
          lb_protocol 'tcp'
        }

        listener {
          instance_port 100
          instance_protocol 'tcp'
          lb_port 101
          lb_protocol 'tcp'
        }
      }

      expect(good_elb.errors.length).to eq 0

      bad_elb = GeoEngineer::Resources::AwsElb.new('type', 'id') {
        name "name"
        listener {
          instance_port 100
          instance_protocol 'tcp'
          lb_port 100
          lb_protocol 'tcp'
        }

        listener {
          instance_port 100
          instance_protocol 'tcp'
          lb_port 100
          lb_protocol 'tcp'
        }
      }

      expect(bad_elb.errors.length).to eq 1
    end
  end

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      elb = AwsClients.elb
      stub = elb.stub_data(
        :describe_load_balancers,
        {
          load_balancer_descriptions: [
            { load_balancer_name: 'name1' },
            { load_balancer_name: 'name2' }
          ]
        }
      )
      elb.stub_responses(:describe_load_balancers, stub)
      remote_resources = GeoEngineer::Resources::AwsElb._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
