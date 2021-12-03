import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/widgets.dart';
import 'src/authentication.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder:(context,_) => MyApp()
  ));
}

class MyApp extends StatelessWidget{
  Widget build(context){
    return MaterialApp(
      title:'Firebase meetup',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
          highlightColor: Colors.deepPurple
        )
      ),
      home:const HomePage()
    );
  }
}

class HomePage extends StatelessWidget{
  const HomePage({Key? key}) : super(key:key);
  Widget build(context){
    return Scaffold(
      appBar: AppBar(
        title:Text('Firebase Meetup'),
      ),
      body:ListView(
        children: [
          Image.asset('assets/codelab.png'),
          const SizedBox(height: 8,),
          const IconAndDetail(Icons.calendar_today,'October 30'),
          const IconAndDetail(Icons.location_city,'San Francisco'),

          Consumer<ApplicationState>(
            builder: (context,appState,_) => Authentication(
              loginState: appState.loginState,
              email: appState.email,
              startLoginFlow: appState.startLoginFlow,
              verifyEmail: appState.verifyEmail,
              registerAccount: appState.registerAccount,
              signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
              cancelRegistration: appState.cancelRegistration,
              signOut:appState.signOut
            )
          ),
          Divider(
            height:8,
            thickness: 1,
            indent:8,
            endIndent: 8,
            color: Colors.grey,
          ),
          Header("What we'll be doing"),
          Paragraph('Join us for a day full of Firebase workshop and pizza!'),
          Consumer<ApplicationState>(
            builder:(context,appState,_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(appState.attendees == 0) Paragraph('No one going')
                else if(appState.attendees == 1) Paragraph('1 person going')
                else Paragraph('${appState.attendees} people going'),
                if(appState.loginState == LoginState.loggedIn) ...[
                  YesNoSelection(state:appState.attending,onSelection:(attending) => appState.attending = attending),
                  Header('Discussion'),
                  GuestBook(
                    guestBookMessages: appState.guestBookMessages,
                    userId:appState.currentUserId,
                    deleteMessage:appState.deleteMessage,
                    addMessage:(message) => appState.addMessageToGuestBook(message)
                  )
                ]
              ],
            )
          )
        ],
      )
    );
  }
}

enum Attending{
  unknown,
  yes,
  no
}

class ApplicationState extends ChangeNotifier{
  LoginState _loginState = LoginState.loggedOut;
  LoginState get loginState => _loginState;


  String _currentUserId = '';
  String get currentUserId => _currentUserId;

  String? _email;
  String? get email => _email;

  StreamSubscription? _subscription;

  List<GuestBookMessage> _guestBookMessages = [];
  List<GuestBookMessage> get guestBookMessages => _guestBookMessages;

  int _attendees = 0;
  int get attendees => _attendees;
  Attending _attending = Attending.unknown;
  Attending get attending => _attending;
  set attending(Attending attending){
    final userDoc = FirebaseFirestore.instance.collection('attendee').doc(FirebaseAuth.instance.currentUser!.uid);
    if(attending == Attending.yes){
      userDoc.set({'attending':true});
    }else{
      userDoc.set({'attending':false});
    }
  }
  StreamSubscription<DocumentSnapshot>? _attendeeSubscription;


  ApplicationState(){
    init();
  }

  Future<void> init() async{
    await Firebase.initializeApp();

    //attendeeの人数を取得.
    //ログインしててもしてなくても表示して問題ないから、
    //FirebaseAuth.instance.userChanges().listenの外でinitializeしてて、closeもしていない
    FirebaseFirestore.instance.collection('attendee').where('attending',isEqualTo: true).snapshots().listen((snapshot) {
      _attendees = snapshot.docs.length;
      notifyListeners();
    });

    FirebaseAuth.instance.userChanges().listen((user) {
      if(user != null){
        _currentUserId = user.uid;
        _loginState = LoginState.loggedIn;
        _subscription = FirebaseFirestore.instance.collection('guestbook').orderBy('timestamp',descending: true).snapshots().listen((snapshot) {
          _guestBookMessages = [];
          snapshot.docs.forEach((document) {
            _guestBookMessages.add(GuestBookMessage(
                messageId:document.id,
                user: document.data()['name'],
                message:document.data()['text'],
                userId:document.data()['userId'],
                timestamp:document.data()['timestamp']
            ));
          });
          notifyListeners();
        });
        _attendeeSubscription = FirebaseFirestore.instance.collection('attendee').doc(user.uid).snapshots().listen((snapshot) {
          if(snapshot.data() != null){
            if(snapshot.data()!['attending']){
              _attending = Attending.yes;
            }else{
              _attending = Attending.no;
            }
            notifyListeners();
          }
        });
      }else{
        _currentUserId = '';
        _loginState = LoginState.loggedOut;
        _guestBookMessages = [];
        _subscription?.cancel();
        _attendeeSubscription?.cancel();
      }
      notifyListeners();

    });

  }

