import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_flutter/icons_flutter.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  late String _profilePicUrl;
  late int _totalLikes = 0;
  late List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    try {
      // Fetch user data
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      // Fetch user posts
      QuerySnapshot userPostsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .get();

      setState(() {
        _name = userData['displayName'];
        _email = userData['email'];
        _profilePicUrl = userData['photoURL'];
        _posts = userPostsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(_profilePicUrl),
          ),
          SizedBox(height: 20),
          Text(
            _name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            _email,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'Total Likes: $_totalLikes',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Posts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1 / 1,
              ),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _showPostDialog(context, _posts[index]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage('${_posts[index]['plantimage']}'),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDialog(BuildContext context, Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(post['plantname'], style: GoogleFonts.ptSerif(
              textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600
              )
          ),),
          actions: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: (){
                  _deletePost(post['postId']);
                  Navigator.pop(context);
                }, child: Text("Delete Post", style: TextStyle(color: Colors.white),)),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: (){
                  Navigator.pop(context);
                }, child: Text("Close", style: TextStyle(color: Colors.white),)),

          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width*0.9,
                height: MediaQuery.of(context).size.height*0.3,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.fill,
                        image: NetworkImage(
                            post['plantimage']
                        ))
                ),
              ),
              SizedBox(height: 10),
              Text(post['plantdescription']),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(FontAwesome5Icon.heart),
                      SizedBox(width: 5,),
                      Text('${post['likes']}', style: TextStyle(fontSize: 15),),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(FontAwesome5Icon.comment),
                      SizedBox(width: 5,),
                      Text('${post['comments']}', style: TextStyle(fontSize: 15),),
                    ],
                  ),
                ],
              ),
            ],
          ),

        );
      },
    );
  }

  void _deletePost(String postId) async {
    try {
      // Show circular progress indicator while deleting
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing the dialog
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Check if postId is not null before deleting
      if (postId != null) {
        // Delete the post document from Firestore
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

        // Remove the deleted post from the _posts list
        setState(() {
          _posts.removeWhere((post) => post['postId'] == postId);
        });

        // Dismiss the progress indicator dialog
        Navigator.pop(context);

        // Show a snackbar to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post deleted successfully'),
          ),
        );
      } else {
        // If postId is null, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post ID is null. Cannot delete post.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      // Dismiss the progress indicator dialog
      Navigator.pop(context);

      // Show an error snackbar if deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
