require_relative '../spec_helper'

describe("NullObject") do
  it "should not error on methods" do
    no = NullObject.new()
    expect(no.not_a_method).to eq nil
  end
end

describe("NullObject.maybe") do
  it "should create a NullObject or not" do
    a = NullObject.maybe(nil)
    expect(a.not_a_method).to eq nil

    b = NullObject.maybe("b")
    expect(b.to_s).to eq "b"
  end
end
