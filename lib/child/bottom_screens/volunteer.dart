import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class VolunteerPage extends StatefulWidget {
  @override
  State<VolunteerPage> createState() => _VolunteerPageState();
}

// _launchURL(String url) async {
//   if (await launchUrl(url)) {
//     await launch(url);
//   } else {
//     throw 'Could not launch $url';
//   }
// }


class _VolunteerPageState extends State<VolunteerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Locations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          // Process snapshot data and display it in the UI
          final documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              final liveLocation = document['live_location'];
               final name = document['name'];

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                color: Colors.grey[200], // Set the background color
                borderRadius: BorderRadius.circular(10), // Set the border radius
               ),
                child: ListTile(
                  title: Text('User Name: ${name}'),
                   subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                    "I am in trouble"
                  ),

                  SizedBox(width:10),
                
                  InkWell(
                        onTap: () {
                          launchUrlString(
                            'https://www.google.com/maps/search/?api=1&query=${liveLocation['latitude']}%2C${liveLocation['longitude']}',
                          );
                        },
                        child: Icon(Icons.location_on,color: Colors.blue,),
                      ),
                    ],
                   ),
                   
                ),
              );
            },
          );
        },
      ),
    );
  }
}
