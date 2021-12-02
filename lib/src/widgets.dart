import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Header extends StatelessWidget{
  final String heading;
  const Header(this.heading);

  Widget build(Context){
    return Padding(
      padding:EdgeInsets.all(8),
      child:Text(
        heading,
        style:TextStyle(fontSize:24)
      )
    );
  }
}

class Paragraph extends StatelessWidget{
  final String content;
  const Paragraph(this.content);

  Widget build(context){
    return Padding(
      padding:EdgeInsets.symmetric(vertical: 4,horizontal: 8),
      child: Text(
        content,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class IconAndDetail extends StatelessWidget{
  final IconData icon;
  final String detail;
  const IconAndDetail(this.icon,this.detail);

  Widget build(context){
    return Padding(
      padding:EdgeInsets.all(8),
      child:Row(
        children:[
          Icon(icon),
          SizedBox(width:8),
          Text(
            detail,
            style: TextStyle(fontSize:18),
          )
        ]
      )
    );
  }
}

class StyledButton extends StatelessWidget{
  final void Function() onPressed;
  final Widget child;
  const StyledButton({required this.onPressed,required this.child});

  Widget build(context){
    return OutlinedButton(
      style:OutlinedButton.styleFrom(side:BorderSide(color: Colors.deepPurple)),
      child:child,
      onPressed: onPressed,
    );
  }
}

class MyMessage extends StatelessWidget{
  final String message;
  final int timestamp;
  final DateFormat _formatter = DateFormat('MM/dd HH:mm');
  final void Function() onPressed;
  MyMessage({required this.message,required this.timestamp,required this.onPressed});

  Widget build(context){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8,horizontal: 16),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          //投稿日時
          Text(
              _formatter.format(DateTime.fromMillisecondsSinceEpoch(timestamp)),
              style:TextStyle(color: Colors.grey,fontSize: 8)
          ),
          SizedBox(width:8),
          //投稿
          GestureDetector(
            onLongPress: ()=> onPressed(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.lightGreenAccent
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.6),
              child: Text(message),
            ),
          )

        ],
      )
    );
  }
}

class OtherMessage extends StatelessWidget{
  final String message;
  final String username;
  final int timestamp;
  final DateFormat _formatter = DateFormat('MM/dd HH:mm');
  
  OtherMessage({required this.message,required this.username,required this.timestamp});
  
  Widget build(context){
    return Container(
      padding: EdgeInsets.symmetric(vertical:8,horizontal:16),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.6),
            decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(10)),
            child: Text(message),
          ),
          SizedBox(width:8),
          Text(_formatter.format(DateTime.fromMillisecondsSinceEpoch(timestamp)))
        ],
      )
    );
  }
}