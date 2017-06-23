#!/usr/bin/env ruby
# encoding: utf-8

# Copyright (c) 2017 by Fred George.
# May be used freely except for training; license required for training.

# For debugging...
# require 'pry'
# require 'pry-nav'

require 'securerandom'
require 'rapids_rivers'

# Publishes rental offers on an event bus on need
class RentalOffer
  attr_reader :service_name

  OFFER = 'car_rental_offer'

  def initialize(host_ip, port)
    rapids_connection = RapidsRivers::RabbitMqRapids.new(host_ip, port)
    @river = RapidsRivers::RabbitMqRiver.new(rapids_connection)
    # See river_test.rb for various functions River supports to aid in filtering, like:
    # @river.require_values("key", "value");  // Reject packet unless it has key:value pair
    # @river.require("key1", "key2");   # Reject packet unless it has key1 and key2
    # @river.forbid("key1", "key2");    # Reject packet if it does have key1 or key2
    # @river.interested_in("key1", "key2");  // Allows key1 and key2 to be queried and set in a packet
    # For any keys required, forbidden, or deemed interesting, accessor methods are created in Packet
    @river.require_values(need: OFFER)
    @river.forbid('solution')
    @service_name = 'supply_rental_offer_ruby_' + SecureRandom.uuid
  end

  def start
    puts " [*] #{@service_name} waiting for traffic on RabbitMQ event bus ... To exit press CTRL+C"
    @river.register(self)
  end

  def packet rapids_connection, packet, warnings
    puts " [<] Need of offer received"
    packet.solution = {
      text: 'discount',
      value: (1000 * rand()).to_i,
      likelihood: rand().round(2)
    }
    rapids_connection.publish packet
    puts " [>] Published offer:\n\t    #{packet.to_json}"
  end

  def on_error rapids_connection, errors
    #puts " [x] #{errors}"
  end

  private

    def offer_packet
      fields = { offer: OFFER }
      RapidsRivers::Packet.new fields
    end
end

RentalOffer.new(ARGV.shift, ARGV.shift).start
