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

    //attendee??????????????????.
    //???????????????????????????????????????????????????????????????????????????
    //FirebaseAuth.instance.userChanges().listen?????????initialize????????????close??????????????????
    FirebaseFirestore.instance.collection('attendee').where('attending',isEqualTo: true).snapshots().listen((snapshot) {
      _attendees = snapshot.docs.length;
      notifyListeners();
    });

    FirebaseAuth.instance.userChanges().listen((user) {
      if(user != null){
        _loginState = LoginState.loggedIn;
        _subscription = FirebaseFirestore.instance.collection('guestbook').orderBy('timestamp',descending: true).snapshots().listen((snapshot) {
          _guestBookMessages = [];
          snapshot.docs.forEach((document) {
            _guestBookMessages.add(GuestBookMessage(user: document.data()['name'],message:document.data()['text']));
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
        _loginState = LoginState.loggedOut;
        _guestBookMessages = [];
        _subscription?.cancel();
        _attendeeSubscription?.cancel();
      }
      notifyListeners();

    });

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
  const GuestBook({Key? key,required this.addMessage,required this.guestBookMessages}) : super(key: key);
  final Future<void> Function(String message) addMessage;
  final List<GuestBookMessage> guestBookMessages;

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
      for(var message in widget.guestBookMessages) Paragraph('${message.user}:${message.message}'),
      SizedBox(width:8)
      ]
    );
  }
}

//GusetBook??????????????????????????????
class GuestBookMessage{
  final String user;
  final String message;
  GuestBookMessage({required this.user,required this.message});
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

