require 'rubygems'
require 'sinatra'

#set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dawnsecret' 

BLACKJACK_AMT = 21
DEALER_STAY_AMT = 17
STARTING_CHIPS_AMT = 500

helpers do
  def calculate_total(cards)
    total = 0
    face_cards = ["jack", "queen", "king"]
    cards.each do |card|
      if face_cards.include?(card[1]) 
        total += 10
      elsif card[1] == "ace" # Use value of 11 for now. Change to 1 later if total > BLACKJACK_AMT
        total += 11
      else
        total += card[1].to_i
      end        
    end

    # Use value of 1 instead of 11 for Aces if the total > BLACKJACK_AMT
    cards.select{ |card| card[1] == "ace"}.count.times do
      total -= 10 if total > BLACKJACK_AMT
    end    
    total       
  end

  def card_img_src(card)
    image = "/images/cards/#{card[0]}_#{card[1]}.jpg"
  end 

  def declare_win(msg)
    @success = "Congratulations, #{session[:player_name]}! #{msg}"
    @game_over = true
    @show_game_buttons = false
    session[:player_chips] += session[:bet_amount]
  end

  def declare_loss(msg)
    @error = "Sorry, #{session[:player_name]}. #{msg}"
    @game_over = true
    @show_game_buttons = false
    session[:player_chips] -= session[:bet_amount]
  end

  def declare_tie(msg)
    @success = "The game has ended in a tie at #{msg}."
    @game_over = true
    @show_game_buttons = false
  end 
end 

before do
  @show_game_buttons = true
end  

get '/' do
  #session.clear
  if !session[:player_name]
    redirect '/new_player'
  else  
    redirect '/game' 
  end  
end

get '/new_player' do
  session[:player_chips] = STARTING_CHIPS_AMT
  erb :set_player_name
end  
  
post '/set_player_name' do
  if params[:player_name].empty?
    @error = "You must enter your name to start the game."
    halt erb(:set_player_name)
  end
  
  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:bet_amount] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "You must enter a bet amount to start this round."
    halt erb(:bet)

  elsif params[:bet_amount].to_i > session[:player_chips]
    @error = "You cannot bet more than you have."
    halt erb(:bet)      
  end
  session[:bet_amount] = params[:bet_amount].to_i
  redirect '/game' 
end     

get '/game' do
  SUITS = ["hearts", "diamonds", "clubs", "spades"]
  CARDS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
  session[:deck] = SUITS.product(CARDS).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_total] = 0
  session[:dealer_total] = 0
  
  #deal cards
  2.times do
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  end  

  session[:player_total] = calculate_total(session[:player_cards])
  session[:dealer_total] = calculate_total(session[:dealer_cards])
  
  #@info = "A new game has been dealt #{session[:player_name]}!"   
  erb :game
end

post '/player/hit' do
  session[:player_cards] << session[:deck].pop
  session[:player_total] = calculate_total(session[:player_cards])
  if session[:player_total] > BLACKJACK_AMT
    declare_loss("You have busted!")
  elsif session[:player_total] == BLACKJACK_AMT
    declare_win("You have hit blackjack!")
  end    
  erb :game
end  

post '/player/stay' do
  @success = "#{session[:player_name]} has decided to stay."
  @show_game_buttons = false
  @show_dealer_card_button = true
  redirect '/dealer/turn'
end  

get '/dealer/turn' do
  @show_game_buttons = false
  @dealer_turn = true
  session[:dealer_total] = calculate_total(session[:dealer_cards])
  if session[:dealer_total] >= DEALER_STAY_AMT
    if (session[:dealer_total] == BLACKJACK_AMT) && (session[:player_total] == BLACKJACK_AMT)
      declare_tie("#{BLACKJACK_AMT}") 
    elsif (session[:dealer_total] == BLACKJACK_AMT) 
      declare_loss("Dealer has hit blackjack!")
    elsif (session[:dealer_total] > session[:player_total]) 
      declare_loss("Dealer total of #{session[:dealer_total]} is higher than your total of #{session[:player_total]}.")
    elsif (session[:dealer_total] < session[:player_total]) 
      declare_win("Dealer must stay on #{DEALER_STAY_AMT} or higher. You have won with #{session[:player_total]}.")
    elsif (session[:dealer_total] == session[:player_total])
      declare_tie("#{session[:player_total]}") 
    end       
  else
    @show_dealer_card_button = true  
  end 

  erb :game
end    

post '/dealer/hit' do
  @dealer_turn = true
  @show_game_buttons = false
  @show_dealer_card_button = false
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_total] = calculate_total(session[:dealer_cards])

  if (session[:dealer_total] == BLACKJACK_AMT) && (session[:player_total] == BLACKJACK_AMT)
    declare_tie("#{BLACKJACK_AMT}") 
  elsif (session[:dealer_total] == BLACKJACK_AMT) 
    declare_loss("Dealer has hit blackjack!")
  elsif session[:dealer_total] > BLACKJACK_AMT
    declare_win("Dealer has busted!")
  elsif session[:dealer_total] > session[:player_total]
    declare_loss("Dealer has won! Dealer total of #{session[:dealer_total]} is higher than your total of #{session[:player_total]}.")
  elsif session[:dealer_total] >= DEALER_STAY_AMT
    declare_win("Dealer must stay on #{DEALER_STAY_AMT} or higher. You have won with #{session[:player_total]}.")
  else
    @show_dealer_card_button = true  
  end  

  erb :game
end  

get '/goodbye' do
  erb :goodbye
end  
  