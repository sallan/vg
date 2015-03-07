#!/usr/bin/ruby
#
# Read and summarize the data from your vanguard  accounts
#===========================================================================
require 'csv'


#
# We could use some objects to manipulate.  Something like:
#
# acct:
#   :type (retirement or no)
#   :acct_number
#   :holdings
#      funds []
#   :total_value
#
# fund:
#   :name
#   :symbol
#   :share
#   :price
#   :total_value
#   :expense_ratio
#   :class

class FundDB
  def initialize(filename)
    @type = {}
    File.open(filename).each do |line|
      line.chomp!
      symbol, type = line.split(':')
      @type[symbol] = type
    end
  end

  def to_s
    "DB contains #{@type.keys.length.to_s} funds"
  end

  def type(symbol)
    @type[symbol]
  end

  def print_all
    @type.each do |t|
      puts "#{t[0]}: #{t[1]}"
    end
    return
  end
end

class Fund
  attr_reader :symbol, :name, :value 
  attr_accessor :price, :shares

  def initialize(name, symbol, shares=0, price=0)
    @name = name
    @symbol = symbol
    @shares = shares.to_f
    @price = price.to_f
  end

  def value
    price * shares
  end

  def to_s
    format("%s %10.2f %10.2f %10.2f   %s", symbol, shares, price, value, name)
  end
end

class Account
  attr_accessor :name, :funds

  def initialize(name, funds=[])
    @name = name
    @funds = funds
  end

  def total_value
    funds.inject(0) {|sum, f| sum += f.value}
  end

  def to_s
    format "%s: %.2f", name, total_value
  end

  def display_funds
    funds.each {|f| puts f}
  end
end

class VanguardAccount < Account
  # Constants for field names
  $ACCT_NUMBER = 'Account Number'
  $FUND_NAME = 'Investment Name'
  $SYMBOL = 'Symbol'
  $PRICE = 'Share Price'
  $SHARES = 'Shares'
  $TOTAL = 'Total Value'

  def load_funds(file)
    CSV.foreach(file, :headers => true, :skip_blanks => true) do |row|
      # There are 2 sets of  data in the downloaded file. Stop when we 
      # get to the second header line
      break if row[$ACCT_NUMBER] !~ /^\d/
      funds << Fund.new(row[$FUND_NAME], row[$SYMBOL], row[$SHARES], row[$PRICE])
    end
  end
end

def get_all_vg_funds
  # Maybe, someday...
  all_vg_funds_url = 'https://investor.vanguard.com/mutual-funds/all-vanguard-funds'
  all_vg_funds_url = 'https://investor.vanguard.com/mutual-funds/all-vanguard-funds#tab=general'
end

# def print_fund(r)
#   puts "#{r[$SYMBOL]}  #{format("%10.2f", r[$TOTAL])}  #{r[$FUND_NAME]}"
# end


fund_db = FundDB.new("investment-types.dat")
v = VanguardAccount.new("Vanguard Non-Retirement", fund_db)
v.load_funds("non-ira.csv")
v.display_funds
