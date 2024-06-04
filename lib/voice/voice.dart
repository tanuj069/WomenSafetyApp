import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:women_safety_app/child/bottom_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VoiceCommandScreen(),
    );
  }
}

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  late stt.SpeechToText _speech; // Initialize it using 'late'

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText(); // Initialize it here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Command Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              onPressed: _toggleListening,
            ),
            Text(_isListening ? 'Listening...' : 'Not Listening'),
          ],
        ),
      ),
    );
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            String recognizedWords = result.recognizedWords.toLowerCase();
            if (recognizedWords == 'help') {
              // Open the app or navigate to the desired screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BottomPage()),
              );
            }
          });
        },
      );
    }
  }

  void _stopListening() {
  _speech.stop();
  setState(() {
    _isListening = false;
  });
}

}

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help Screen'),
      ),
      body: Center(
        child: Text(
          'This is the Help Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
