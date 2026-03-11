require "test_helper"

class VisitTest < ActiveSupport::TestCase
  def setup
    url = ShortUrl.create!(target_url: "https://example.com")
    @visit = Visit.new(short_url: url, ip_address: "127.0.0.1", visited_at: Time.current)
  end

  test "valid visit" do
    assert @visit.valid?
  end

  test "belongs to short_url" do
    assert_equal ShortUrl.first, @visit.short_url
  end
end
