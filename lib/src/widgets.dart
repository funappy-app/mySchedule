import 'package:flutter/material.dart';

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