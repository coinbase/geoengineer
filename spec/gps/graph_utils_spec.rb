require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS::GraphUtils do
  let(:old) do
    {
      'my/project' => {
        'my-account' => {
          'my-configuration' => {
            'service' => {
              'main' => {
                'foo' => true
              }
            }
          }
        }
      }
    }
  end

  let(:new) do
    {
      'my/project' => {
        'my-account' => {
          'my-configuration' => {
            'service' => {
              'main' => {
                'foo' => false,
                'bar' => true
              }
            }
          }
        }
      }
    }
  end

  it 'flattens properly' do
    output = GeoEngineer::GPS::GraphUtils.flatten(old)
    expected = { 'my/project.my-account.my-configuration.service.main.foo' => true }
    expect(output).to eq expected
  end

  it 'diffs properly' do
    old_flat = GeoEngineer::GPS::GraphUtils.flatten(old)
    new_flat = GeoEngineer::GPS::GraphUtils.flatten(new)
    output = GeoEngineer::GPS::GraphUtils.difference(old_flat, new_flat)
    expected = [
      {
        action: "~",
        key: "my/project.my-account.my-configuration.service.main.foo",
        value: false
      },
      {
        action: "+",
        key: "my/project.my-account.my-configuration.service.main.bar",
        value: true
      }
    ]
    expect(output).to eq expected
  end
end
