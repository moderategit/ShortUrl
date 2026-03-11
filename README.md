# URL Shortener Microservice

A simple Ruby on Rails application that implements a URL shortening service.
This project was built as part of the CoinGecko Engineering written assignment.

## Features

**Web Interface**
- Simple form to enter target URLs
- Returns shortened URL, original URL, and page title
- Click tracking with geolocation

**URL Shortening**
- Generates random short paths (max 15 characters)
- Unique paths enforced in database
- Multiple short URLs can map to the same target
- Automatic page title extraction

**Visit Tracking & Analytics**
- Records each click/visit to a short URL
- Stores: IP address, timestamp, geolocation (latitude, longitude)
- Usage report page showing all clicks and their details

**Clean Architecture**
- Built with Rails 8
- SQLite database (easily swappable for PostgreSQL)
- RESTful API design
- Basic test coverage included

## Installation & Setup

### Requirements
- Ruby 3.0+
- Rails 8.0+
- SQLite3

### Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd CoinGecko
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Start the development server**
   ```bash
   rails server
   ```

5. **Visit the application**
   - Open [http://localhost:3000](http://localhost:3000) in your browser
   - Create your first short URL!

## Usage

### Creating a Short URL
1. Visit the home page
2. Enter a target URL (e.g., `https://example.com`)
3. Submit the form
4. You'll receive:
   - The short URL path (e.g., `http://localhost:3000/abc123`)
   - The original target URL
   - The page's title tag
   - Click count

### Sharing & Accessing
- Copy the short URL and share it publicly
- When someone visits the short URL, they're redirected to the target
- Each visit is logged with timestamp, IP, and location

### Viewing Statistics
1. Navigate to "View Usage Report" from the admin page
2. See all visits with:
   - Short URL path
   - Target URL
   - Visitor's IP address
   - Geolocation (country, latitude/longitude)
   - Timestamp of each visit

## Testing

Run the test suite:
```bash
rails test
```

The project includes:
- Unit tests for models (ShortUrl, Visit)
- Controller tests (create, redirect, index)
- Basic integration test coverage

## Deployment

### Heroku
```bash
git push heroku main
heroku run rails db:migrate
heroku open
```

### Other Platforms
- AWS Elastic Beanstalk
- DigitalOcean App Platform
- Any standard Rails hosting

**Important:** Set environment variables for production:
- `RAILS_ENV=production`
- `DATABASE_URL` (if using PostgreSQL)

## Project Structure

```
.
├── app/
│   ├── models/
│   │   ├── short_url.rb        # URL shortening logic
│   │   └── visit.rb             # Click tracking
│   ├── controllers/
│   │   ├── short_urls_controller.rb
│   │   └── visits_controller.rb
│   └── views/
│       ├── short_urls/          # Forms and displays
│       └── visits/              # Analytics/report
├── db/
│   ├── migrate/                 # Database migrations
│   └── schema.rb                # Generated schema
├── test/                        # Test suite
├── config/
│   └── routes.rb                # URL routing
└── README.md
```

## Configuration

### Geolocation
The app uses the `geocoder` gem for location lookup from IP addresses.
By default, it uses MaxMind's free GeoIP2 database.

To use a paid service or custom configuration, update `config/initializers/geocoder.rb`:
```ruby
Geocoder.configure(
  lookup: :google,
  api_key: ENV['GEOCODER_API_KEY']
)
```

### Database
Default is SQLite3. To use PostgreSQL:
1. Update `Gemfile`: replace `sqlite3` with `pg`
2. Update `config/database.yml` for PostgreSQL
3. Run `bundle install && rails db:create`

## Dependencies

- **rails** ~> 8.1 - Web framework
- **sqlite3** >= 2.1 - Database (can switch to PostgreSQL)
- **puma** >= 5.0 - Web server
- **nokogiri** ~> 1.15 - HTML parsing for title extraction
- **geocoder** ~> 1.8 - IP geolocation

## Notes

- This assignment prioritizes completeness and clarity over advanced features
- The implementation is suitable for API engineer (non-L3) expectations
- See [WIKI.md](WIKI.md) for architectural decisions, limitations, and scalability notes

## License

This project is provided as-is for the CoinGecko Engineering assignment.
