// game_state.dart
// Barrett Koster 2025

import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "said_state.dart";

// This is where you put whatever the game is about.

const int BOARD_SIZE = 15;

// For now this is simply a letter.  In the future we
// could add scoring information, 'double letter' etc.
class Space
{
  String letter;
  Space( this.letter );
}

class GameState
{
  bool iStart; // true iff this player gets the first turn.
  
  List<String> tray; // up to 7 letters you can place on the board
  List<List<Space>> board; // where the letters are played
     // the order is a column of rows
  List<String> bag; // letters left to be used

  // phase really controls the flow of the game.  Each phase allows
  // certain actions, and when you do an action, it potentially advances
  // the phase to something else.
  int phase; // 0=not my turn, 1=my turn, ready to put letters, 2=refill the tray
             // and send turn to other player (phase=0 for this Player).
             // 3=refill the tray and go to phase 1 (you are first player)

  // mover is also a flow controller, just two states, letter or blank.  
  String mover; // a letter that is being moved from tray to board.
                // "" if not in moving process.
  
  int score; // just a letter count at this point.

 
  GameState( this.iStart, this.score,   
            { required this.board, required this.bag,
              required this.tray, required this.phase,
              required this.mover,
            } 
           );

  // This constructor only needs to know whether you are the 
  // first player or not.  Everything else is the same for
  // all players all games.
  GameState.init( this.iStart )
  : board = boardInit(), bag = bagInit(), 
    tray = [], phase=iStart?3:2, mover='',
    score = 0
  ;

  // builds a blank board
  static List<List<Space>> boardInit()
  { List<List<Space>> b = [];
    for ( int y=0; y<BOARD_SIZE; y++ )
    { List<Space> row = [];
      for ( int x=0; x<BOARD_SIZE; x++ )
      {
        row.add(Space(""));
      }
      b.add(row);
    }
    return b;
  }

  // initial letter bag
  // note: we do not store the point values for letters.  
  // All letters are worth one point.
  static List<String> bagInit()
  { /* 0 points: blank x2
      1 point: E ×12, A ×9, I ×9, O ×8, N ×6, R ×6, T ×6, L ×4, S ×4, U ×4
      2 points: D ×4, G ×3
      3 points: B ×2, C ×2, M ×2, P ×2
      4 points: F ×2, H ×2, V ×2, W ×2, Y ×2
      5 points: K ×1
      8 points: J ×1, X ×1
      10 points: Q ×1, Z ×1
    */
    return ["a","a","a","a","a","a","a","a","a",
            "b","b","c","c","d","d","d","d",
            "e","e","e","e","e","e","e","e","e","e","e","e",
            "f","f","g","g","g","h","h",
            "i","i","i","i","i","i","i","i","i","j","k",
            "l","l","l","l","m","m","n","n","n","n","n","n",
            "o","o","o","o","o","o","o","o",
            "p","p","q","r","r","r","r","r","r",
            "s","s","s","s","t","t","t","t","t","t",
            "u","u","u","u","v","v","w","w","x","y","y","z"
           ];
  }
}

// This is the main controller for GameState.  
class GameCubit extends Cubit<GameState>
{
  static final String d = ".";
  GameCubit( bool myt ): super( GameState.init( myt )); 

  // move a random letter from the bag to this player's tray.
  // and send a message to the other player's program that this
  // letter is no longer in the bag.
  void grab( BuildContext context  )
  { int le = state.bag.length; 
    if ( le > 0 ) // if bag is not empty ...
    {
      int pickn = Random().nextInt(le);
      List<String> b = state.bag;
      String ch = b[pickn];
      b.remove(ch); // take out of the bag
      List<String> t = state.tray; 
      t.add(ch); // put into the tray
      SaidCubit yc = BlocProvider.of<SaidCubit>(context);
      yc.say("bag $ch", context); // tell the other Player.
      // note: the other program knows, but the person does not.

      emit( GameState
            ( state.iStart,state.score,
              board: state.board, bag: b, tray: t,
              phase: state.phase, mover:""
            )
          );
    }
  }

  // a player just clicked on a letter in their tray.  This letter
  // is now a mover.  We will find out where it is going on the
  // next click (a different function).
  void startMove( String m )
  { emit
    ( GameState
      (state.iStart,state.score, // state.myTurn,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: state.phase, mover:m
      )
    );
  }

  // The player just clicked on a board square.  Put the mover
  // letter there and tell the other player's program.  
  void endMove( int y, int x, BuildContext context )
  { List<List<Space>> b = state.board;
    b[y][x] = Space(state.mover); // put the mover-letter in that Space.
    List<String> t = state.tray;
    t.remove(state.mover); // take it out of the tray

    SaidCubit sc = BlocProvider.of<SaidCubit>(context); // tell the other side
    sc.say("place ${state.mover} $y $x", context);
    
    emit
    ( GameState
      (state.iStart,state.score+1,
           board: b, bag: state.bag, tray: t,
           phase: state.phase, mover:""
      )
    );
  }

  // change state to phase 2.  that will lead to refilling the tray and
  // switching to the other players turn.
  // This function COULD have just filled the tray HERE, sending messages for each
  // letter grabbed, and then sent a switchUser message.  Instead phase==2
  // make the Player page load one character and emits, so it rebuilds a lot. Hmmm.
  void refill()
  { emit
    ( GameState
      (state.iStart,state.score, 
           board: state.board, bag: state.bag, tray: state.tray,
           phase: 2, mover:""
      )
    );
  }

  // tell other user it is THEIR turn and set our phase=0 (ie not our turn)
  void switchUser( BuildContext context )
  { SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    sc.say("yourturn",context);
    emit
    ( GameState
      ( state.iStart,state.score, // state.myTurn,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: 0, mover:""
      )
    );
  }

  // set our own phase=1 (no message needed).
  // This only gets called for the first turn of the first player,
  // i.e, the first player fills their tray and keeps the turn,
  // but every other time, when you fill your tray you give the
  // turn to the other player.
  void keepUser()
  { emit
    ( GameState
      (state.iStart,state.score, // state.myTurn,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: 1, mover:""
      )
    );
  }

  // incoming messages are sent here for the game to do
  // whatever with.  Messages we handle:
  // "bag X" where X is a letter ... remove X from the bag.
  // "place X y x" puts letter X at coords y,x
  // "yourturn"  tells us it is OUR turn.
  void handle( String msg )
  { List<String> parts = msg.split(" ");
    if ( parts[0] == "bag" )
    { List<String> b = state.bag; // copy of ref to the bag we are about to change
      b.remove(parts[1]);
      emit
      ( GameState
        ( state.iStart,state.score, 
          board: state.board, bag: b, tray: state.tray,
          phase: state.phase, mover:""
        )
      );
    }
    else if ( parts[0] == "place")
    { String m = parts[1];
      int y = int.parse(parts[2]);
      int x = int.parse(parts[3]);
      List<List<Space>> b = state.board;
      b[y][x] = Space(m);
      emit
      ( GameState
        ( state.iStart,state.score, 
          board: b, bag: state.bag, tray: state.tray,
          phase: state.phase, mover:""
        )
      );  
    }
    else if ( parts[0]=="yourturn")
    {
      emit
      ( GameState
        ( state.iStart,state.score, 
          board: state.board, bag: state.bag, tray: state.tray,
          phase: 1, mover:""
        )
      );  
    }
  }
}