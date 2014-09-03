module Digest
  module Helpers
    def self.init(commentable_class)
      @@commentable_class = commentable_class
      # http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
      @@commentable_content_type = commentable_class.name.split("::").last.gsub(/(.)([A-Z])/,'\1_\2').downcase
    end

    def content_objekt(content_id = Random::rand(1000..9999))
      RealSelf::Stream::Objekt.new(@@commentable_content_type, content_id)
    end

    def stream_activity(activity, owner = nil, reasons = [])
      owner = owner || RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      RealSelf::Stream::StreamActivity.new(
        owner,
        activity,
        reasons
      )
    end

    # comment activities
    def user_author_comment_activity(user_id=nil, comment_id=nil, parent_content_id=nil, parent_content_author_id=nil, prototype='user.author.comment')
      user_id = user_id || Random::rand(1000..9999)
      comment_id = comment_id || Random::rand(1000..9999)
      parent_content_id = parent_content_id || Random::rand(1000..9999)
      parent_content_author_id = parent_content_author_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'author',
        RealSelf::Stream::Objekt.new('comment', comment_id),
        RealSelf::Stream::Objekt.new(@@commentable_content_type, parent_content_id),
        { :parent_content_author => RealSelf::Stream::Objekt.new('user', parent_content_author_id)},
        SecureRandom.uuid,
        prototype
      )    
    end

    def user_reply_comment_activity(user_id=nil, comment_id=nil, parent_content_id=nil, parent_comment_id=nil, parent_comment_author_id=nil, parent_content_author_id=nil, prototype='user.reply.comment')
      user_id = user_id || Random::rand(1000..9999)
      comment_id = comment_id || Random::rand(1000..9999)
      parent_content_id = parent_content_id || Random::rand(1000..9999)
      parent_comment_id = parent_comment_id || Random::rand(1000..9999)
      parent_comment_author_id = parent_comment_author_id || Random::rand(1000..9999)
      parent_content_author_id = parent_content_author_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'author',
        RealSelf::Stream::Objekt.new('comment', comment_id),
        RealSelf::Stream::Objekt.new(@@commentable_content_type, parent_content_id),
        { :parent_comment_author => RealSelf::Stream::Objekt.new('user', parent_comment_author_id), 
          :parent_comment => RealSelf::Stream::Objekt.new('comment', parent_comment_id),
          :parent_content_author => RealSelf::Stream::Objekt.new('user', parent_content_author_id) },
        SecureRandom.uuid,
        prototype
      )    
    end

    def user_send_user_message_activity(user_id=nil, message_id=nil, recipient_id=nil, prototype='user.send.user_message')
      user_id = user_id || Random::rand(1000..9999)
      message_id = message_id || Random::rand(1000..9999)
      recipient_id = recipient_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'send',
        RealSelf::Stream::Objekt.new('user_message', message_id),
        RealSelf::Stream::Objekt.new('user', recipient_id),
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end    


    def dr_author_answer_activity(dr_id=nil, answer_id=nil, question_id=nil, topic_id=nil, prototype='dr.author.answer')
      dr_id = dr_id || Random::rand(1000..9999)
      answer_id = answer_id || Random::rand(1000..9999)
      question_id = question_id || Random::rand(1000..9999)
      topic_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', dr_id),
        'author',
        RealSelf::Stream::Objekt.new('answer', answer_id),
        RealSelf::Stream::Objekt.new('question', question_id),
        {:topic => RealSelf::Stream::Objekt.new('topic', topic_id)},
        SecureRandom.uuid,
        prototype
      )    
    end

    def dr_author_article_activity(dr_id=nil, article_id=nil, prototype='dr.author.article')
      dr_id = dr_id || Random::rand(1000..9999)
      article_id = article_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', dr_id),
        'author',
        RealSelf::Stream::Objekt.new('article', article_id),
        nil,
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end

    def dr_author_video_activity(dr_id=nil, video_id=nil, prototype='dr.author.video')
      dr_id = dr_id || Random::rand(1000..9999)
      video_id = video_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', dr_id),
        'author',
        RealSelf::Stream::Objekt.new('video', video_id),
        nil,
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end

    def dr_create_address_activity(dr_id=nil, address_id=nil, prototype='dr.create.address')
      dr_id = dr_id || Random::rand(1000..9999)
      address_id = address_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', dr_id),
        'create',
        RealSelf::Stream::Objekt.new('address', address_id),
        nil,
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end  

    def dr_create_offer_activity(dr_id=nil, offer_id=nil, prototype='dr.create.offer')
      dr_id = dr_id || Random::rand(1000..9999)
      offer_id = offer_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', dr_id),
        'create',
        RealSelf::Stream::Objekt.new('offer', offer_id),
        nil,
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end  

    def dr_update_dr_activity(dr_id=nil, prototype='dr.update.dr')
      dr_id = dr_id || Random::rand(1000..9999)
      offer_id = offer_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', dr_id),
        'update',
        RealSelf::Stream::Objekt.new('dr', dr_id),
        nil,
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end 

    def dr_upload_photo_activity(dr_id=nil, photo_id=nil, topic_id=nil, prototype='dr.upload.photo')
      dr_id = dr_id || Random::rand(1000..9999)
      photo_id = photo_id || Random::rand(1000..9999)
      topid_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', dr_id),
        'upload',
        RealSelf::Stream::Objekt.new('photo', photo_id),
        RealSelf::Stream::Objekt.new('topic', topic_id),
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end     

    def user_author_discussion_activity(user_id=nil, discussion_id=nil, topic_id=nil, prototype='user.author.discussion')
      dr_id = dr_id || Random::rand(1000..9999)
      discussion_id = discussion_id || Random::rand(1000..9999)
      topic_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'author',
        RealSelf::Stream::Objekt.new('discussion', discussion_id),
        RealSelf::Stream::Objekt.new('topic', topic_id),
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end

    def user_author_guide_activity(user_id=nil, guide_id=nil, topic_id=nil, prototype='user.author.guide')
      dr_id = dr_id || Random::rand(1000..9999)
      guide_id = guide_id || Random::rand(1000..9999)
      topic_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'author',
        RealSelf::Stream::Objekt.new('guide', guide_id),
        RealSelf::Stream::Objekt.new('topic', topic_id),
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end    

    def user_author_question_activity(user_id=nil, question_id=nil, topic_id=nil, prototype='user.author.question')
      dr_id = dr_id || Random::rand(1000..9999)
      question_id = question_id || Random::rand(1000..9999)
      topic_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'author',
        RealSelf::Stream::Objekt.new('question', question_id),
        RealSelf::Stream::Objekt.new('topic', topic_id),
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end

    def user_author_review_activity(user_id=nil, review_id=nil, dr_id=nil, topic_id=nil, prototype='user.author.review')
      dr_id = dr_id || Random::rand(1000..9999)
      review_id = review_id || Random::rand(1000..9999)
      topic_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'author',
        RealSelf::Stream::Objekt.new('review', review_id),
        RealSelf::Stream::Objekt.new('topic', topic_id),
        {:dr => RealSelf::Stream::Objekt.new('dr', dr_id)},
        SecureRandom.uuid,
        prototype
      )    
    end

    def user_author_review_entry_activity(user_id=nil, review_entry_id=nil, dr_id=nil, review_id=nil, prototype='user.author.review_entry')
      dr_id = dr_id || Random::rand(1000..9999)
      review_id = review_id || Random::rand(1000..9999)
      topic_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'author',
        RealSelf::Stream::Objekt.new('review_entry', review_entry_id),
        RealSelf::Stream::Objekt.new('review', review_id),
        nil,
        SecureRandom.uuid,
        prototype
      )    
    end

    def user_udpate_question_public_note_activity(user_id=nil, question_id=nil, topic_id=nil, prototype='user.update.question.public_note')
      user_id = user_id || Random::rand(1000..9999)
      question_id = question_id || Random::rand(1000..9999)
      topic_id = topic_id || Random::rand(1000..9999)

      RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('user', user_id),
        'update',
        RealSelf::Stream::Objekt.new('question', question_id),
        RealSelf::Stream::Objekt.new('topic', topic_id),
        {},
        SecureRandom.uuid,
        prototype
      )    
    end
  end
end