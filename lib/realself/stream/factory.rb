module RealSelf
  module Stream
    module Factory

      def self.from_hash content_type, hash
        case content_type
        when RealSelf::ContentType::ACTIVITY
          RealSelf::Stream::Activity.from_hash hash

        when RealSelf::ContentType::DIGEST_ACTIVITY
          RealSelf::Stream::Digest::Digest.from_hash hash

        when RealSelf::ContentType::FOLLOWED_ACTIVITY
          RealSelf::Stream::FollowedActivity.from_hash hash

        when RealSelf::ContentType::STREAM_ACTIVITY
          RealSelf::Stream::StreamActivity.from_hash hash

        else
          raise ContentTypeError, "unsupported content type: #{content_type}"
        end
      end


      def self.from_json content_type, json, validate = true
        case content_type
        when RealSelf::ContentType::ACTIVITY
          RealSelf::Stream::Activity.from_json json, validate

        when RealSelf::ContentType::DIGEST_ACTIVITY
          RealSelf::Stream::Digest::Digest.from_json json, validate

        when RealSelf::ContentType::FOLLOWED_ACTIVITY
          RealSelf::Stream::FollowedActivity.from_json json, validate

        when RealSelf::ContentType::STREAM_ACTIVITY
          RealSelf::Stream::StreamActivity.from_json json   #TODO:  Add schema validation support

        else
          raise ContentTypeError, "unsupported content type: #{content_type}"
        end
      end

    end
  end
end
