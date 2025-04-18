// connection_state.dart
// Barrett Koster 2025

import "dart:io";
import "package:flutter_bloc/flutter_bloc.dart";

// YakState has the socket to another program, over which 
// you can send messages.
// The socket is created one way if you are the server,
// and a different way if you are the client.  Once
// established, both work the same way.

class YakState
{
  Socket? socket = null; // the Socket when connected
  bool listened = false; // true === we are listening to this socket (we only
                         // want to turn this on once, so I have this 
                         // bool to keep track of that. )

  YakState( this.socket, this.listened );
}
class YakCubit extends Cubit<YakState>
{
  // constructor for the client.  make empty start, but then launch the async
  // connect() that will make a connection.
  YakCubit() : super( YakState( null, false) )
  { connectClient(); }

  // constructor for the server.  It needs the ServerSocket,
  // which it hangs out there to get a client to call (which
  // then yields the socket that we communicate through).
  YakCubit.server( ServerSocket? ss ) 
  : super( YakState(null, false ) )
  { if ( ss!=null ) { connectServer(ss); } }

  updateSocket( Socket s ) { emit( YakState(s,false) ); }
  updateListen() { emit( YakState(state.socket, true ) ); }

  // connectClient() calls the server and emits a socket when connected.
  Future<void>  connectClient() async
  { print("------------ YakCubit connectClient running ... ");

    await Future.delayed( const Duration(seconds:2) ); // adds drama
    
    // connect to the socket server
    final serv = await Socket.connect('localhost', 9203);
    print('---------- Connected to: ${serv.remoteAddress.address}:${serv.remotePort}');
    updateSocket(serv);
  }

  // connectServer() is given a ServerSocket.  It listens for
  // client to call.  This can take forever, but assuming that a 
  // client calls at some point, the socket is established.
  Future<void>  connectServer( ServerSocket ss ) async
  { print("------- ss not null, so listen for client to call ....");
    ss.listen
    ( (client)
      { print("-------- client called, there's your socket ...");
        updateSocket(client);
      }
    );
  }

  // put this message on the socket (for the other end
  // to read.
  void say( String msg )
  {
    if ( state.socket!=null )
    { state.socket!.write(msg);
    }
  }

}
