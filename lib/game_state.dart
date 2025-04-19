// game_state.dart
// Barrett Koster 2025

import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "said_state.dart";

// This is where you put whatever the game is about.

const int BOARD_SIZE = 15;

class Space
{
  String letter;
  Space( this.letter );
}

class GameState
{
  bool iStart;
  bool myTurn;
  int phase; // 0=not my turn, 1=ready to put letters, 2=refill the tray
             // and send turn to other player
             // 3=refill the tray and go to phase 1 (you are first player)
  String mover; // a letter that is being moved from tray to board.
                // "" if not in moving process.
  List<String> tray;

  // scrabble particulars
  List<List<Space>> board;
  List<String> bag;

  GameState( this.iStart, this.myTurn, //this.tttboard, 
            { required this.board, required this.bag,
              required this.tray, required this.phase,
              required this.mover,
            } 
           );

  GameState.init( this.iStart, this.myTurn, //this.tttboard 
                )
  : board = boardInit(), bag = bagInit(), 
    tray = ['a','b','c'], phase=iStart?3:2, mover=''
  ;

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

class GameCubit extends Cubit<GameState>
{
  static final String d = ".";
  GameCubit( bool myt ): super( GameState.init( myt, myt,   )); 

  // move a random letter from the bag to this player's tray.
   void grab( BuildContext context  )
  { int le = state.bag.length; 
    if ( le > 0 )
    {
      int pickn = Random().nextInt(le);
      List<String> b = state.bag;
      String ch = b[pickn];
      b.remove(ch);
      List<String> t = state.tray;
      t.add(ch);
      SaidCubit yc = BlocProvider.of<SaidCubit>(context);
      yc.say("bag $ch", context);

      emit( GameState
            (state.iStart,state.myTurn,//state.tttboard,
           board: state.board, bag: b, tray: t,
           phase: state.phase, mover:""
            )
          );
    }
  }

  
  void startMove( String m )
  { emit
    ( GameState
      (state.iStart,state.myTurn,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: state.phase, mover:m
      )
    );
  }

  void endMove( int y, int x, BuildContext context )
  { List<List<Space>> b = state.board;
    b[y][x] = Space(state.mover);
    List<String> t = state.tray;
    t.remove(state.mover);

    SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    sc.say("place ${state.mover} $y $x", context);
    
    emit
    ( GameState
      (state.iStart,state.myTurn,
           board: b, bag: state.bag, tray: t,
           phase: state.phase, mover:""
      )
    );
  }

  // change state to phase 2.  that will refill the tray and
  // lead to notify the other player that it is now their turn.
  void refill()
  { emit
    ( GameState
      (state.iStart,state.myTurn,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: 2, mover:""
      )
    );
  }

  // tell user user it is THEIR turn and set our phase=0 (not our turn)
  void switchUser( BuildContext context )
  { SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    sc.say("yourturn",context);
    emit
    ( GameState
      ( state.iStart,state.myTurn,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: 0, mover:""
      )
    );
  }

  void keepUser()
  { emit
    ( GameState
      (state.iStart,state.myTurn,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: 1, mover:""
      )
    );
  }

  /*
  update( int where, String what )
  {
    // state.tttboard[where] = what;
    state.myTurn = !state.myTurn;
    emit( GameState(state.iStart,state.myTurn,//state.tttboard,
           board: state.board, bag: state.bag, tray: state.tray,
           phase: state.phase, mover:state.mover
                   ) ) ;
  }

  // Someone played x or o in this square.  (numbered from
  // upper left 0,1,2, next row 3,4,5 ... 
  // Update the board and emit.
  play( int where )
  { String mark = state.myTurn==state.iStart? "x":"o";
    // state.tttboard[where] = mark;
    state.myTurn = !state.myTurn;
    emit( GameState(state.iStart,state.myTurn,//state.tttboard,
             board: state.board, bag: state.bag, tray: state.tray,
             phase: state.phase, mover: state.mover
                   ) ) ;
  }
  */
  

  // incoming messages are sent here for the game to do
  // whatever with.  Messages we handle:
  // "bag X" where X is a letter ... remove X from the bag.
  // "place X y x" puts letter X at coords y,x
  // "yourturn"  tells us it is OUR turn.
  void handle( String msg )
  { List<String> parts = msg.split(" ");
    if ( parts[0] == "bag" )
    { List<String> b = state.bag;
      b.remove(parts[1]);
      emit
      ( GameState
        ( state.iStart,state.myTurn,
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
        ( state.iStart,state.myTurn,
          board: b, bag: state.bag, tray: state.tray,
          phase: state.phase, mover:""
        )
      );  
    }
    else if ( parts[0]=="yourturn")
    {
      emit
      ( GameState
        ( state.iStart,state.myTurn,
          board: state.board, bag: state.bag, tray: state.tray,
          phase: 1, mover:""
        )
      );  
    }


  }
}