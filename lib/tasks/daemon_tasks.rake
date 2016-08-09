
require 'base64'
require 'realself/stream'
require 'bunny'

module RealSelf
  module Daemon
    module RakeTasks
      def self.process_errors rmq_url, queue_name, content_type, limit=nil
        connection = Bunny.new rmq_url
        connection.start

        error_queue_name = "#{queue_name}-error"

        ch = connection.channel
        error_queue = ch.queue(error_queue_name, :durable => true)

        limit         = error_queue.message_count if limit.to_i <=  0
        message_count = [limit.to_i, error_queue.message_count].min
        processed     = 0;

        puts("#{error_queue_name} size: #{message_count}")

        consumer = Bunny::Consumer.new(ch, error_queue, ch.generate_consumer_tag, false, true)

        if 0 < message_count
          consumer.on_delivery do |delivery_info, properties, payload|
            begin
              # attempt to parse the original message out of the error message wrapper
              message   = JSON.parse(payload, :symbolize_names => true)
              payload   = Base64.decode64(message[:payload])
              puts "replaying activity:  #{payload}"
              activity  = RealSelf::Stream::Factory.from_json(content_type, payload)

              # publish it back to the originating queue
              publish_queue = ch.queue(queue_name,
                :durable => true,
                :arguments => {
                  :'x-dead-letter-exchange' => "#{queue_name}-retry"
                  })

              publish_queue.publish(activity.to_s, {:content_type => content_type})

              # ack the message
              ch.acknowledge(delivery_info.delivery_tag, false)

            rescue StandardError => se
              puts "failed to parse message:  #{payload.to_s}"
              puts "#{se.message}\n#{se.backtrace}"

              # reject the message and requeue it in the error queue
              ch.reject(delivery_info.delivery_tag, true)

            ensure
              processed += 1

              puts "processed #{processed}/#{message_count}"

              if message_count <= processed
                consumer.cancel
                break
              end
            end
          end

          error_queue.subscribe_with(consumer, {:block => true})
        end

        puts "processed #{message_count} errors"

        ch.close
        connection.stop
      end
    end
  end
end

desc "Replay messages from an error queue"
task :replay_error_queue, :rmq_url, :original_queue_name, :content_type, :limit do |t, args|
  RealSelf::Daemon::RakeTasks.process_errors args[:rmq_url], args[:original_queue_name], args[:content_type], args[:limit]
end
