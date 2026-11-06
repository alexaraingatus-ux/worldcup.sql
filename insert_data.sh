#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Read games.csv and insert the data into the database
GAME_VALUES=""
TEAM_VALUES=""

while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  if [[ $YEAR != "year" ]]
  then
    GAME_VALUES="${GAME_VALUES}(${YEAR}, '${ROUND}', '${WINNER}', '${OPPONENT}', ${WINNER_GOALS}, ${OPPONENT_GOALS}),"
    TEAM_VALUES="${TEAM_VALUES}('${WINNER}'),('${OPPONENT}'),"
  fi
done < games.csv

GAME_VALUES=${GAME_VALUES%,}
TEAM_VALUES=${TEAM_VALUES%,}

$PSQL "BEGIN;
INSERT INTO teams(name)
SELECT DISTINCT name
FROM (VALUES ${TEAM_VALUES}) AS incoming(name)
ON CONFLICT(name) DO NOTHING;

INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT game_data.year, game_data.round, winner.team_id, opponent.team_id,
       game_data.winner_goals, game_data.opponent_goals
FROM (VALUES ${GAME_VALUES}) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
JOIN teams AS winner ON winner.name = game_data.winner
JOIN teams AS opponent ON opponent.name = game_data.opponent;
COMMIT;"
