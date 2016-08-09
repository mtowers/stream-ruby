require 'spec_helper'


describe RealSelf::Handler::Digest do

  class TestDigestHandler; end

  describe '#register_handler' do
    it 'calls Factory.register_handler with the correct parameters' do
      expect(RealSelf::Handler::Factory).to receive(:register_handler)
        .with(
        'user.create.thing',
        RealSelf::ContentType::DIGEST_ACTIVITY,
        TestDigestHandler)

      TestDigestHandler.send(:include, RealSelf::Handler::Digest)
      TestDigestHandler.send(:register_handler, 'user.create.thing')
    end
  end
end