  void deleteMessage(String messageId) async {
    DocumentReference ref = FirebaseFirestore.instance.collection('guestbook').doc(messageId);
    DocumentSnapshot data = await ref.get();
    String user = (data.data() as Map<String,dynamic>)['userId'];
    if(user == FirebaseAuth.instance.currentUser!.uid){
      await ref.delete();
      notifyListeners();
    }
  }

  Future<DocumentReference> addMessageToGuestBook(String message){
    if(_loginState != LoginState.loggedIn){
      throw Exception('MUST BE LOGGED IN');
    }
    return FirebaseFirestore.instance.collection('guestbook').add(<String,dynamic>{
      'text': message,
      'timestamp':DateTime.now().millisecondsSinceEpoch,
      'name':FirebaseAuth.instance.currentUser!.displayName,
      'userId':FirebaseAuth.instance.currentUser!.uid
    });
  }

  void startLoginFlow(){
    _loginState = LoginState.emailAddress;
    notifyListeners();
  }

  void verifyEmail(String email,void Function(FirebaseException e) errorCallback) async {
    try{
      var methods =  await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if(methods.contains('password')){
        _loginState = LoginState.password;
      }else {
        _loginState = LoginState.register;
      }
      _email = email;
      notifyListeners();
    }on FirebaseException catch(e){
      errorCallback(e);
    }
  }

  void registerAccount(String email,String displayName,String password,void Function(FirebaseAuthException e) errorCallback) async {
    try{
      var credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(displayName);
    } on FirebaseAuthException catch(e){
      errorCallback(e);
    }
  }

  void signInWithEmailAndPassword(String email,String password, void Function(FirebaseAuthException e) errorCallback) async{
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      _loginState = LoginState.loggedIn;
      notifyListeners();
    }on FirebaseAuthException catch(e){
      errorCallback(e);
    }
  }

  void cancelRegistration(){
    _loginState = LoginState.emailAddress;
    notifyListeners();
  }

  void signOut(){
    FirebaseAuth.instance.signOut();
  }

}

class GuestBook extends StatefulWidget {
  const GuestBook({Key? key,required this.addMessage,required this.guestBookMessages,required this.userId,required this.deleteMessage}) : super(key: key);
  final Future<void> Function(String message) addMessage;
  final List<GuestBookMessage> guestBookMessages;

  final String userId;
  final void Function(String messageId) deleteMessage;

  @override
  _GuestBookState createState() => _GuestBookState();
}

class _GuestBookState extends State<GuestBook> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_GuestBookState');
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
        padding:EdgeInsets.all(8),
        child: Form(
          key:_formKey,
          child:Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  decoration:InputDecoration(
                    hintText:'Leave a message'
                  ),
                  validator:(value){
                    if(value == null || value.isEmpty){
                      return 'Enter your message to continue';
                    }
                    return null;
                  }
                ),
              ),
              SizedBox(width:8),
              StyledButton(
                onPressed:(){
                  if(_formKey.currentState!.validate()){
                    widget.addMessage(_controller.text);
                    _controller.clear();
                  }
                },
                child:Row(
                  children: [
                    Icon(Icons.send),
                    SizedBox(width:4),
                    Text('Send')
                  ],
                )

              )
            ],
          )
        ),
      ),
      SizedBox(width:8),
      //TODO  ここから変更
        for(var message in widget.guestBookMessages) LineLikeMessage(userId: widget.userId, message: message, deleteMessage: ()=>widget.deleteMessage(message.messageId)),
      // for(var message in widget.guestBookMessages) Paragraph('${message.user}:${message.message}'),
      SizedBox(width:8)
      ]
    );
  }
}



