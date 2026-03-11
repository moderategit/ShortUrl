class Visit < ApplicationRecord
  # Associations
  belongs_to :short_url

  # Validations
  validates :ip_address, presence: true
  validates :visited_at, presence: true

  # Geocoding: Automatically fetch latitude/longitude from IP address
  geocoded_by :ip_address, latitude: :latitude, longitude: :longitude
  after_validation :geocode, if: ->(obj) { obj.ip_address.present? && obj.ip_address_changed? }

  # Scopes
  scope :recent, -> { order(visited_at: :desc) }
end
