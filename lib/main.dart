// yak_base.dart.  This is a GUI demo of socket connections.
// Barrett Koster

// This is the base for a program that is a 2-player game
// on different machines (or at least different processes)
// Run this program twice, first selecting 'server' and
// second run selecting 'client'.

/*
   must have 
	<key>com.apple.security.network.client</key>
	<true/>
  in Runner/DebugProfile.entitlements and Runner/Release.entitlements

*/

//import 'dart:io';
//import 'dart:typed_data';

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "server_state.dart";
import "yak_state.dart";
//import "said_state.dart";
import "player.dart";

void main()
{ runApp( ServerOrClient () );
}

// This is a spash page that gives the choices of
// server or client.
class ServerOrClient extends StatelessWidget
{ ServerOrClient({super.key});

  @override
  Widget build( BuildContext context )
  { return MaterialApp
    ( title: "game",
      home: Builder
      ( builder: (context) => Scaffold
        ( appBar: AppBar( title: Text("which role?") ),
          body: Row
          ( children:
            [ ElevatedButton
              ( onPressed: ()
                { Navigator.of(context).push
                  ( MaterialPageRoute
                    ( builder: (context) => ServerBase() ),
                  ); 
                },
                child: Text("server"),
              ),
              ElevatedButton
              ( onPressed: ()
                { Navigator.of(context).push
                  ( MaterialPageRoute
                    ( builder: (context) => ClientBase() ),
                  );
                },
                child: Text("client"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
  This is called when you choose 'server' from the splash screen.
  The sequence is a little tricky here.  We construct the ServerCubit,
  but the ServerSocket that gets created comes later, which causes the
  BlocBuilder for ServerCubit to rebuild.  And we do not want to
  construct the YakCubit until that happens (because the rebuild does
  not call the YakCubit constructor again).  So we issue a
  "loading" message until the ServerSocket exists.  THEN 
  (when ServerCubit is rebuilt with an existing ServerSocket) we can 
  tell the YakCubit to try to establish a connection.  The server
  version of YakCubit construction, i.e., YakCubit.server(ss), tells
  the ServerSocket ss to listen for a client to call, and when the
  client calls, THAT is the Socket that is the core of YakCubit.
*/
class ServerBase extends StatelessWidget
{ @override
  Widget build( BuildContext context )
  { return BlocProvider<ServerCubit>
    ( create: (context) => ServerCubit(),
      child: BlocBuilder<ServerCubit, ServerState>
      ( builder: (context,state) 
        { ServerCubit sc = BlocProvider.of<ServerCubit>(context);
          ServerState ss = sc.state;
          return ss.server==null ? Text("loading") : 
          BlocProvider<YakCubit>
          ( create: (context) => YakCubit.server(ss.server),
            child: BlocBuilder<YakCubit,YakState>
            ( builder: (context,state) 
              // => Player( false ), // this works but below is better
              { YakCubit yc = BlocProvider.of<YakCubit>(context);
                YakState ys = yc.state;
                return ys.socket==null 
                ? Text("waiting for client to call") 
                : Player(false);
              }
            ), 
          );
        }
      ),
    );
  }
}

/*
  The ClientBase is easier than the ServerBase.  YakCubit 
  constructor (client version) calls the server and the resulting
  Socket is the connection core of YakCubit.  We could probably
  have a 'loading' message here too, because the call to the
  server is async, which means that we build Player onces and
  then have to do it again when the YakCubit socket gets
  created and BlocBuilder rebuilds from here down.
*/
class ClientBase extends StatelessWidget
{ @override
  Widget build( BuildContext context )
  { print("------- ClientBase building ....");
    return BlocProvider<YakCubit>
    ( create: (context) => YakCubit(),
      child: BlocBuilder<YakCubit,YakState>
      ( builder: (context, state) => Player( true ),
      ),
    );
  }
}
