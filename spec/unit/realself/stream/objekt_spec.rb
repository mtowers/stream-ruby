describe RealSelf::Stream::Objekt do

  def example_hash
    { :type => 'User', :id => '1234' }
  end

  def example_hash_downcased
    example_hash.hmap { |k, v| [k, v.downcase] }
  end

  def example_json
    '{"type": "User", "id": "1234"}'
  end

  before :each do
    @objekt = RealSelf::Stream::Objekt.new('user', 1234)
  end

  describe '#new' do
    it 'takes two parameters and returns an Objekt object' do
      expect(@objekt).to be_an_instance_of RealSelf::Stream::Objekt
    end
  end

  describe '::from_hash' do
    it 'takes a hash and returns a new instance' do
      expect(@objekt).to eql RealSelf::Stream::Objekt.from_hash(example_hash)
    end

    it 'creates a new instance from a hash with underscore prefixed parameters' do
      expect(@objekt).to eql RealSelf::Stream::Objekt.from_hash({ :_type => 'User', :_id => '1234' })
    end
  end

  describe '::from_json' do
    it 'takes a JSON string and returns a new instance' do
      expect(@objekt).to eql RealSelf::Stream::Objekt.from_json(example_json)
    end
  end

  describe '#type' do
    it 'returns the correct type' do
      expect(@objekt.type).to eql 'user'
    end
  end

  describe '#id' do
    it 'returns the correct type' do
      expect(@objekt.id).to eql '1234'
    end
  end

  describe '#to_h' do
    it 'returns a hash' do
      expect(@objekt.to_h).to eql example_hash_downcased
    end
  end

  describe '#==' do
    it 'compares two objekts' do
      other = RealSelf::Stream::Objekt.new('user', 1234)
      expect(@objekt).to eql other

      other.id = '2345'
      expect(@objekt).to_not eql other
    end

    it 'compares to nil' do
      expect(@objekt).to_not eql nil
    end

    it 'compares to other object types' do
      expect(@objekt).to_not eql 'string'
      expect(@objekt).to_not eql({:foo => 'bar'})
      expect(@objekt).to_not eql Exception.new('oops!')
    end
  end

  describe '#to_s' do
    it 'returns a JSON string' do
      expect(@objekt.to_s).to eql MultiJson.encode(example_hash_downcased)
    end
  end

  describe '#hash' do

    it 'will equal hash value of a hash with the same content' do

      expected = {:type => 'user'.to_s, :id => 1234.to_s}.hash

      actual = RealSelf::Stream::Objekt.new('user', 1234).hash

      expect(actual).to eql expected
    end

    it 'supports hash key equality' do
      o1 = RealSelf::Stream::Objekt.new('user', 1234)
      o2 = RealSelf::Stream::Objekt.new('user', 1234)

      expect(o1.object_id).to_not eql(o2.object_id)
      e = {}

      e[o2] = 1234

      expect(e.include?(o1)).to eq(true)

    end

  end

  describe '::from_json' do
    it 'creates an objekt from a JSON string' do
      json = MultiJson.encode(example_hash)
      objekt = RealSelf::Stream::Objekt.from_json(json)
      expect(objekt).to be_an_instance_of RealSelf::Stream::Objekt
      expect(objekt).to eql @objekt
    end
  end
end
