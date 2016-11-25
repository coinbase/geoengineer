require 'spec_helper'
require 'open3'

describe 'rubocop' do
  it 'should validate the code style' do
    puts ""
    puts "Starting Rubocop Scan"
    stdout, _stderr, status = Open3.capture3('bundle exec rubocop')
    expect(status.success?).to eq(true), stdout
    puts "Finished Rubocop Scan"
    puts ""
  end
end
