# URL Shortener - Architecture & Design Decision Wiki

## Overview

This wiki documents the architectural decisions, design patterns, limitations, and scalability considerations for the URL Shortener microservice.

---

## 1. Short Path Generation Strategy

### Current Implementation

```ruby
def generate_path
  self.path = loop do
    token = SecureRandom.urlsafe_base64(10)
    candidate = token.tr('+/=', '').first(15)
    break candidate unless ShortUrl.exists?(path: candidate)
  end
end
```

**Approach:** Random base64 string, truncated to max 15 characters, with collision detection via database lookup.

### Why This Works

- **Simple:** Easy to understand and implement
- **URL-safe:** Uses alnum + dashes/underscores (no special chars)
- **Adequate namespace:** 64^15 theoretical possibilities
- **Unique enforcement:** Database constraint prevents collisions

### Limitations

1. **Database hit per creation:** Every new URL requires a DB lookup, creating a bottleneck at scale
2. **Non-monotonic:** Cannot predict or control assignment order
3. **Collision risk:** Entropy is good but not guaranteed; at 10M+ URLs daily this becomes an issue

### Scalability Workarounds

**For thousands of URLs/day (current):**
- Current approach is fine; DB lookup is negligible

**For millions of URLs/day (future growth):**
1. **Option A - Redis Counter + Base62**
   - Use Redis to maintain an atomic counter
   - Convert counter to base62 (alphanumeric)
   - Store in database with high confidence of uniqueness
   ```
   counter → base62(counter) → URL path
   ```

2. **Option B - Snowflake IDs**
   - Use Twitter's Snowflake algorithm (64-bit unique IDs)
   - Convert to base36/62 for shorter URL representation
   - Removes database collision check entirely

3. **Option C - Sharded Tables**
   - Partition `short_urls` table by path prefix
   - Each shard uses its own collision strategy
   - Parallelizes writes across multiple nodes

---

## 2. Page Title Extraction

### Current Implementation

```ruby
def fetch_title
  require 'nokogiri'
  html = URI.open(target_url, read_timeout: 5).read
  doc = Nokogiri::HTML(html)
  self.title = doc.at_css('title')&.text&.strip || target_url
rescue => e
  self.title = target_url
end
```

**Approach:** Synchronous HTTP request to fetch HTML, parse with Nokogiri, extract `<title>` tag.

### Why This Approach

- **User feedback:** User sees page title immediately in the response
- **Relevant metadata:** Title provides context about the shortened URL

### Limitations

1. **Blocks user request:** Network I/O is slow; slow sites delay URL creation
2. **Timeout risk:** If target site is down, creation fails (with fallback to URL)
3. **Resource intensive:** Every URL creation consumes bandwidth and CPU
4. **HTTPS issues:** Certificate errors, redirects, or timeouts can cause failures

### Scalability Workarounds

1. **Background Job (Best)**
   ```ruby
   # Immediate: create short URL with title = target_url
   # Async: fetch title in background and update later
   after_create :fetch_title_later
   
   def fetch_title_later
     FetchTitleJob.perform_later(self.id)
   end
   ```

2. **Caching Layer**
   - Cache titles in Redis by domain
   - Reuse cached titles for same domain URLs
   ```
   redis.get("title:example.com") # → "Example - Home"
   ```

3. **Title Cache DB**
   - Store domain → title mappings
   - Lookup before fetching
   ```
   DomainMetadata.find_by(domain: 'example.com')
   ```

---

## 3. Visit Tracking & Geolocation

### Current Implementation

```ruby
# In controller:
@short_url.visits.create!(
  ip_address: request.remote_ip,
  visited_at: Time.current
)

# In model:
geocoded_by :ip_address
after_validation :geocode
```

**Approach:** Record every click with IP; use geocoder gem to lookup country/lat/long.

### What Gets Stored

| Field | Type | Source |
|-------|------|--------|
| `ip_address` | String | `request.remote_ip` |
| `visited_at` | DateTime | `Time.current` |
| `country` | String | Geocoder lookup |

### Why This Approach

- **Complete tracking:** Timestamp + location gives full context
- **Opt-in privacy:** IPs logged but no user identification
- **Practical analytics:** Can measure geographic reach

### Limitations

1. **IP accuracy:** Geolocation by IP is ~80% accurate for city-level, variable for specific location
2. **Unbounded table growth:** Every click adds a row; tables grow very large quickly
3. **Geocoder API rate limits:** Third-party service may throttle requests
4. **Privacy concerns:** Storing IPs may violate GDPR/privacy regulations at scale

### Scalability Workarounds

1. **Sampling**
   ```ruby
   # Only log 10% of visits for high-traffic URLs
   if short_url.visits_today < 10_000 || rand < 0.1
     Visit.create!(...)
   end
   ```

2. **Aggregation**
   - Don't store individual visits
   - Increment counters: `short_url.visits_today`, `visits_by_country`, etc.
   ```ruby
   # Instead of: Visit.create(...)
   VisitCounter.increment(short_url_id, date, country)
   ```

3. **Time-series Database**
   - Use InfluxDB, Prometheus, or similar
   - Store click timeseries, not individual records
   ```
   metric: short_url_clicks
   tags: [short_url_id, country, date_hour]
   value: count
   ```

4. **TTL/Retention Policy**
   ```ruby
   # Delete visits older than 90 days
   Visit.where('created_at < ?', 90.days.ago).delete_all
   ```

---

## 4. URL Validation

### Current Implementation

