require "test_helper"

class ShortUrlsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_short_url_url
    assert_response :success
  end

  test "create and show" do
    assert_difference('ShortUrl.count') do
      post short_urls_url, params: { short_url: { target_url: 'https://example.com' } }
    end
    url = ShortUrl.last
    assert_redirected_to short_url_url(url)
  end

  test "redirect action" do
    url = ShortUrl.create!(target_url: 'https://example.com')
    get short_path_url(url.path)
    assert_response :redirect
    assert_equal 'https://example.com', @response.redirect_url
  end
end
