// server_state.dart
// Barrett Koster 2025

import "dart:io";
import 'package:flutter_bloc/flutter_bloc.dart';

// This class holds the ServerSocket, obvioiusly only
// for the server.  Creating the ServerSocket is async,
// so we launch the process of doing so in the constructor,
// and then when it succeeds, it emits a new state which
// has the ServerSocket in place.
class ServerState
{
   ServerSocket? server;

  ServerState(this.server);
}

class ServerCubit extends Cubit<ServerState>
{
  // constructor.  start with null ServerSocket, but when
  // connect() succeeds, that will get replaced.
  ServerCubit() : super( ServerState(null) )
  { connect(); }

  Future<void> connect() async
  { await Future.delayed( const Duration(seconds:2) ); // adds drama
    // bind the socket server to an address and port
    ServerSocket s = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);
    print("server socket created?");
    emit( ServerState(s) );
  }
}
