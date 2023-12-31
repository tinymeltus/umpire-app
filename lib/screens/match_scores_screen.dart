import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:the_umpire_app/widgets/set_scores.dart';

import '../model/MatchDetails.dart';
import '../model/ScoreHistory.dart';
import '../widgets/current_game_score.dart';
import '../widgets/players_names.dart';
import '../widgets/timer_widget.dart';

class MatchScoresScreen extends StatefulWidget {
  MatchScoresScreen({
    Key? key,
    required this.matchDetails,
    required this.numberOfSets,
    required this.teamAName,
    required this.teamBName,
  }) : super(key: key);

  final MatchDetails matchDetails;
  final int numberOfSets;
  final String teamAName;
  final String teamBName;

  // Declare scoreChangeHistory List
  final List<ScoreChangeEvent> scoreChangeHistory = [];

  @override
  _MatchScoresScreenState createState() => _MatchScoresScreenState();
}

class _MatchScoresScreenState extends State<MatchScoresScreen> {
  // Variables,
  //gameScores
  int scorePlayerA = 0;
  int scorePlayerB = 0;
  int gamesPlayerA = 0;
  int gamesPlayerB = 0;
  int setsWonPlayerA = 0;
  int setsWonPlayerB = 0;
  int numberOfSetsToWinMatch = 3; // TODO: change to dynamic value
  String matchWinner = '';
  bool isDeuce = false;

  // Variables for tracking games won per set
  int gamesWonByPlayerAInSet = 0;
  int gamesWonByPlayerBInSet = 0;

  List<List<int>> setScores = [];

  GameTimer _gameTimer = GameTimer();

  @override
  void initState() {
    super.initState();
    _gameTimer.startTimer();
  }

