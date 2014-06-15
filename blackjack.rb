#!/usr/bin/env ruby

require 'redis'

class Dealer

  def initialize(redis_instance)
    @@redis = redis_instance
    @game = 1
    @@redis.del('hand::dealer')
  end

  def draw
    newcard = @@redis.spop("deck::game::#{@game}")
    @@redis.rpush('hand::dealer', newcard)
  end

  def show_cards
    @@redis.lrange('hand::dealer', 0 , -1)
  end

  def show_second_card
    @@redis.lindex('hand::dealer', -1)
  end

  def self.set_game_number(number)
    @game = number
  end

  def score
    score = 0
    @@redis.lrange("hand::player_id::#{@@player_id}", 0, -1).each do |card|
      score += @@redis.get("#{card}").to_i
    end

    score
  end

  def score_second_card
    @@redis.get(@@redis.lindex('hand::dealer', -1))
  end
end


class Player

  def initialize(redis_instance)
    @@redis = redis_instance
    @@player_id = rand(10)
    @game = 1
    #@@redis.del('hand::player1')
  end

  def draw
    newcard = @@redis.spop("deck::game::#{@game}")
    @@redis.rpush("hand::player_id::#{@@player_id}", newcard)
  end

  def show_cards
    @@redis.lrange("hand::player_id::#{@@player_id}", 0, -1)
  end

  def self.set_game_number(number)
    @game = number
  end

  def score
    score = 0
    @@redis.lrange("hand::player_id::#{@@player_id}", 0, -1).each do |card|
      score += @@redis.get("#{card}").to_i
    end

    score
  end

end

@redis = Redis.new(:port => 62222)

#puts redis.get('foo')
#populate deck
def cards()
  deck_array = []
  suits = ['C', 'D', 'H', 'S']
  for num in 1..13
    suits.each do |suit|
      case "#{num}".to_i
      when 1
        deck_array << "A#{suit}"
        @redis.set("A#{suit}", 1)
      when 11
        deck_array << "J#{suit}"
        @redis.set("J#{suit}", 10)
      when 12
        deck_array << "Q#{suit}"
        @redis.set("Q#{suit}", 10)
      when 13
        deck_array << "K#{suit}"
        @redis.set("K#{suit}", 10)
      else
        deck_array << "#{num}#{suit}"
        @redis.set("#{num}#{suit}", "#{num}")
      end
    end
  end
  deck_array
end

def verify_deck(deck)
  return false if @redis.exists(deck) == 0
  if @redis.smembers(deck).sort != cards().sort
    @redis.del(deck)
    return false
  end

  return true
end

def create_deck(deck_name)
  @redis.sadd(deck_name, cards()) unless verify_deck(deck_name)
end

def remove_hands
  hands_array = @redis.keys('*').grep(/hand::/)

  hands_array.each do |hand|
    @redis.del(hand)
  end
end

remove_hands
#Create 52 card deck
create_deck('starter')

#Create new deck for game 1
@redis.sunionstore('deck::game::1', 'starter')

@redis.del("hand::*")

joe = Dealer.new(@redis)
dustin = Player.new(@redis)
#Dealer.new.draw

dustin.draw
#puts "Dustin: #{dustin.show_cards.join()}"

joe.draw

dustin.draw
puts "Dustin: #{dustin.show_cards.join(" ")}"
puts "Score: #{dustin.score}"

joe.draw
puts "Dealer: #{joe.show_second_card}"
puts "Score: #{joe.score_second_card}"

puts "Hit or stay?"
answer = gets.chomp

case "#{answer}"
when "h"
  dustin.draw
  puts "Dustin: #{dustin.show_cards.join(" ")}"
  puts "Score: #{dustin.score}"
else
puts "Dealer: #{joe.show_cards}"
puts "Score: #{joe.score_second_card}"
end


def cleanup()
  @redis.del('deck::game:1')
end

cleanup()
#@redis.del('deck') unless verify_deck
#@redis.sadd('deck', populate_deck()) if @redis.exists('deck
#puts @redis.smembers('deck')
