import 'package:flutter/material.dart';
import 'widgets.dart';



enum LoginState{
  loggedOut,
  emailAddress,
  register,
  password,
  loggedIn
}

class Authentication extends StatelessWidget{
  final LoginState loginState;
  final String? email;
  final void Function() startLoginFlow;
  final void Function(String email, void Function(Exception e) onError) verifyEmail;
  final void Function(String  email,String displayName,String password, void Function(Exception e)onError) registerAccount;
  final void Function() cancelRegistration;
  final void Function(String email,String password, void Function(Exception e)) signInWithEmailAndPassword;
  final void Function() signOut;

  const Authentication({
      required this.loginState,
      required this.email,
      required this.startLoginFlow,
      required this.verifyEmail,
      required this.registerAccount,
      required this.cancelRegistration,
      required this.signInWithEmailAndPassword,
      required this.signOut});

  Widget build(context){
    switch(loginState){
      case LoginState.loggedOut:
        return Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left:24,bottom:8),
              child:StyledButton(
                child:Text('RSVP'),
                onPressed: ()=>startLoginFlow(),
              )
            )
          ],
        );

      case LoginState.emailAddress:
        return EmailForm(
          callback: (email) => verifyEmail(email,(err) => _handleErr(context,'Invalod Address',err))
        );

      case LoginState.register:
        return RegisterForm(
          email:email!,
          cancel:()=>cancelRegistration(),
          registerAccount:(email,displayName,password) => registerAccount(email,displayName,password,(err)=>_handleErr(context,'Failed to create account',err))
        );

      case LoginState.password:
        return PasswordForm(
          email:email!,
          login:(email,password) => signInWithEmailAndPassword(email,password,(err) => _handleErr(context,'Failed to sign in',err))
        );

      case LoginState.loggedIn:
        return Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left:24,bottom:8),
              child:StyledButton(
                child: Text('LOGOUT'),
                onPressed: (){
                  signOut();
                },
              )
            )
          ],
        );
      default:
        return Row(
          children: [
            Text('Internal Error happened')
          ],
        );

    }
  }

  void _handleErr(BuildContext context,String title,Exception e){
    //ダイアログにエラーの内容を表示する
    showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text(
                title,
                style: TextStyle(fontSize:24),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                      (e as dynamic).message,
                    style: TextStyle(fontSize:18),
                  )
                ],
              ),
            ),
            actions: [
              StyledButton(
                child: Text('OK'),
                onPressed: ()=> Navigator.of(context).pop(),
              )
            ],
          );
        }
    );
  }
}



class EmailForm extends StatefulWidget {
  const EmailForm({Key? key,required this.callback}) : super(key: key);
  final void Function(String email) callback;

  @override
  _EmailFormState createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_fEmailFormState');
  final _emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header('Sign in with email'),
        Padding(
          padding: EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: TextFormField(
                      controller: _emailController,
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return 'Enter your email to continue';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your email'
                      ),
                    ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding:EdgeInsets.symmetric(vertical:16,horizontal: 30),
                      child: StyledButton(
                        onPressed:(){
                          if(_formKey.currentState!.validate()){
                            widget.callback(_emailController.text);
                          }
                        },
                        child: Text('NEXT'),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

class RegisterForm extends StatefulWidget {
  final String email;
  final void Function(String email,String dispayName,String password) registerAccount;
  final void Function() cancel;
  const RegisterForm({Key? key,required this.email,required this.registerAccount,required this.cancel}) : super(key: key);

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_RegisterAccountState');
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header('Create account'),
        Padding(
          padding:EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText:'Enter your email'
                    ),
                    validator: (value){
                      if(value == null || !value.contains('@')){
                        return 'Invalid email address';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                        hintText:'Enter your name'
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Enter your name to continue';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                        hintText:'Enter your password to continue'
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Invalid email address';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical:16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child:Text('CANCEL'),
                        onPressed:()=>widget.cancel()
                      ),
                      const SizedBox(width: 16,),
                      StyledButton(
                        child:Text('SAVE'),
                        onPressed: (){
                          if(_formKey.currentState!.validate()){
                            widget.registerAccount(_emailController.text,_displayNameController.text,_passwordController.text);
                          }
                        },
                      ),
                      const SizedBox(width:30)
                    ],
                  ),
                )

              ],
            ),
          ),
        )
      ],
    );
  }
}

class PasswordForm extends StatefulWidget {
  const PasswordForm({Key? key,required this.email,required this.login}) : super(key: key);
  final String email;
  final void Function(String email,String password) login;
  @override
  _PasswordFormState createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_PasswordFormState');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header('Sign in'),
        Padding(
          padding:EdgeInsets.all(8),
          child: Form(
            key:_formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your mail to continue'
                    ),
                    validator: (value){
                      if(value!.isEmpty || !value.contains('@')){
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration:InputDecoration(
                      hintText: 'enter your password'
                    ),
                    validator:(value){
                      if(value!.isEmpty){
                        return 'Enter your password to continue';
                      }
                      return null;
                    }
                  ),
                ),
                Padding(
                  padding:EdgeInsets.symmetric(vertical:16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(width:16),
                      StyledButton(
                        child:Text('LOGIN'),
                        onPressed: (){
                          if(_formKey.currentState!.validate()){
                            widget.login(_emailController.text,_passwordController.text);
                          }
                        },
                      ),
                      SizedBox(width:30)
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}





