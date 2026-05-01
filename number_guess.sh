#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN() {
  echo "Enter your username:"
  read USERNAME

  if [[ -z $USERNAME ]]
  then
    return
  fi

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME';")
  if [[ -z $USER_ID ]]
  then
    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME');")
    if [[ $INSERT_USER_RESULT = "INSERT 0 1" ]]
    then
      echo "Welcome, $USERNAME! It looks like this is your first time here."
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME';")
    fi
  else
    IFS="|" read GAMES_PLAYED MIN_GUESS <<< $($PSQL "SELECT count(*), min(guess_count) FROM games WHERE name = '$USERNAME';")

    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $MIN_GUESS guesses."
  fi

  SECRET=$(GENERATE_RANDOM_NUMBER)
  echo "Secret is: $SECRET"
  
  GUESS_COUNT=0
  HANDLE_GUESS
  
}

GENERATE_RANDOM_NUMBER() {
  local number=$RANDOM
  let "number %= 1000 + 1"
  echo $number
}

HANDLE_GUESS() {
  if [[ ! $1 ]]
  then
    echo "Guess the secret number between 1 and 1000:"
  else
    echo $1
  fi
  read GUESS
  

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    HANDLE_GUESS "That is not an integer, guess again:"
    return
  fi

  ((GUESS_COUNT += 1))

  if [[ $SECRET -lt $GUESS ]]
  then
    HANDLE_GUESS "It's lower than that, guess again:"
    return
  fi

  if [[ $SECRET -gt $GUESS ]]
  then
    HANDLE_GUESS "It's higher than that, guess again:"
    return
  fi
  
  echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET. Nice job!"
  INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(name, guess_count) VALUES('$USERNAME', $GUESS_COUNT);")
}

MAIN
