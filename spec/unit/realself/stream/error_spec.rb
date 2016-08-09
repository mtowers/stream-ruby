# require 'multi_json'
require 'spec_helper'

describe RealSelf::Stream::Error do

  before :each do
    @error = RealSelf::Stream::Error.new('TestError', 'sample error message')
  end

  describe "#new" do
    it "creates a new Error object" do
      expect(@error).to be_an_instance_of RealSelf::Stream::Error
    end
  end

  describe "#to_h" do
    it "creates a hash representation of the error" do
      # @error.to_h.should eql ({:type => 'TestError', :message => 'sample error message'})
      expect(@error.to_h).to eql ({:type => 'TestError', :message => 'sample error message'})
    end
  end

  describe "#==" do
    it "compares two errors" do
      other = RealSelf::Stream::Error.new('TestError', 'sample error message')

      expect(@error).to eql other

      other = RealSelf::Stream::Error.new('TestError2', 'sample error message 2')

      expect(@error).to_not eql other
    end

    it 'compares to nil' do
      expect(@error).to_not eql nil
    end

    it 'compares to other object types' do
      expect(@error).to_not eql RealSelf::Stream::Objekt.new('user', 1234)
      expect(@error).to_not eql 'string'
      expect(@error).to_not eql({:foo => 'bar'})
      expect(@error).to_not eql Exception.new('oops!')
    end
  end

  describe "#to_s" do
    it "converts an Error to a JSON string" do
      json = @error.to_s
      hash = MultiJson.decode(json)

      error = RealSelf::Stream::Error.new(hash['type'], hash['message'])
      expect(@error).to eql error
    end
  end

end