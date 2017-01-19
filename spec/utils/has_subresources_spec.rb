require_relative '../spec_helper'

describe("HasSubResources") do
  it 'should add subresources with a block' do
    class WithSubResources
      include HasAttributes
      include HasSubResources
    end

    x = WithSubResources.new()
    x.one_sr {
      value 10
      sr {
        multi true
      }
    }

    # checks for assigned value
    expect(x.one_sr.value).to eq 10

    # checks for non assigned value
    expect(x.no_one_value).to eq nil

    # checks that there are multi level sub resources
    expect(x.one_sr.sr.multi).to eq true

    x.multi_sr {
      value 20
    }

    x.multi_sr {
      value 40
    }

    expect(x.all_multi_sr[0].value).to eq 20
    expect(x.all_multi_sr[1].value).to eq 40
  end
end
