require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'

Capybara.default_driver = :selenium
Capybara.run_server = false

module GetCount
  class WebScraper
    include Capybara::DSL

    def get_page_data(url, css)
      visit(url)
      doc = Nokogiri::HTML(page.html)
      doc.css(css).text
    end
  end
end
