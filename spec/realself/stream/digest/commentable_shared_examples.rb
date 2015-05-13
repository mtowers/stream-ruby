RSpec.configure do |c|
  c.include Digest::Helpers
end

shared_examples "a commentable summary" do |commentable_class|

  before :each do
    Digest::Helpers.init(commentable_class)
  end

  describe "#new" do
    it "creates a new commentable activity summary" do
      activity = user_author_comment_activity_shared
      comment_target = activity.target

      summary = RealSelf::Stream::Digest::Summary.create(comment_target)
      expect(summary).to be_an_instance_of(commentable_class)
    end

    it "must be initialized with the proper object type" do
      object = RealSelf::Stream::Objekt.new('answer', 1234)
      expect{RealSelf::Stream::Digest::Summary.create(object)}.to raise_error
    end
  end

  describe "#add" do
    it "summarizes comments for a user subscribed to (following) a commentable content item" do
      activity = user_author_comment_activity_shared
      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      content = activity.target
      stream_activity = RealSelf::Stream::StreamActivity.new(owner, activity, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      hash = summary.to_h

      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 0

      stream_activity2 = RealSelf::Stream::StreamActivity.new(owner, user_author_comment_activity_shared(nil, nil, nil, content.id), [content])
      summary.add(stream_activity2)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 2
      expect(hash[:comment_reply].length).to eql 0
    end

    it "summarizes comments for the author of a commentable content item (notifications)" do
      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      activity = user_author_comment_activity_shared
      content = activity.target
      stream_activity = RealSelf::Stream::StreamActivity.new(owner, activity, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 0

      stream_activity2 = RealSelf::Stream::StreamActivity.new(owner, user_author_comment_activity_shared(nil, nil, nil, content.id), [content])
      summary.add(stream_activity2)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 2
      expect(hash[:comment_reply].length).to eql 0
    end

    it "summarizes comment replies when the author of a commentable content item is also the author of the parent comment" do
      # discussion author IS author of parent comment
      parent_content_author = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      parent_comment_author = parent_content_author
      parent_comment = RealSelf::Stream::Objekt.new('comment', Random::rand(1000..9999))
      parent_content = content_objekt()
      summary = RealSelf::Stream::Digest::Summary.create(parent_content)

      # first reply to parent comment
      activity = user_reply_comment_activity_shared(
        nil,
        nil,
        parent_comment.id,
        parent_content.type,
        parent_content.id,
        parent_comment_author.id)

      stream_activity = RealSelf::Stream::StreamActivity.new(parent_content_author, activity, [parent_content_author])

      summary.add(stream_activity)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 1
      expect(hash[:comment_reply][parent_comment.id]).to be_an_instance_of(Array)
      expect(hash[:comment_reply][parent_comment.id][0]).to eql parent_comment.to_h
      expect(hash[:comment_reply][parent_comment.id][1][:last]).to eql activity.object.to_h
      expect(hash[:comment_reply][parent_comment.id][1][:count]).to eql 1

      # second reply to same parent comment
      activity = user_reply_comment_activity_shared(
        nil,
        nil,
        parent_comment.id,
        parent_content.type,
        parent_content.id,
        parent_comment_author.id)

      stream_activity = RealSelf::Stream::StreamActivity.new(parent_content_author, activity, [parent_content_author])
      summary.add(stream_activity)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 1
      expect(hash[:comment_reply][parent_comment.id]).to be_an_instance_of(Array)
      expect(hash[:comment_reply][parent_comment.id][0]).to eql parent_comment.to_h
      expect(hash[:comment_reply][parent_comment.id][1][:last]).to eql activity.object.to_h
      expect(hash[:comment_reply][parent_comment.id][1][:count]).to eql 2

      # first reply to DIFFERENT parent comment
      parent_comment2 = RealSelf::Stream::Objekt.new('comment', Random::rand(1000..9999))
      activity = user_reply_comment_activity_shared(
        nil,
        nil,
        parent_comment2.id,
        parent_content.type,
        parent_content.id,
        parent_comment_author.id)

      stream_activity = RealSelf::Stream::StreamActivity.new(parent_content_author, activity, [parent_content_author])
      summary.add(stream_activity)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 2
      expect(hash[:comment_reply][parent_comment2.id]).to be_an_instance_of(Array)
      expect(hash[:comment_reply][parent_comment2.id][1][:last]).to eql activity.object.to_h
      expect(hash[:comment_reply][parent_comment2.id][1][:count]).to eql 1
    end

    it "summarizes comment replies for a user subscribed to (following) a commentable content item" do
      # user is NOT author of parent comment
      # stream_activity exists in :subscriptions stream only
      parent_content = content_objekt()

      activity = user_reply_comment_activity_shared(
        nil,
        nil,
        nil,
        parent_content.type,
        parent_content.id,
        nil)

      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      content = activity.extensions[:parent_content]
      stream_activity = RealSelf::Stream::StreamActivity.new(owner, activity, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      summary.add(stream_activity)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 0

      # user IS author of parent comment
      # stream_activity exists in :notifications stream
      # stream_activity exists in :subscriptions stream ???
      activity2 = user_reply_comment_activity_shared(nil, nil, nil, content.type, content.id, owner.id)
      content = activity2.extensions[:parent_content]
      stream_activity2 = RealSelf::Stream::StreamActivity.new(owner, activity2, [content])
      comment = activity2.object
      parent_comment = activity2.target

      summary.add(stream_activity2)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 1
      expect(hash[:comment_reply][parent_comment.id][1][:count]).to eql 1
      expect(hash[:comment_reply][parent_comment.id][1][:last]).to eql comment.to_h
    end

    it "fails to add a stream_activity that doesn't match the summary type"  do
      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      activity = user_author_comment_activity_shared()
      content = RealSelf::Stream::Objekt.new('video', 1234)
      stream_activity = RealSelf::Stream::StreamActivity.new(owner, activity, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      expect{summary.add(stream_activity)}.to raise_error


      activity = user_reply_comment_activity_shared
      stream_activity = RealSelf::Stream::StreamActivity.new(owner, activity, [content])
      expect{summary.add(stream_activity)}.to raise_error
    end

    it "rejects unknown activity types" do
      activity = user_author_comment_activity_shared()
      hash = activity.to_h
      hash[:prototype] = "cron.send.digest"
      activity = RealSelf::Stream::Activity.from_hash(hash)

      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      stream_activity = RealSelf::Stream::StreamActivity.new(owner, activity, [activity.target])
      summary = RealSelf::Stream::Digest::Summary.create(activity.target)
      expect{summary.add(stream_activity)}.to raise_error
    end
  end
end