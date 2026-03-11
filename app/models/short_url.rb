class ShortUrl < ApplicationRecord
  # Associations
  has_many :visits, dependent: :destroy

  # Validations
  validates :path, presence: true, length: { maximum: 15 }, uniqueness: true
  validates :target_url, presence: true
  validate :target_url_valid_uri

  # Callbacks
  before_validation :normalize_target_url
  before_validation :generate_path, if: :new_record?
  before_save :fetch_title, if: :target_url_changed?

  # Generates a unique short path (max 15 chars) for new records
  def generate_path
    self.path = loop do
      token = SecureRandom.urlsafe_base64(10)
      candidate = token.tr('+/=', '').first(15)
      break candidate unless ShortUrl.exists?(path: candidate)
    end
  end

  # Fetches the page title from the target URL
  def fetch_title
    return if target_url.blank?
    begin
      require 'open-uri'
      require 'nokogiri'
      html = URI.open(target_url, read_timeout: 5).read
      doc = Nokogiri::HTML(html)
      self.title = doc.at_css('title')&.text&.strip || target_url
    rescue => e
      Rails.logger.warn("Failed to fetch title for #{target_url}: #{e.message}")
      self.title = target_url
    end
  end

  # Builds the shortened URL
  def shortened_url
    Rails.application.routes.url_helpers.short_url_redirect_url(path: path, host: Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000')
  end

  private

  # Adds 'https://' to the target_url if it doesn't have a scheme
  def normalize_target_url
    return if target_url.blank?
    unless target_url =~ /\Ahttps?:\/\//
      self.target_url = "https://#{target_url}"
    end
  end

  # Validates that the target_url is a valid URI with scheme and host
  def target_url_valid_uri
    begin
      uri = URI.parse(target_url)
      errors.add(:target_url, "must be a valid URL") unless uri.scheme && uri.host
    rescue URI::InvalidURIError
      errors.add(:target_url, "must be a valid URL")
    end
  end
end
