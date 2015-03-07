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

  def allocations(funds_db)
    allocations = Hash.new(0)

    funds.each do |fund|
      fund_type = funds_db.type(fund.symbol)
      allocations[fund_type] += fund.value
    end
    allocations
  end

  def display_allocations(funds_db)
    asset_classes = Hash.new(0)
    stocks = ["DS", "IS"]
    bonds = ["DB", "IS"]
    
    allocations = self.allocations(funds_db)
    total = total_value
    total_percent = 0
    printf("%6s : %10s %8s\n", "Type", "Value", "Perc")
    puts '=' * 30
    allocations.each do |type, value|
      percent = 100 * (value / total)
      total_percent += percent
      printf("%6s : %10.2f %8.2f\n", type, value, percent)

      # Combine stocks and bonds
      if stocks.include?(type)
        asset_classes['Stocks'] += percent
      elsif bonds.include?(type)
        asset_classes['Bonds'] += percent
      else
        asset_classes['Other'] += percent
      end
    end

    puts '=' * 30
    printf("%6s : %10.2f %8.2f\n\n", ' ', total, total_percent)

    puts "Summary"
    puts '=' * 30
    asset_classes.each do |type, percent|
      printf("%6s : %8.2f\n", type, percent)
    end
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
      # The data we want starts with this header line:
      #
      # Account Number,Investment Name,Symbol,Shares,Share Price,Total Value,
      #
      # and ends when we get to the next header line (or eof)

      # Decide it was just easer for now to hand edit the downloaded file.
      # I know, lame.
      # if row.start_with('Account Number,Investment Name,Symbol,Shares')
      #   data_found = true
      #   next
      # end

      # when we no longer see an account number, we're done
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


fund_db = FundDB.new("investment-types.dat")
v = VanguardAccount.new("Vanguard - All Accounts")
# v.load_funds("non-ira.csv")
v.load_funds("vg-all.csv")
#v.display_funds
# puts v

v.display_allocations(fund_db)
