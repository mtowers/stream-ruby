describe RealSelf::Stream::FollowedObjekt do

  def followed_objekt(i)
    {
      :type       => "answer",
      :id         => i.to_s,
      :followers  =>
      [
        {
          :type => "user",
          :id   => "2345"
        },
        {
          :type => "user",
          :id   => "3456"
        }
      ]
    }
  end

  before :each do
    @followed_objekt = RealSelf::Stream::FollowedObjekt.from_json(MultiJson.encode(followed_objekt(1234)))
  end

  describe "#new" do
    it "takes 2 or 3 parameters and returns a FollowedObjekt" do
      followed_objekt = RealSelf::Stream::FollowedObjekt.new("answer", 1234)
      expect(followed_objekt).to be_an_instance_of RealSelf::Stream::FollowedObjekt
      expect(followed_objekt.followers.length).to eql 0

      followed_objekt = RealSelf::Stream::FollowedObjekt.new("answer", 1234,
        [RealSelf::Stream::Objekt.new('user', 2345),
          RealSelf::Stream::Objekt.new('user', 3456)]
      )
      expect(followed_objekt).to be_an_instance_of RealSelf::Stream::FollowedObjekt
      expect(followed_objekt.followers.length).to eql 2
    end
  end

  describe "#followers" do
    it "returns an array of Objekts" do
      expect(@followed_objekt.followers.length).to eql 2
      expect(@followed_objekt.followers).to include(
        RealSelf::Stream::Objekt.new('user', 2345),
        RealSelf::Stream::Objekt.new('user', 3456)
      )
    end
  end

  describe "#to_h" do
    it "returns a hash representing the FollowedObjekt" do
      expect(followed_objekt(1234)).to eql @followed_objekt.to_h
    end
  end

  describe '#==' do
    it 'compares two FollowedObjekts' do
      other = RealSelf::Stream::FollowedObjekt.from_json(MultiJson.encode(followed_objekt(1234)))
      expect(@followed_objekt).to eql other

      other = RealSelf::Stream::FollowedObjekt.from_json(MultiJson.encode(followed_objekt(12345)))
      expect(@followed_objekt).to_not eql other
    end

    it 'compares to nil' do
      expect(@followed_objekt).to_not eql nil
    end

    it 'compares to other object types' do
      expect(@followed_objekt).to_not eql RealSelf::Stream::Objekt.new('user', 1234)
      expect(@followed_objekt).to_not eql 'string'
      expect(@followed_objekt).to_not eql({:foo => 'bar'})
      expect(@followed_objekt).to_not eql Exception.new('oops!')
    end
  end

  describe "#hash" do
    it "supports hash key equality" do
      sa1 = RealSelf::Stream::FollowedObjekt.from_hash followed_objekt(1234)
      sa2 = RealSelf::Stream::FollowedObjekt.from_hash followed_objekt(1234)

      expect(sa1.object_id).to_not eql(sa2.object_id)

      e = {}
      e[sa2] = 1234
      expect(e.include?(sa1)).to eql(true)
    end
  end

  describe "#to_objekt" do
    it "converts a QueueItem in to an Objekt" do
      objekt = @followed_objekt.to_objekt
      expect(objekt).to be_an_instance_of RealSelf::Stream::Objekt
      expect(objekt.id).to eql "1234"
      expect(objekt.type).to eql "answer"
    end
  end

  describe "::from_json" do
    it "takes a JSON string and returns a FollowedObjekt" do
      expect(@followed_objekt).to be_an_instance_of RealSelf::Stream::FollowedObjekt
      expect(@followed_objekt).to be_an_kind_of RealSelf::Stream::Objekt
    end
  end

end
