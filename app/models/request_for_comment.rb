class RequestForComment < ActiveRecord::Base
    before_create :set_requested_timestamp

    def set_requested_timestamp
        self.requested_at = Time.now
    end
end
