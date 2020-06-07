require 'watir-webdriver'
require 'webdrivers'
require 'nokogiri'
require 'pry'

class Parser

  def self.start
    @vehiclelist = []
    @carbrand = ARGV[0].downcase
    @carmodel = ARGV[1].downcase
    @browser = Watir::Browser.new
    @browser.goto ENV['SITE1']

    Parser.prepare_page
    Parser.scrape_data
    Parser.check_next_page
    Parser.count_result
  end

  private 

  def self.count_result
    puts "Total records: #{@vehiclelist.flatten.count}"
  end

  def self.scrape_data
    htmlpage = Nokogiri::HTML.parse(@browser.html)
    table = htmlpage.css('#old_cars_list')
    @carname = table.css('tr > td[2]').map {|n| n.text.strip } 
    @carprice = table.css('tr > td[3]').map {|n| n.text.strip } 
    @caryear = table.css('tr > td[4]').map {|n| n.text.strip } 
    @cardmileage = table.css('tr > td[5]').map {|n| n.text.strip }
    @carlink = table.css('tr > td[2] > a').map {|n| n['href'] }
    export_data
    sleep 1
  end

  def self.export_data
    @data = [@carname, @carprice, @caryear, @cardmileage, @carlink ].transpose.map{|n,p,y,m,l| { name: n, price: p, year: y, mileage: m, link: l }}
    @vehiclelist.push(@data)
    sleep 1
  end

  def self.prepare_page
    @browser.span(:id => 'pseudo_link_inventory_trade').click
    select_brand = @browser.select_list(:id => 'car_brand_offer_trade_in')
    @select_content_brand = select_brand.options.map(&:text).map(&:strip).map(&:downcase)
    if @select_content_brand.index(@carbrand).nil?
      puts "No such brand name found."
      exit
    end
    brand_choose = @select_content_brand.index(@carbrand)
    @browser.select_list(:id => 'car_brand_offer_trade_in').option(index: brand_choose).click
    
    select_model = @browser.select_list(:id => 'car_model_offer_trade_in')
    @select_model_content = select_model.options.map(&:text).map(&:strip).map(&:downcase)
    if @select_model_content.index(@carmodel).nil?
      puts "No such model name found."
      exit
    end
    model_choose = @select_model_content.index(@carmodel)
    @browser.select_list(:id => 'car_model_offer_trade_in').option(index: model_choose).click
    @browser.button(:id => "big_input", :index => 3).click
    sleep 1
  end

  def self.check_next_page
    count = @browser.as(:class, "right").count
    while count == 1
      @browser.a(:class, "right").click
      sleep 1
      scrape_data
      count = @browser.as(:class => "right").count
    end
  end
end

Parser.start
