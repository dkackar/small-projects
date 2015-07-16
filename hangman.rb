=begin
  WebApp -> HangMan using Ruby/Sinatra
  Rules 
  	>> dict.txt is the dictionary used
  	>> Sort dict.txt on the lengths of the words
  	
  	>> Also create a Hash which lists the start and end index of
  	   words of length x  i.e
  	   start_level2 => 0 
  	   end_level2 => 5  
  	   The above indicates that 2 letter words start at index 0
  	   and end at index 5

  	>> Select level of play --> i.e. no of letters in the word
  	>> Select the new word at random i.e. between the indexes
  	   start_level<n> to end_level<n> --> both included

  	>> User gets a max of 5 tries
  	>> Pressing the restart will start the hangman game at
  	   current level but new word
  	>> Pressing the back will ask user to enter new difficulty level
  	   and start game with new word   
=end

require 'sinatra'
require 'sinatra/reloader'

#returns the counter to add to the no of tries based on if
#the letter was guessed correctly or not or a repeated guess
def check_guessed_letter(word,letter,available_letters)

	if word.include?(letter)
		return 0
	elsif !available_letters.include?(letter)
		return 0
	else
		$missed_letters.push(letter)
		return -1
	end
end 

#Checks the difficulty level entered 
def check_level(level)
	if level == nil || level.to_i < 2
		return "Enter the number for your difficulty level (Minimum 2)"
	end
	return "Difficulty level is #{level}"
end

def get_letter(letter,available_letters)
	if letter == nil || letter.strip.empty? ||\
	   (letter < "a" || letter > "z") 
		return [false,"Enter an alphabet [a-z]!"]
	elsif !available_letters.include?(letter)
		return [false,"Letter #{letter} already guessed"]
	end	
	return [true,""]
end

# sorts the dictionary text file based on lengths
# creates a hash for the start and end indices for words
# of a particular length
def array_sort(level)
	arr = []

	dictfile = File.open("dict.txt", 'r')
	while !dictfile.eof?
		line = dictfile.readline
		arr.push(line.chomp)
	end	

	sorted_arr = arr.sort {|x,y| x.length <=> y.length}
        sorted_arr_lengths = Hash.new()

	start = 0

	sorted_arr.each_with_index do |item, index|
		if item.length != start 
			sorted_arr_lengths["start_"+item.length.to_s] = index
			if start > 0
				sorted_arr_lengths["end_"+start.to_s] = index - 1
			end
			start = item.length
		end
	end
	sorted_arr_lengths["end_"+start.to_s] = arr.length - 1
	return [sorted_arr, sorted_arr_lengths]
end

# gets a new word based on the no of leters expected
def get_new_word(level)
	
	dict_array_details = array_sort(level)

	sorted_dict_array = dict_array_details[0]
	sorted_dict_lengths = dict_array_details[1]

	if sorted_dict_lengths["end_" + level.to_s] == nil
		message = "Could not find a #{level} letter word. Try again!"
	else
  		len = sorted_dict_lengths["end_" + level.to_s] - sorted_dict_lengths["start_" + level.to_s] + 1
		offset = sorted_dict_lengths["start_" + level.to_s]

		no = offset + rand(len)
		$word = sorted_dict_array[no].split("")
		puts "Debug: WORD is #{$word.join("").to_s}"

		$word.length.times do |i|
			$guessed_word[i] = "_"
		end	
  		$is_get_level = false
  		message = "Word has #{level} letters!"
  	end	
end

#define and initialize some globals
def initialize_globals(game)

	$available_letters = "abcdefghijklmnopqrstuvwxyz".split("")
        $missed_letters = []

	if game.downcase == "back" 
		$is_get_level = true
		$is_eof_game = false

	elsif game.downcase == "restart"
		$is_get_level = false
		$is_eof_game = false
	end

	$guessed_word = ["_"]
	$word = ""
end

#---------------- START of MAIN PROGRAM ------------------#
initialize_globals("back")
MAX_TRIES = 5
current_try = MAX_TRIES

#game = "back" for difficulty level, restart for sme level
#     = "current" for ongoing game 
game = "current"

#is true when max tries exhausted or game won	
$is_eof_game = false

#In case game is restarted, last level is played again
last_level = ""   

get '/' do

	level = params["level"]
 	letter = params["letter"]
 	game = params["game"]

  	if $is_get_level
 		message = check_level(level)
  	end 
  		
	if level.to_i > 1
		last_level = level
		message = get_new_word(level)
  	end

	return_value = get_letter(letter,$available_letters)

	letter_msg =  return_value[1]
	letter_valid = return_value[0]
    
	if letter_valid
           num = check_guessed_letter($word,letter,$available_letters)
           current_try += num
    
    	   if (ind = $available_letters.index(letter)) != nil
		     $available_letters[ind] =  "*"
     	   end
    
           ind_array = (0..$word.size - 1).select {|i| $word[i] == letter}
           ind_array.each {|i| $guessed_word[i] = letter}	
    end
 
    if current_try == 0
  	curent_try = MAX_TRIES
   	$is_eof_game = true
   	message = "YOU ARE SO DEAD! HOW HARD WAS IT TO GUESS\
   	           THE WORD #{$word.join("")} ?"
    elsif $guessed_word.include?("_") == false
   	$is_eof_game = true
   	message = "AWESOME! YOU HAVE YOUR LIFE BACK!" 
    end	
 	
    if game != nil
       if game.downcase == "back" || game.downcase == "restart"
		initialize_globals(game)
   	  	current_try = MAX_TRIES
     	  	message = ""
     	
     	  	if game.downcase == "restart"
     	  		level = last_level
		 	message = get_new_word(level)
	  	end 
	end  			  
    end

    erb :hm_index, :locals => {:level => level, :message => message, :letter => letter, :available_letters => $available_letters, :is_get_level => $is_get_level, :guessed_word => $guessed_word, :current_try => current_try, :is_eof_game => $is_eof_game, :game => game, :missed_letters => $missed_letters}
end
