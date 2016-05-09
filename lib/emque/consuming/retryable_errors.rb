module Emque
  module Consuming
    module RetryableErrors
      def retryable_errors
        config.retryable_errors
      end

      def retryable_error_limit
        config.retryable_error_limit
      end

      def delay_ms_time(retry_count)
        retry_count * 500 * ( 2 ** retry_count)
      end

      def retry_error(delivery_info, metadata, payload, ex)
        headers = metadata[:headers] || {}
        retry_count = headers.fetch("x-retry-count", 0)

        if retry_count <= retryable_error_limit
          logger.info("Retrying Retryable Error #{ex.class}, with count " +
                      "#{retry_count}")
          headers["x-retry-count"] = retry_count + 1
          headers["x-delay"] = delay_ms_time(retry_count)
          channel.ack(delivery_info.delivery_tag)
          delayed_message_exchange.publish(payload, { :headers => headers })
        else
          logger.info("Retryable Error: #{ex.class} ran out of retries at " +
                       "#{retry_count}")
          channel.nack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
