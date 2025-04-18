// said_state.dart
// Barrett Koster 2025

import "dart:io";
import "dart:typed_data";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "yak_state.dart";
import "game_state.dart";

// Use this class to pass messages between two programs.
// It has access to the YakCubit so to listen for
// messages.  And it has access to the GameCubit
// so that it can send messages to it (to update the
// state of the game.

class SaidState
{
   String said;

   SaidState( this.said );
}

class SaidCubit extends Cubit<SaidState>
{
  SaidCubit() : super( SaidState("and so it begins ....\n" ) );

  // void update( String more ) { emit(SaidState( "${state.said}$more\n" ) ); } 
  void update( String s ) { emit( SaidState(s) ); }

  void listen( BuildContext bc )
  { YakCubit yc = BlocProvider.of<YakCubit>(bc);
    YakState ys = yc.state;

    GameCubit gc = BlocProvider.of<GameCubit>(bc);
    // GameState gs = gc.state;
    
    ys.socket!.listen
    ( (Uint8List data) async
      { final message = String.fromCharCodes(data);
        update(message);
        gc.handle(message);
      },
          // handle errors
      onError: (error)
      { print(error);
        ys.socket!.close();
      },
    );
  }
}
