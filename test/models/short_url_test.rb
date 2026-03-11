require "test_helper"

class ShortUrlTest < ActiveSupport::TestCase
  def setup
    @short = ShortUrl.new(target_url: "https://example.com")
  end

  test "valid with target_url" do
    assert @short.valid?
  end

  test "generates path on create" do
    @short.save
    assert @short.path.present?
    assert @short.path.length <= 15
  end

  test "fetches title" do
    @short.target_url = "https://example.com"
    @short.save
    assert_equal "Example Domain", @short.title
  end
end