//GusetBookのデータを表すクラス
class GuestBookMessage{
  final String user;
  final String message;
  final int timestamp;
  final String userId;
  final String messageId;

  GuestBookMessage({
    required this.user,
    required this.message,
    required this.timestamp,
    required this.userId,
    required this.messageId
  });
}

class YesNoSelection extends StatelessWidget{
  final Attending state;
  final void Function(Attending selection) onSelection;

  const YesNoSelection({required this.state,required this.onSelection});

  @override
  Widget build(context){
    switch(state){
      case Attending.yes:
        return Padding(
          padding:EdgeInsets.all(8),
          child:Row(
            children:[
              ElevatedButton(
                child: Text('YES'),
                onPressed: () => onSelection(Attending.yes),
                style:ElevatedButton.styleFrom(elevation: 0)
              ),
              SizedBox(width:8),
              TextButton(
                child:Text('NO'),
                onPressed: ()=> onSelection(Attending.no),
              )
            ]
          )
        );
      case Attending.no:
        return Padding(
          padding:EdgeInsets.all(8),
          child:Row(
            children: [
              TextButton(
                child:Text('YES'),
                onPressed:()=> onSelection(Attending.yes)
              ),
              SizedBox(width:8),
              ElevatedButton(
                onPressed:()=> onSelection(Attending.no),
                child:Text('NO'),
                style:ElevatedButton.styleFrom(elevation: 0)
              )
            ],
          )
        );
      default:
        return Padding(
          padding:EdgeInsets.all(8),
          child: Row(
            children: [
              StyledButton(
                child: Text('YES'),
                onPressed: ()=> onSelection(Attending.yes),
              ),
              SizedBox(width:8),
              StyledButton(
                child:Text('NO'),
                onPressed:()=> onSelection(Attending.no)
              )
            ],
          ),
        );
    }
  }
}

class LineLikeMessage extends StatelessWidget{
  final String userId;
  final GuestBookMessage message;
  final void Function() deleteMessage;

  LineLikeMessage({required this.userId,required this.message,required this.deleteMessage});

  Future<void> showConfirmDialog(BuildContext context)async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:Text('メッセージの削除'),
        content:Text('このメッセージを削除しますか？'),
        actions: [
          StyledButton(
            child:Text('YES'),
            onPressed: (){
              deleteMessage();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('NO'),
            onPressed: ()=> Navigator.of(context).pop(),
          )
        ],
      )
    );
  }

  Widget build(context){
    if(userId == message.userId) return MyMessageWidget(message:message.message,timestamp:message.timestamp,onPressed:()=>showConfirmDialog(context),);
    else return OtherMessage(message: message.message, username: message.user, timestamp: message.timestamp);
  }
}

/*
class LineLikeMessage extends StatelessWidget{
  final bool isMine;
  //多分使わない　final String messageId;
  final String message;
  final int timestamp;
  final String username;
  final void Function() deleteMessage;


  LineLikeMessage({
      required this.isMine,
      required this.message,
      required this.timestamp,
      required this.username,
      required this.deleteMessage
  });

  void showConfirmDialog(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:Text(
              'メッセージの削除',
              style:TextStyle(fontSize:24)
          ),
          content: Text(
            'このメッセージを削除しますか？',
            style:TextStyle(fontSize:18)
          ),
          actions: [
            StyledButton(
              child: Text('YES'),
              onPressed: (){
                deleteMessage();
                Navigator.of(context).pop();
                },
            ),
            TextButton(
              child: Text('NO'),
              onPressed:()=> Navigator.of(context).pop(),
            )
          ],
        )
    );


  }
  Widget build(context){
    if(isMine) return MyMessage(message: message, timestamp: timestamp, onPressed: ()=>showConfirmDialog(context));
    else return OtherMessage(message:message,timestamp:timestamp,username:username);
  }
}
 */


