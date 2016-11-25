require_relative '../spec_helper'

describe("HasLifecycle") do
  it "should work" do
    class Life
      include HasLifecycle
      attr_reader :called_count
      after :initialize, -> { @called_count += 1 }
      def initialize
        @called_count = 0
        execute_lifecycle(:after, :initialize)
      end
    end

    class AfterLife < Life
      after :initialize, -> { @called_count += 10 }
    end

    life       = Life.new()
    after_life = AfterLife.new()
    expect(life.called_count).to eq 1
    expect(after_life.called_count).to eq 11
  end
end
