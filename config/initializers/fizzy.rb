FizzyApiClient.configure do |config|
  config.api_token = ENV["FIZZY_API_TOKEN"]
  config.account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
end
