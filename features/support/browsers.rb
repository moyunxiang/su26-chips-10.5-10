# frozen_string_literal: true

# Selenium Driver Code:
# https://github.com/SeleniumHQ/selenium/tree/trunk/rb/lib/selenium/webdriver

# Original Source
# https://gist.github.com/bbonamin/4b01be9ed5dd1bdaf909462ff4fdca95
require 'capybara/rspec'
require 'selenium/webdriver'
require 'cucumber'
require 'active_support/all'

#### TODO: See if we can further simplify capybara setup.
# https://github.com/teamcapybara/capybara#drivers

# This returns a symbol representing the requested driver.
# By default this app selects a real browser for it's driver.
# We could speed up tests by using `rack_test`, but this doesn't work
# for JavaScript content and would require tagging scenarios with @javascript
def select_capybara_driver
  default_driver = :headless_chrome
  known_drivers = Capybara.drivers.names
  if ENV['DRIVER'].present?
    # be nice and accept 'Headless Chrome', spaces, etc.
    driver = ENV['DRIVER'].downcase.parameterize.underscore.to_sym
    unless known_drivers.include?(driver)
      puts "Unknown driver: \"#{driver}\".\nKnown drivers are: #{known_drivers.to_sentence}.\n"
      exit(1)
    end
    driver
  elsif ENV['GUI'].present?
    :chrome
  else
    default_driver
  end
end

### Google Chrome
chrome_options = Selenium::WebDriver::Chrome::Options.new
chrome_options.add_preference(:download, prompt_for_download: false,
                                  default_directory: '/tmp/downloads')

chrome_options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
end

Capybara.register_driver :headless_chrome do |app|
  chrome_options.add_argument('--headless=new')
  chrome_options.add_argument('--disable-gpu')
  chrome_options.add_argument('--no-sandbox')
  chrome_options.add_argument('--disable-dev-shm-usage')
  chrome_options.add_argument('--window-size=1440,900')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
end

#### Safari (macOS only.)
Capybara.register_driver :safari do |app|
  Capybara::Selenium::Driver.new(app, browser: :safari)
end

Capybara.register_driver :stp do |app|
  Selenium::WebDriver::Safari.technology_preview!
  Capybara::Selenium::Driver.new(app, browser: :safari)
end

### Firefox
Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(app, browser: :firefox)
end

Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.headless!
  Capybara::Selenium::Driver.new(app, browser: :firefox, options:)
end

Capybara.default_driver = select_capybara_driver
Capybara.javascript_driver = select_capybara_driver
puts "\nRUNNING CAPYBARA WITH DRIVER #{Capybara.default_driver}\n\n"
