import 'package:flutter/material.dart';

class CircularProgressLoading extends StatefulWidget {
  final  double? strokeWidth;
  const CircularProgressLoading({Key? key,this.strokeWidth}) : super(key: key);

  @override
  _CircularProgressLoadingState createState() =>
      _CircularProgressLoadingState();
}

class _CircularProgressLoadingState extends State<CircularProgressLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    // _controller = AnimationController(vsync: this);
    _controller =
        AnimationController(duration: new Duration(seconds: 2), vsync: this);
    _controller.repeat();
    // widget.strokeWidth = (widget.strokeWidth!=null)?widget.strokeWidth:4.0;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth:widget.strokeWidth??4.0 ,
        valueColor: _controller
            .drive(ColorTween(begin: Colors.blueAccent, end: Colors.red)),
      ),
    );
  }
}