```ruby
validate :target_url_valid_uri

private
def target_url_valid_uri
  begin
    URI.parse(target_url)
    if target_url !~ /\A#{URI::DEFAULT_PARSER.regexp[:ABS_URI]}\z/
      errors.add(:target_url, "must be a valid URL")
    end
  rescue URI::InvalidURIError
    errors.add(:target_url, "must be a valid URL")
  end
end
```

**Approach:** Parse URL with `URI` gem; validate against RFC ABS_URI pattern.

### Security Considerations

1. **SSRF Prevention**
   - Reject internal IP ranges: `127.0.0.1`, `10.0.0.0/8`, metadata servers
   ```ruby
   def target_url_valid_uri
     # ... existing code ...
     url_host = URI.parse(target_url).host
     raise "blocked host" if ['localhost', '127.0.0.1'].include?(url_host)
   end
   ```

2. **URL Redirect Attacks**
   - URLs are displayed as links; ensure escaping in views (Rails does this by default)
   - Validate that redirects don't point to phishing sites

3. **Protocol Validation**
   - Only allow HTTP/HTTPS (current regex does this)
   - Reject `javascript:`, `file://`, `data:` URIs

---

## 5. Database Schema & Indexing

### Migrations

```ruby
# short_urls table
create_table :short_urls
  t.string :path, null: false, index: unique
  t.string :target_url, null: false
  t.string :title
  t.timestamps

# visits table
create_table :visits
  t.references :short_url, foreign_key: true
  t.string :ip_address
  t.float :latitude, :longitude
  t.string :country
  t.datetime :visited_at
  t.timestamps
  add_index :visited_at
  add_index :short_url_id
```

### Current Indexes

| Table | Column | Type | Purpose |
|-------|--------|------|---------|
| `short_urls` | `path` | Unique | Prevent duplicates, fast lookup |
| `visits` | `short_url_id` | Foreign key | Navigate from short URL to visits |
| `visits` | `visited_at` | Ascending | Time-based queries, sorting |

### Performance Notes

- **Path lookup:** O(1) via unique index
- **Visit list:** O(log n) via sorted index on created_at
- **Geolocation:** O(n) if scanning all visits per URL; consider aggregating

### Future Indexes

At higher scale, add:
```ruby
add_index :short_urls, :created_at           # For recent URLs
add_index :visits, [:short_url_id, :visited_at]  # Composite for range queries
add_index :visits, :country                  # For geographic reports
```

---

## 6. Concurrency & Database Selection

### SQLite (Current)

**Pros:**
- Zero setup; file-based
- Great for development and small deployments
- Sufficient for < 100 requests/second

**Cons:**
- Write operations serialize; one writer at a time
- Poor for high concurrency (> 100 req/s)
- Locks entire database during writes

### PostgreSQL (Recommended for Production)

**Pros:**
- ACID compliance with row-level locking
- Multi-writer concurrency
- Can handle 1000+ req/s

**Migration path:**
```bash
# 1. In Gemfile, replace sqlite3 with pg
# 2. Update config/database.yml
# 3. Run: rails db:create db:migrate
```

---

## 7. Rate Limiting & Abuse Prevention

### Current State

No rate limiting implemented. Potential for abuse:
- User creates millions of short URLs
- Bot floods redirects
- DDoS via high-volume tracking

### Recommendations

1. **Create Rate Limit**
   ```ruby
   # Limit to 10 new URLs per minute per IP
   Rack::Attack.throttle('req/ip') do |req|
     req.ip if req.path == '/short_urls' && req.post?
   end
   ```

2. **Redirect Rate Limit**
   ```ruby
   # Prevent redirect DoS
   Rack::Attack.throttle('visits/ip') do |req|
     req.ip if req.path_info.match?(%r{^/[a-z0-9]{1,15}$})
   end
   ```

3. **User Quotas** (if authentication added)
   ```ruby
   user.short_urls.count >= user.quota && return error
   ```

---

## 8. Security Checklist

- [x] HTTPS in production (configure in web host)
- [x] URL validation (prevent SSRF/open redirect)
- [x] SQL injection prevention (using Rails ORM)
- [x] XSS prevention (Rails auto-escapes variables)
- [x] CSRF protection (enabled by default)
- [ ] Rate limiting (see section 7)
- [ ] User authentication (optional feature)
- [ ] Content Security Policy (optional)
- [ ] HSTS headers (configure in production)

---

## 9. Monitoring & Observability

### Metrics to Track

1. **Usage Metrics**
   - Unique short URLs created per day
   - Total clicks per day
   - Average clicks per URL

2. **Performance Metrics**
   - URL creation latency (including title fetch)
   - Redirect latency
   - Database query times

3. **System Metrics**
   - Database size growth
   - Visits table growth rate
   - Error rates (title fetch failures)

### Recommended Tools

- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Sentry** for error tracking
- **New Relic/DataDog** for APM

---

## 10. Scalability Summary

| Metric | Light Load | Medium Load | Heavy Load |
|--------|-----------|-------------|-----------|
| **URLs/day** | <1,000 | 10K-100K | 1M+ |
| **Clicks/day** | <10K | 100K-1M | 10M+ |
| **Database** | SQLite | PostgreSQL | PostgreSQL + Sharding |
| **Title fetch** | Sync | Async job | Queue + Retry logic |
| **Click tracking** | Individual rows | Aggregated | Time-series DB |
| **Deployment** | Single server | Multi-instance + LB | Kubernetes |

---

## Conclusion

The current implementation is well-suited for an API engineer assignment and handles typical workloads gracefully. Growth beyond prototypical scale would require the scalability strategies outlined above.

For questions or contributions, see the main README.md.
