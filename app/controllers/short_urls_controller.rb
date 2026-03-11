class ShortUrlsController < ApplicationController
  before_action :set_short_url, only: [:show, :redirect]
  before_action :set_all_short_urls, only: [:show, :new]

  # Displays a list of all short URLs
  def index
    @short_urls = ShortUrl.all.order(created_at: :desc)
  end

  # Shows the form to create a new short URL
  def new
    @short_url = ShortUrl.new
  end

  # Creates a new short URL
  def create
    @short_url = ShortUrl.new(short_url_params)
    if @short_url.save
      redirect_to short_url_path(@short_url), notice: 'Short URL created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Shows details of a short URL
  def show
    # Display details: short path, target URL, title, click count
    @click_count = @short_url.visits.count
    @recent_visits = @short_url.visits.recent.limit(10)
  end

  # Redirects to the target URL and records the visit
  def redirect
    # Record the visit (click) with IP and timestamp
    Rails.logger.info("Redirecting short URL '#{@short_url.path}' to '#{@short_url.target_url}' from IP #{request.remote_ip}")
    @short_url.visits.create!(
      ip_address: request.remote_ip,
      visited_at: Time.current
    )
    # Redirect to the target URL
    redirect_to @short_url.target_url, allow_other_host: true
  end

  private

  # Finds the short URL by path or ID
  def set_short_url
    # Handle both /show/:id and /:path routes
    if params[:path].present?
      @short_url = ShortUrl.find_by!(path: params[:path])
    else
      @short_url = ShortUrl.find(params[:id])
    end
  end

  # Sets the total count of short URLs (used in views)
  def set_all_short_urls
    @short_urls = ShortUrl.all.count
  end

  # Permits only the target_url parameter
  def short_url_params
    params.require(:short_url).permit(:target_url)
  end
end
