#!/usr/bin/env ruby
# encoding: utf-8

# Copyright (c) 2017 by Fred George.
# May be used freely except for training; license required for training.

# For debugging...
# require 'pry'
# require 'pry-nav'

require 'securerandom'
require 'rapids_rivers'

# Understands the complete stream of messages on an event bus
class RentalNeed
  attr_reader :service_name

  NEED = 'car_rental_offer'

def initialize(host_ip, port)
    @rapids_connection = RapidsRivers::RabbitMqRapids.new(host_ip, port)
    @river = RapidsRivers::RabbitMqRiver.new(@rapids_connection)
    # See river_test.rb for various functions River supports to aid in filtering, like:
    # @river.require_values("key", "value");  // Reject packet unless it has key:value pair
    # @river.require("key1", "key2");   # Reject packet unless it has key1 and key2
    # @river.forbid("key1", "key2");    # Reject packet if it does have key1 or key2
    # @river.interested_in("key1", "key2");  // Allows key1 and key2 to be queried and set in a packet
    # For any keys required, forbidden, or deemed interesting, accessor methods are created in Packet
    @river.require_values(need: NEED)
    @river.interested_in('solution')
    @service_name = 'rental_need_ruby_' + SecureRandom.uuid
  end

  def start
    loop do
      @rapids_connection.publish need_packet
      puts " [<] Published a rental offer need on the bus:\n\t     #{need_packet.to_json}"
      sleep 5
    end
  end

  def packet rapids_connection, packet, warnings
    puts "Got an offer for a need!"
  end

  private

    def need_packet
      fields = { need: NEED, id: SecureRandom.uuid, user_id: [1, 2, 3, nil].sample }
      RapidsRivers::Packet.new fields
    end

end

RentalNeed.new(ARGV.shift, ARGV.shift).start
