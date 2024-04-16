import 'package:cha_app/url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  IO.Socket? socket;
  List<dynamic> contacts = [];
  dynamic currentUser;
  dynamic currentChat;
  bool isLoading = false;
  List<dynamic> messages = []; // Define the messages list here

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
      var decodedUser = jsonDecode(userJson);
      if (decodedUser != null && decodedUser['user'] != null) {
        setState(() {
          currentUser = decodedUser['user'];
        });
        connectSocket();
        fetchContacts();
      } else {
        // Handle the scenario where user data is not properly formatted
        print("Error: User data is not in expected format.");
      }
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
        List<dynamic> responseContacts = jsonDecode(response.body);
        if (responseContacts.isNotEmpty) {
          setState(() {
            contacts = responseContacts;
          });
        } else {
          print("No contacts found.");
        }
      } else {
        print('Error fetching contacts: Status Code ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetching contacts: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  void handleChatChange(dynamic selectedContact) {
    setState(() {
      currentChat = selectedContact;
      messages = []; // Clear messages for the previous chat
    });
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
      appBar: AppBar(title: Text("Contacts")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(contacts[index]['username']),
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

//
// class ChatContainer extends StatefulWidget {
//   final dynamic chat;
//   final IO.Socket? socket;
//
//   ChatContainer({required this.chat, this.socket});
//
//   @override
//   _ChatContainerState createState() => _ChatContainerState();
// }
//
// class _ChatContainerState extends State<ChatContainer> {
//   TextEditingController _messageController = TextEditingController();
//   List<dynamic> messages = [];
//   bool isLoading = false;
//   dynamic currentUser;
//
//   @override
//   void initState() {
//     super.initState();
//     initUser();
//     fetchMessages();
//
//   }
//
//   Future<void> initUser() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? userJson = prefs.getString('user');
//     if (userJson != null) {
//       var decodedUser = jsonDecode(userJson);
//       if (decodedUser != null && decodedUser['user'] != null) {
//         setState(() {
//           currentUser = decodedUser['user'];
//         });
//       } else {
//         print("Error: User data is not in expected format.");
//       }
//     }
//   }
//
//   Future<void> fetchMessages() async {
//
//     setState(() {
//       isLoading = true;
//     });
//     try {
//       print("current user-${currentUser}");
//       print("current currentChat-${widget.chat.chat}");
//
//       var response = await http.post(
//           Uri.parse('${URL.url}/api/messages/getmsg/'),
//           body: jsonEncode({'from': currentUser['_id'], 'to': widget.chat['_id']}),
//           headers: {'Content-Type': 'application/json'}
//       );
//       if (response.statusCode == 200) {
//         List<dynamic> fetchedMessages = jsonDecode(response.body);
//         if (fetchedMessages.isNotEmpty) {
//           setState(() {
//             messages = fetchedMessages.map((msg) {
//               return {
//                 'senderName': msg['from'] == currentUser['_id'] ? currentUser['username'] : widget.chat['username'],
//                 'message': msg['message']['text'],
//               };
//             }).toList();
//           });
//         } else {
//           print("No messages received.");
//         }
//       } else {
//         print('Error fetching messages: Status Code ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Exception fetching messages: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> sendMessage(String message) async {
//     if (currentUser == null || widget.chat == null) return;
//
//     try {
//       var response = await http.post(
//           Uri.parse('${URL.url}/api/messages/addmsg/'),
//           body: jsonEncode({
//             'from': currentUser['_id'],
//             'to': widget.chat['_id'],
//             'message': message,
//           }),
//           headers: {'Content-Type': 'application/json'}
//       );
//       if (response.statusCode == 200) {
//         _messageController.clear();
//         dynamic newMessage = jsonDecode(response.body);
//         setState(() {
//           messages.add({
//             'senderName': currentUser['username'],
//             'message': newMessage['message'],
//           });
//         });
//       } else {
//         print('Error sending message: Status Code ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error sending message: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//             child: isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 bool isSentByMe = messages[index]['senderName'] == currentUser['username'];
//                 return Align(
//                   alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     padding: EdgeInsets.all(8),
//                     margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                     decoration: BoxDecoration(
//                       color: isSentByMe ? Colors.blue : Colors.grey[300],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(messages[index]['message'],
//                       style: TextStyle(color: isSentByMe ? Colors.white : Colors.black),
//                     ),
//                   ),
//                 );
//               },
//             )
//         ),
//         Container(
//           padding: EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _messageController,
//                   decoration: InputDecoration(
//                     hintText: 'Type a message...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                   ),
//                 ),
//               ),
//               IconButton(
//                 icon: Icon(Icons.sentiment_satisfied),
//                 onPressed: () {
//                   // Emoji picker logic if implemented
//                 },
//               ),
//               IconButton(
//                 icon: Icon(Icons.send),
//                 onPressed: () {
//                   String message = _messageController.text.trim();
//                   if (message.isNotEmpty) {
//                     sendMessage(message);
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//
//
// class WelcomeWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Select a chat to start messaging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//     );
//   }
// }
