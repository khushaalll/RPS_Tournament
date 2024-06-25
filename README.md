# RPS_Tournament

## About the Project

I have implemented a Rock Paper Scissors (RPS) game tournament using Erlang. Multiple players participate in the tournament, each with a set number of credits. Players lose one credit for each lost match, and the last player with remaining credits wins the tournament.

## Game Logic Overview

1. **Starting a Game**:
    - Players send requests to other players to start a game.
    - Requests are made after a random delay (10-100 milliseconds) using `timer:sleep(N)`.

2. **Handling Invitations**:
    - Players can receive and accept game invitations unless they have no credits left.
    - Confirmed games are scheduled by the master process, which assigns a unique game ID.

3. **Playing the Game**:
    - Each player randomly selects an RPS move (rock, paper, or scissors) and sends it to the master process.
    - The master process determines the winner once both moves are received.

4. **Game Outcomes**:
    - Players lose one credit per loss; ties are resolved by replaying the game.
    - Disqualified players (zero credits) cannot start or accept new games but must reject incoming requests.

5. **Tournament End**:
    - The tournament concludes when only one player has remaining credits.
    - The master process notifies all players and displays a summary of the tournament.

## How to Run the Project

1. **Clone the repository**:
    ```bash
    git clone https://github.com/khushaalll/RPS_Tournament.git
    cd RPS_Tournament.git
    ```

2. **Compile and run**:
    - Ensure you have Erlang installed.
    - First compile the game.erl file using the command: "c(game).".
    - Similarly compile the players.erl file.
    - Run the program using the following command: "game:start(["Players.txt"]).".
    - Note: "Players.txt" is a text file containing the list of players and their credits.
    - Just copy paste the following to your Players.txt file:
      {jill,7}.
      {ahmad,8}.
      {tom,3}.
      {sam,4}.
