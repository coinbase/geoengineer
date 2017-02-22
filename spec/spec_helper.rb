require 'rspec'
require_relative '../lib/geoengineer'
require 'pry'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

# https://ruby.awsblog.com/post/Tx2SU6TYJWQQLC3/Stubbing-AWS-Responses
AwsClients.stub!

# Common Resource Class Tests
# rubocop:disable Metrics/AbcSize
def init_test(clazz_name)
  it "should initialize and error" do
    env = GeoEngineer::Environment.new("name")
    res = env.resource(clazz_name, 'id') {
      some_value 10
      sub_resource {
        another_value 20
      }
    }
    expect(res.some_value).to eq 10
    expect(res.sub_resource.another_value).to eq 20
    expect(res.errors.length).to_not eq 0
  end
end

def mapping_tests(clazz, clazz_name)
  it 'should be identified from #get_resource_class_from_type' do
    gen_clazz = GeoEngineer::Environment.get_resource_class_from_type(clazz_name)
    expect(gen_clazz).to eq clazz
  end

  it 'should derive its type from its class with #type_from_class_name' do
    clazz_name = clazz.type_from_class_name
    expect(clazz_name).to eq clazz_name
  end
end

def fetch_empty_should_work(clazz)
  it 'should work with emtpy response' do
    remote_resources = clazz._fetch_remote_resources(nil)
    expect(remote_resources.length).to eq 0
  end
end

def common_resource_tests(clazz, clazz_name, fetch_remote = true)
  describe 'init test' do
    init_test(clazz_name)
  end

  describe "class mapping" do
    mapping_tests(clazz, clazz_name)
  end

  return unless fetch_remote

  describe "#_fetch_remote_resources" do
    fetch_empty_should_work(clazz)
  end
end

def name_tag_geo_id_tests(clazz)
  describe "_terraform_id and _geo_id" do
    it 'should get terraform_id from remote by matching geo_ids' do
      clazz.clear_remote_resource_cache
      remote_resources = [{ _geo_id: 'geo_id', _terraform_id: 't_id' }]
      allow(clazz).to(receive(:_fetch_remote_resources).and_return(remote_resources))
      res = clazz.new('type', 'id') {
        tags { Name 'geo_id' }
      }
      expect(res._geo_id).to eq 'geo_id'
      expect(res.remote_resource._terraform_id).to eq 't_id'
    end
  end
end
