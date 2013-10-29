require 'test_helper'

class NotificationTest < ActiveSupport::TestCase

  test "criar notificacao" do
    params = {description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.day}}

    warning = Notification.new params
    assert warning.invalid?

    warning.title = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

    assert warning.valid?
    assert warning.save
  end

  test "nao cadastra sem data final" do
    params = {title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", schedule_attributes: {start_date: Date.today}}
    warning = Notification.new params

    assert warning.invalid?
    assert warning.errors.messages.has_key?(:"schedule.end_date")

    warning.schedule.end_date = Date.today
    assert warning.valid?
  end

end
