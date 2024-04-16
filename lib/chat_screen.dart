import 'package:cha_app/url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  IO.Socket? socket;
  List<dynamic> contacts = [];
  dynamic currentUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  void initUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');
    if (userJson == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        currentUser = jsonDecode(userJson)['user'];
        connectSocket();
        fetchContacts();
      });
    }
  }

  void connectSocket() {
    socket = IO.io('${URL.url}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket?.connect();
    socket?.onConnect((_) {
      print('connected');
      socket?.emit('add-user', currentUser['_id']);
    });
  }

  Future<void> fetchContacts() async {
    setState(() {
      isLoading = true;
    });
    try {
      var response = await http.get(Uri.parse('${URL.url}/api/auth/allusers/${currentUser['_id']}'));
      if (response.statusCode == 200) {
        setState(() {
          contacts = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print('Error fetching contacts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contacts")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
        itemCount: contacts.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text(contacts[index]['username'][0]),
            ),
            title: Text(
              contacts[index]['username'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  selectedUser: contacts[index],
                ),
              ));
            },
          );
        },
      ),
    );
  }
}






class ChatDetailScreen extends StatefulWidget {
  final dynamic selectedUser;

  ChatDetailScreen({required this.selectedUser});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<types.Message> messages = [];
  types.User? currentUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initCurrentUser();
  }

  // Method to initialize current user from local storage
  void initCurrentUser() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user'); // Retrieve the JSON string
    if (userJson != null) {
      var decodedUser = jsonDecode(userJson);
      if (decodedUser != null && decodedUser['user'] != null) {
        // Assuming 'id' is the correct key for the user's identifier
        String userId = decodedUser['user']['_id']; // Correctly extracting user ID
        print(userId);
        setState(() {
          currentUser = types.User(id: userId); // Use the extracted ID to create User
          isLoading = false;
          fetchMessages();
        });
      } else {
        print("No current user data available in local storage.");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print("No user data found in local storage.");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMessages() async {
    if (currentUser == null || widget.selectedUser == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      var response = await http.post(
          Uri.parse('${URL.url}/api/messages/getmsg/'),
          body: jsonEncode({
            'from': currentUser!.id,
            'to': widget.selectedUser['_id'],
          }),
          headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        List<dynamic> fetchedMessages = jsonDecode(response.body);
        List<types.Message> chatMessages = fetchedMessages.map<types.Message>((msg) {
          return types.TextMessage(
              author: types.User(id: msg['fromSelf'] ? currentUser!.id : widget.selectedUser['_id']),
              createdAt: DateTime.now().millisecondsSinceEpoch, // Assuming timestamp handling if needed
              id: Uuid().v4(), // Generating a new UUID for each message, adjust if actual IDs are available
              text: msg['message'],
              status: msg['fromSelf'] ? types.Status.sent : types.Status.delivered
          );
        }).toList();

        setState(() {
          messages = chatMessages;
        });
      } else {
        print('Error fetching messages: Status Code ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetching messages: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: currentUser!,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: Uuid().v4(),
      text: message.text,
    );

    sendMessage(textMessage);
  }

  Future<void> sendMessage(types.TextMessage message) async {
    if (currentUser == null) return;

    try {
      var response = await http.post(
          Uri.parse('${URL.url}/api/messages/addmsg/'),
          body: jsonEncode({
            'from': currentUser!.id,
            'to': widget.selectedUser['_id'],
            'message': message.text,
          }),
          headers: {'Content-Type': 'application/json'}
      );
print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          messages.insert(0, message);
        });
      } else {
        print('Error sending message: Status Code ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.selectedUser['username'])),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Chat(
        messages: messages,
        onSendPressed: _handleSendPressed,
        user: currentUser!,
        showUserAvatars: true,
        showUserNames: true,
      ),
    );
  }
}


