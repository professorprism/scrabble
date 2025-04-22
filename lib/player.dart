// player.dart
// Barrett Koster 2025

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "said_state.dart";
import "game_state.dart";
import "yak_state.dart";

/*
  A Player gets called for each of the ServerBase and the ClientBase.
  We establish the game state, slightly different depending on 
  whether you are the starting player or not.  
  Player establishes the Game and Said BLoC layers. 
*/
class Player extends StatelessWidget
{ final bool iStart;
  Player( this.iStart, {super.key} );

  @override
  Widget build( BuildContext context )
  { 
    return BlocProvider<GameCubit>
    ( create: (context) => GameCubit( iStart ),
      child: BlocBuilder<GameCubit,GameState>
      ( builder: (context,state) => 
        BlocProvider<SaidCubit>
        ( create: (context) => SaidCubit(),
          child: BlocBuilder<SaidCubit,SaidState>
          ( builder: (context,state) => Scaffold
            ( appBar: AppBar(title: Text("player")),
              body: Player2(),
            ),
          ),
        ),
      ),
    );
  }
}

// this layer initializes the communication.
// By this point, the sockets exist in YakState, but
// they have not yet been told to listen for messages.
// build() ... sc.listen() will start the listening.
class Player2 extends StatelessWidget
{ Widget build( BuildContext context )
  { YakCubit yc = BlocProvider.of<YakCubit>(context);
    YakState ys = yc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if ( ys.socket != null && !ys.listened )
    { sc.listen(context); // is not async, whaddaya know
      yc.updateListen(); // notes the fact that we are now listening
    } 
    return Player3();
  }
}

// This is the actual presentation of the game.
// As we play the game and change game state, we rebuild the Widget tree as high
// as the Player above, but we do NOT rebuild the YakState later.
// (and the YakState layer is flagged so that we do not try to 
// REstart Yak listening in Player2, which would crash.)
class Player3 extends StatelessWidget
{ Player3( {super.key} );

  Widget build( BuildContext context )
  { SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    SaidState ss = sc.state;
    GameCubit gc = BlocProvider.of<GameCubit>(context);
    GameState gs = gc.state;

    // See GameState.phase definition for explanation of game flow.

    // in phase 2 or 3, refill your tray. (one letter at a time)
    // When the tray is full, switch user on phase 2 only.
    if ( gs.phase>=2 )
    { if ( gs.tray.length < 7 && gs.bag.length>0 ) // letter can be filled
      { gc.grab( context ); }
      else // done filling tray, switch user if phase==2 (and go to phase=0)
      { if ( gs.phase==2 ) { gc.switchUser( context ); }
        else { gc.keepUser(); } // set phase=1, our turn!
      }
    }
  
    // create the grid of boxes that is the visible board.
    Column grid = Column( children: []);
    for ( int y=0; y<BOARD_SIZE; y++ )
    { Row row = Row( children: []);
      for ( int x=0; x<BOARD_SIZE; x++ )
      {
        row.children.add(BP( gs.board[y][x].letter,y,x ));
      }
      grid.children.add(row);
    }

    // Here is the tray of letters that you play from.
    Row tray = Row( children: []);
    int x=0;
    for ( String letter in gs.tray )
    { tray.children.add( BP(letter, -1, x ) ); x++; }

    // spare letter bag. reveal only for debugging
    String bagString = "";
    for ( String ch in gs.bag )
    { bagString += ch; }

    // Here is the actual Widget tree to display
    return Column
    ( children:
      [ grid, // don't miss this!
        Row
        ( children:
          [ Text("score:"),
            Text("${gs.score}  "),
            (gs.phase==0)
            ? Text("not my turn")  
            : ElevatedButton
              ( onPressed: (){ gc.refill(); },
                child: Text("end turn"),
              ),
          ],
        ),
        tray,
        Text(ss.said), // for debugging only
        // Text("bag:${bagString}"), // debug only
      ],
    );
  }
}

// BP is a box for a letter.  We use it for the board as
// well as the tray.  Tray letters have y=-1.  Board letters
// have non-zero x and y.
class BP extends StatelessWidget
{
  final String letter;
  final int y;
  final int x;
  const BP(this.letter, this.y, this.x, {super.key});
  

  // clicked()
  // This letter is clicked on.  If it is our turn, either
  // 1. state.mover is blank and y == -1 so we are clicking on
  // a tray letter to move it.  Set it to be state.mover.
  // 2. state.mover already has a letter and y>=0, in which case 
  // what we are clicking on here is a board space and we should
  // put the mover letter at THESE coordinates. (and set mover="")
  void clicked( BuildContext context )
  { GameCubit gc = BlocProvider.of<GameCubit>(context);
    GameState gs = gc.state;

    if ( gs.phase==1 )
    {
      if ( gs.mover=="" && y == -1 ) // pick letter from the tray
      { gc.startMove(letter); }
      else if ( gs.mover!="" && y>=0 )// placing letter on the board
      { gc.endMove(y,x, context); }
      else
      { print("------  not correct click"); }
    }
  }

  // This draws the letter in a box that we can click on.
  @override
  Widget build( BuildContext context )
  { return Listener
    ( onPointerDown: (_){ clicked(context); }, 
      child: Container
      ( width: 20, height: 20,
        decoration: BoxDecoration( border: Border.all() ),
        child: Text(letter, style:TextStyle(fontSize:15) ),
      )
    );
  }
}