  @override
  void dispose() {
    // Reset preferred orientations to allow any orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // potrait screen orientation
    return Builder(builder: (context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Match Scores'),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    PlayerNameWidget(playerName: widget.teamAName),
                    GameScoreWidget(score: scorePlayerA),
                    SetScoresWidget(
                        //sets won  count
                        playerName: widget.teamAName,
                        setsWon: setsWonPlayerA),
                    Text('Games won: $gamesPlayerA'),
                  ],
                ),
                Row(
                  children: [
                    PlayerNameWidget(playerName: widget.teamBName),
                    GameScoreWidget(score: scorePlayerB),
                    SetScoresWidget(
                        //sets won  count
                        playerName: widget.teamBName,
                        setsWon: setsWonPlayerB),
                    Text('Games won: $gamesPlayerB'),
                  ],
                ),

                // Other widgets can be added here...
                Expanded(
                  child: ListView.builder(
                    itemCount: setScores.length,
                    itemBuilder: (context, index) {
                      final setScore = setScores[index];
                      final setNumber = index + 1;

                      return Text(
                          'Set $setNumber: ${setScore[0]} - ${setScore[1]}');
                    },
                  ),
                )
              ],
            ),

            // buttons
            Positioned(
              bottom: 0,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _incrementScore('A');
                      print(scorePlayerA);
                      _checkSetWinner();
                    },
                    child: Text('Point A'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _incrementScore('B');
                      print(scorePlayerB);
                      _checkSetWinner();
                    },
                    child: Text('Point B'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Update game logic
                      Navigator.pop(context);
                    },
                    child: const Text('Game'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Update set logic
                    },
                    child: const Text('Set'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Start Tiebreak logic
                    },
                    child: const Text('Tiebreak'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.scoreChangeHistory.isNotEmpty) {
                        final lastChange =
                            widget.scoreChangeHistory.removeLast();
                        setState(() {
                          scorePlayerA = lastChange.previousScorePlayerA;
                          scorePlayerB = lastChange.previousScorePlayerB;
                        });
                      }
                    },
                    child: const Text('Undo'),
                  ),
                ],
              ),
            ),
            // Timer
            Positioned(
              top: 0,
              right: 0,
              child: StreamBuilder<int>(
                stream: _gameTimer.timerStream, // Use the timerStream
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final seconds = snapshot.data;

                    // Convert seconds into a formatted time string (you can use your own format)
                    final minutes = seconds! ~/ 60;
                    final remainingSeconds = seconds % 60;
                    final timeString =
                        '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';

                    return Text('Game Time: $timeString');
                  } else {
                    return Text('Game Time: 00:00'); // Initial value
                  }
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  //methods
  //count game scores
  //scoring rules with duece situation included
  void _incrementScore(String player) {
    final lastChange = ScoreChangeEvent(scorePlayerA, scorePlayerB);
    widget.scoreChangeHistory.add(lastChange);

    if (player == 'A') {
      _handleScoringForPlayerA();
    } else if (player == 'B') {
      _handleScoringForPlayerB();
    }

    setState(() {});
  }

  void _handleScoringForPlayerA() {
    print(
        'Before scoring: Player A score: $scorePlayerA, Player B score: $scorePlayerB');

    if (scorePlayerA == 0) {
      scorePlayerA = 15;
    } else if (scorePlayerA == 15) {
      scorePlayerA = 30;
    } else if (scorePlayerA == 30) {
      scorePlayerA = 40;
    } else if (scorePlayerA == 40) {
      if (scorePlayerB == 40) {
        // Scores are tied at "deuce," increment by "Advantage" for Player A
        scorePlayerA = 45; // "45" means "Advantage" for Player A
        scorePlayerB = 40; // Reset Player B's score from 40 to 40
        isDeuce = true;
        print('Advantage for Player A');
      } else if (scorePlayerB == 45) {
        // Player B had "Advantage," scores are back to "deuce"
        scorePlayerA = 40;
        scorePlayerB = 40;
        isDeuce = true;
        print('Back to deuce');
      } else {
        // Player A wins the game
        gamesPlayerA++; // Increment game count for Player A
        scorePlayerA = 0; // Reset game score for Player A
        scorePlayerB = 0; // Reset game score for Player B
        print('Player A wins the game');
      }
    } else if (scorePlayerA == 45) {
      // Player A has "Advantage"
      scorePlayerA = 50; // "50" means "Game Point" for Player A
      print('Game Point for Player A');
    } else if (scorePlayerA == 50) {
      // Player A wins the game
      gamesPlayerA++; // Increment game count for Player A
      scorePlayerA = 0; // Reset game score for Player A
      scorePlayerB = 0; // Reset game score for Player B
      print('Player A wins the game');
    } else {
      // Handle other cases or show an error message
      print('Unknown case');
    }

    print(
        'After scoring: Player A score: $scorePlayerA, Player B score: $scorePlayerB');
  }

  void _handleScoringForPlayerB() {
    print(
        'Before scoring: Player A score: $scorePlayerA, Player B score: $scorePlayerB');

    if (scorePlayerB == 0) {
      scorePlayerB = 15;
    } else if (scorePlayerB == 15) {
      scorePlayerB = 30;
    } else if (scorePlayerB == 30) {
      scorePlayerB = 40;
    } else if (scorePlayerB == 40) {
      if (scorePlayerA == 40) {
        // Scores are tied at "deuce," increment by "Advantage" for Player B
        scorePlayerB = 45; // "45" means "Advantage" for Player B
        scorePlayerA = 40; // Reset Player A's score from 40 to 40
        isDeuce = true;
        print('Advantage for Player B');
      } else if (scorePlayerA == 45) {
        // Player A had "Advantage," scores are back to "deuce"
        scorePlayerA = 40;
        scorePlayerB = 40;
        isDeuce = true;
        print('Back to deuce');
      } else {
        // Player B wins the game
        gamesPlayerB++; // Increment game count for Player B
        scorePlayerA = 0; // Reset game score for Player A
        scorePlayerB = 0; // Reset game score for Player B
        print('Player B wins the game');
      }
    } else if (scorePlayerB == 45) {
      // Player B has "Advantage"
      scorePlayerB = 50; // "50" means "Game Point" for Player B
      print('Game Point for Player B');
    } else if (scorePlayerB == 50) {
      // Player B wins the game
      gamesPlayerB++; // Increment game count for Player B
      scorePlayerA = 0; // Reset game score for Player A
      scorePlayerB = 0; // Reset game score for Player B
      print('Player B wins the game');
    } else {
      // Handle other cases or show an error message
      print('Unknown case');
    }

    print(
        'After scoring: Player A score: $scorePlayerA, Player B score: $scorePlayerB');
  }

// Check for game winner and update gamesPlayerA or gamesPlayerB
// Reset game scores to deuce (40-40) when applicable
  void _checkGameWinner() {
    if (scorePlayerA == 40 && scorePlayerB == 40 && !isDeuce) {
      // Deuce situation
      isDeuce = true;
    } else if ((scorePlayerA == 45 || scorePlayerB == 45) && isDeuce) {
      // Advantage situation, check if it's from deuce
      isDeuce = false;
    } else if ((scorePlayerA == 50 || scorePlayerB == 50) && !isDeuce) {
      // Game over, declare winner and show message
      if (scorePlayerA == 50) {
        _showGameOutcomeMessage(widget.teamAName);
        gamesPlayerA++; // Increment game count for Player A
      } else {
        _showGameOutcomeMessage(widget.teamBName);
        gamesPlayerB++; // Increment game count for Player B
      }
      // Reset game score for both players
      scorePlayerA = 0;
      scorePlayerB = 0;
      // Reset deuce situation
      isDeuce = false;
      print(isDeuce);
    }
  }

  //toast message to show game winner
  void _showGameOutcomeMessage(String winnerName) {
    print('toast message');
    Fluttertoast.showToast(
      msg: 'Game over! $winnerName wins the game!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Check for set winner and update setsPlayerA or setsPlayerB
  // Reset game scores and gamesPlayerA/gamesPlayerB to deuce (40-40) when applicable
  void _checkSetWinner() {
    if (gamesPlayerA >= widget.matchDetails.numberOfGamesPerSet ||
        gamesPlayerB >= widget.matchDetails.numberOfGamesPerSet) {
      // Check if the set is won by Player A
      if (gamesPlayerA >= widget.matchDetails.numberOfGamesPerSet &&
          gamesPlayerA - gamesPlayerB >= 2) {
        setsWonPlayerA++; // Player A wins the set
        print('A won');
      }
      // Check if the set is won by Player B
      else if (gamesPlayerB >= widget.matchDetails.numberOfGamesPerSet &&
          gamesPlayerB - gamesPlayerA >= 2) {
        setsWonPlayerB++; // Player B wins the set
        print('B won');
      }

      // Reset game scores to 0-0 for the next set
      scorePlayerA = 0;
      scorePlayerB = 0;

      // Reset games won
      gamesPlayerA = 0;
      gamesPlayerB = 0;
    }
  }

// Check for match winner
  void _checkMatchWinner() {
    if (setsWonPlayerA == numberOfSetsToWinMatch) {
      matchWinner = 'A'; // Player A wins the match
    } else if (setsWonPlayerB == numberOfSetsToWinMatch) {
      matchWinner = 'B'; // Player B wins the match
    }
  }
}
