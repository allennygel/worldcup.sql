#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
echo $($PSQL "TRUNCATE teams, games")


cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS

do
  if [[ $WINNER != "winner" && $OPPONENT != "opponent" ]]
  then

    # Insert teams if not found, using UNION ALL for efficiency
    $PSQL "
      INSERT INTO teams(name)
      SELECT '$WINNER' WHERE NOT EXISTS (SELECT 1 FROM teams WHERE name='$WINNER')
      UNION ALL
      SELECT '$OPPONENT' WHERE NOT EXISTS (SELECT 1 FROM teams WHERE name='$OPPONENT');
    "

    # Get team IDs after potential insertions (no need for separate queries)
     GET_TEAM=$($PSQL "SELECT name FROM teams WHERE name='$WINNER' OR name='$OPPONENT'")
     if [[ $GET_TEAM == "INSERT 0 1" || $GET_TEAM == "INSERT 0 2" ]]
     then
        echo Inserted into majors, $MAJOR
      fi
  fi


  

  # Get team IDs after potential insertions
  TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER' OR name='$OPPONENT'")

  # Insert game data
  INSERT_GAME=$($PSQL "
    INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
    VALUES ($YEAR, '$ROUND', (SELECT team_id FROM teams WHERE name='$WINNER'), (SELECT team_id FROM teams WHERE name='$OPPONENT'), $WINNER_GOALS, $OPPONENT_GOALS);
  ")

  # Check for errors in game insertion (optional)
  if [[ $? -eq 0 ]]; then
    echo "Game data inserted successfully."
  else
    echo "Error inserting game data: $INSERT_GAME"
  fi

done


