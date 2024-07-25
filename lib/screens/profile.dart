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
  late List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  int _totalLikes = 0;
  int _totalComments = 0;

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

      List<Map<String, dynamic>> posts = userPostsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      int totalLikes = posts.fold(0, (sum, post) => sum + (post['likes'] as int?? 0));
      int totalComments = posts.fold(0, (sum, post) => sum + (post['comments'] as int ?? 0));

      setState(() {
        _name = userData['displayName'];
        _email = userData['email'];
        _profilePicUrl = userData['photoURL'];
        _posts = posts;
        _totalLikes = totalLikes;
        _totalComments = totalComments;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Profile', style: GoogleFonts.poppins(
          fontSize: MediaQuery.of(context).textScaleFactor * 20,
          fontWeight: FontWeight.w500,
          color: Color(0xff426D51)
        ),),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 20),
          // Profile Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Colors.white,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_profilePicUrl),
                ),
                SizedBox(height: 10),
                Text(
                  _name,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _email,
                  style: GoogleFonts.dmSans(
                    textStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProfileStat('Posts', _posts.length),
                    SizedBox(width: 30),
                    _buildProfileStat('Comments', _totalComments),

                    SizedBox(width: 30),
                    _buildProfileStat('Likes', _totalLikes),

                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Divider(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 18.0, right: 18.0),
              child: Container(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Posts',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _showPostDialog(context, _posts[index]);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage('${_posts[index]['plantimage']}'),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String title, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          title,
          style: GoogleFonts.dmSans(
            textStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      ],
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
          )),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _deletePost(post['postId']);
                Navigator.pop(context);
              },
              child: Text("Delete Post", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: NetworkImage(post['plantimage']),
                  ),
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
                      Icon(FontAwesome5Icon.heart, size: 18),
                      SizedBox(width: 5),
                      Text('${post['likes']}', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(FontAwesome5Icon.comment, size: 18),
                      SizedBox(width: 5),
                      Text('${post['comments']}', style: TextStyle(fontSize: 15)),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      if (postId != null) {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

        setState(() {
          _posts.removeWhere((post) => post['postId'] == postId);
          _totalLikes = _posts.fold(0, (sum, post) => sum + (post['likes'] as int ?? 0));
          _totalComments = _posts.fold(0, (sum, post) => sum + (post['comments'] as int?? 0));
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post deleted successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post ID is null. Cannot delete post.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
