class VisitsController < ApplicationController
  def index
    # Display usage report: all visits with their details
    @visits = Visit.includes(:short_url).recent
    @total_visits = @visits.count
    @unique_short_urls = ShortUrl.count
    # Logger Debug Visit Data
    @visits.each do |visit|
      Rails.logger.debug("Visit Data - ID: #{visit.id}, Short URL: #{visit.short_url&.path}, IP: #{visit.ip_address}, Visited At: #{visit.visited_at}")
    end
  end
end
