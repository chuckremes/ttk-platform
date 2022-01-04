require 'oj'

# Reads in the configuration files for the strategy and delegates
# the ownership of each subsection to a dedicated class that knows
# how to interpret it. Details differ between vendors (e.g. ETrade,
# TDAmeritrade, etc.) so we load the appropriate vendor to handle
# the configuration.
#
module TTK
  module Platform
    module Config
      class Config
        def self.from_path(path)
          string = IO.read(path, mode: 'r')
          new(string)
        end

        attr_reader :contents

        def initialize(json_string)
          @contents = Oj.load(json_string)
        end

        def login
          @login ||= begin
                       case @contents['login']['vendor']
                       when 'etrade'
                         TTK::ETrade::Config::Login.new(@contents)
                       end
                     end
        end

        def accounts
          @accounts ||= begin
                          case @contents['accounts']['vendor']
                          when 'etrade'
                            TTK::ETrade::Config::Accounts.new(@contents)
                          end
                        end
        end

        def balances
          @balances ||= begin
                          case @contents['balances']['vendor']
                          when 'etrade'
                            TTK::ETrade::Config::Balances.new(@contents)
                          end
                        end
        end

        def positions
          @positions ||= begin
                           case @contents['positions']['vendor']
                           when 'etrade'
                             TTK::ETrade::Config::Positions.new(@contents)
                           end
                         end
        end

        def orders
          @orders ||= begin
                        case @contents['orders']['vendor']
                        when 'etrade'
                          TTK::ETrade::Config::Orders.new(@contents)
                        end
                      end
        end

        def strategy
          # need a fix for this... can't have platform dependant
          @strategy ||= LadderedHoldStrike::Config.new(@contents)
        end
      end
    end
  end
end
