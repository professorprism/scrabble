// player.dart
// Barrett Koster 2025

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "said_state.dart";
import "game_state.dart";
import "yak_state.dart";

/*
  A Player gets called for each of the ServerBase and the ClientBase.
  We establish the game state, usually different depending on 
  whether you are the starting player or not.  
  This establishes the Game and Said BLoC layers. 
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
// By this point, the socets exist in the YakState, but
// they have not yet been told to listen for messages.
// build() will start the listening.
class Player2 extends StatelessWidget
{ Widget build( BuildContext context )
  { YakCubit yc = BlocProvider.of<YakCubit>(context);
    YakState ys = yc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if ( ys.socket != null && !ys.listened )
    { sc.listen(context);
      yc.updateListen();
    } 
    return Player3();
  }
}

// This is the actual presentation of the game.
//
class Player3 extends StatelessWidget
{ Player3( {super.key} );

  Widget build( BuildContext context )
  { SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    SaidState ss = sc.state;
    GameCubit gc = BlocProvider.of<GameCubit>(context);
    GameState gs = gc.state;

    // in phase 1, it is this player's turn and if the tray
    // is not full and there's letters left in the bad, grab
    // a letter from the bag.
    if ( gs.phase>2 && gs.tray.length < 7 && gs.bag.length>0 )
    { gc.grab();
    }

    Column grid = Column( children: []);
    for ( int y=0; y<BOARD_SIZE; y++ )
    { Row row = Row( children: []);
      for ( int x=0; x<BOARD_SIZE; x++ )
      {
        row.children.add(BP( gs.board[y][x].letter,y,x ));
      }
      grid.children.add(row);
    }

    Row tray = Row( children: []);
    int x=0;
    for ( String letter in gs.tray )
    { tray.children.add( BP(letter, -1, x ) ); x++; }


    return Column
    ( children:
      [ grid,
        Text(gs.phase==0?"not my turn":"my turn"),
        tray
      ],
    );


  }
}

class BP extends StatelessWidget // place for tile on the board
{
  final String letter;
  final int y;
  final int x;
  const BP(this.letter, this.y, this.x, {super.key});

  // This letter is clicked on.  If it is our turn, either
  // 1. state.mover already has a letter and y>=0, in which case we
  // put that letter at THESE coordinates. (and mover="")
  // 2. state.mover is blank and y == -1 so we want to move THIS letter.
  // .. set it to be state.mover.
  void clicked( BuildContext context )
  { GameCubit gc = BlocProvider.of<GameCubit>(context);
    GameState gs = gc.state;

    if ( gs.phase==1 )
    {
      if ( gs.mover=="" && y == -1 ) // pick letter from the tray
      { gc.startMove(letter); }
      else if ( gs.mover!="" && y>=0 )// placing letter on the board
      { gc.endMove(y,x); }
      else
      { print("------  not correct click"); }
    }
  }

  @override
  Widget build( BuildContext context )
  {
    //return Text(letter, style: TextStyle(fontSize: 20 ) );
    return Listener
    ( onPointerDown: (_){ clicked(context); }, 
      child: Container
      ( width: 20, height: 20,
        decoration: BoxDecoration( border: Border.all() ),
        child: Text(letter),
      )
    );
  }
  
}