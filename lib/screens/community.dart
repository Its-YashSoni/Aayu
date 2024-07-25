import 'dart:io';
import 'package:ayu/screens/Home.dart';
import 'package:ayu/screens/home_screen.dart';
import 'package:ayu/screens/homepage.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:ayu/screens/screen_builder.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

class User {
  final String id;
  final String name;
  final String image;
  final String plantName;
  final String plantImage;
  final String plantDescription;
  final int likes;
  final int comments;
  final List<String>? likedBy;
  final Timestamp timestamp;

  User({
    required this.id,
    required this.name,
    required this.image,
    required this.plantName,
    required this.plantImage,
    required this.plantDescription,
    required this.likes,
    required this.comments,
    required this.likedBy,
    required this.timestamp,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      plantName: data['plantname'] ?? '',
      plantImage: data['plantimage'] ?? '',
      plantDescription: data['plantdescription'] ?? '',
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      timestamp: data['timestamp'],
    );
  }
}


class Community extends StatefulWidget {
  final bool isGuest;

  Community({required this.isGuest, super.key});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  bool _isLoading = false;
  int _currentIndex = 1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  String name = '';
  String? email;
  String profilePicUrl = '';

  var userId;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      var user = userCredential.user;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastSignInTime': user.metadata.lastSignInTime,
          'creationTime': user.metadata.creationTime,
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(isGuest: widget.isGuest),
        ),
      );
    } catch (e) {
      print('Error signing in with Google: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void fetchData() async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      setState(() {
        name = userData['displayName'];
        email = userData['email'];
        profilePicUrl = userData['photoURL'];
        userId = userData['uid'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: $e')),
      );
    }
  }

  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xff426D51),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(FontAwesome.group), label: "Community"),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: "Upload"),
          ],
          onTap: (value) => setState(() {
            _currentIndex = value;
            if (_currentIndex == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(isGuest: widget.isGuest)));
            }
          }),
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          elevation: 50,
        ),
      ),
      body: _currentIndex == 2
          ? userId == null ? Center(child: CircularProgressIndicator(),) : UploadScreen(uid: userId, name: name, image: profilePicUrl)
          : _currentIndex == 1
          ? _isLoading
          ? Center(child: Lottie.asset('assets/loading.json'))
          : Padding(
        padding: const EdgeInsets.only(top: 12, left: 20.0, right: 20.0),
        child: widget.isGuest
            ? Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            child: ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/google.png', width: MediaQuery.of(context).size.width * 0.1),
                  Text("Sign In with Google"),
                ],
              ),
            ),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Community",
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            fontSize: MediaQuery.of(context).textScaleFactor * 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        "Uniting for Herbal Wisdom and Wellness",
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 12),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      userId == null ? Center(child: CircularProgressIndicator(),) : Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadScreen(
                            image: profilePicUrl,
                            name: name,
                            uid: userId ,
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.add_box_outlined, size: MediaQuery.of(context).size.width * 0.09),
                  ),
                ],
              ),
            ),

            Divider(),
            Expanded(
              child: StreamBuilder(
                stream: _postsCollection.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No posts available'));
                  }
                  List<User> users = snapshot.data!.docs.map((doc) => User.fromFirestore(doc)).toList();
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: PostItem(user: users[index], name: name, photoUrl: profilePicUrl,),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )
          : Container(),
    );
  }
}


class PostItem extends StatefulWidget {
  User user;
  final String name;
  final String photoUrl;
  PostItem({required this.user, required this.name, required this.photoUrl});

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool isExpanded = false;

  // void toggleLike() async {
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.user.id);
  //   final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser?.uid);
  //
  //   setState(() {
  //     if (widget.user.likedBy!.contains(currentUser?.uid)) {
  //       widget.user.likedBy!.remove(currentUser?.uid);
  //       widget.user.likes--;
  //     } else {
  //       widget.user.likedBy!.add(currentUser!.uid);
  //       widget.user.likes++;
  //     }
  //   });
  //
  //   await postRef.update({'likes': widget.user.likes, 'likedBy': widget.user.likedBy});
  //   await userRef.update({'likedPosts': widget.user.likedBy});
  // }

  @override
  void initState(){
    super.initState();
    initDynamicLinks();
  }

  Future<Uri> createDynamicLink(String postId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://aayuapp.page.link',
      link: Uri.parse('https://www.aayuapp.com/post?postId=$postId'),
      androidParameters: AndroidParameters(
        packageName: 'com.aayu.app',
        minimumVersion: 1,
      ),
    );

    final Uri dynamicUrl = await FirebaseDynamicLinks.instance.buildLink(parameters);
    return dynamicUrl;
  }

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink;
    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;

    if (deepLink != null) {
      String? postId = deepLink.queryParameters['postId'];
      if (postId != null) {
        // Navigate to the post details screen
        // Example: Navigator.pushNamed(context, '/post', arguments: postId);
      }
    }
  }



  void toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case when the user is not authenticated
      return;
    }
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.user.id);
    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    bool isLiked = widget.user.likedBy!.contains(currentUser.uid);
    int updatedLikes = widget.user.likes + (isLiked ? -1 : 1);
    List<String> updatedLikedBy = List.from(widget.user.likedBy!);

    if (isLiked) {
      updatedLikedBy.remove(currentUser.uid);
    } else {
      updatedLikedBy.add(currentUser.uid);
    }

    // Optimistically update the UI
    setState(() {
      widget.user = User(
        id: widget.user.id,
        name: widget.user.name,
        image: widget.user.image,
        plantName: widget.user.plantName,
        plantImage: widget.user.plantImage,
        plantDescription: widget.user.plantDescription,
        likes: updatedLikes,
        comments: widget.user.comments,
        likedBy: updatedLikedBy,
        timestamp: widget.user.timestamp,
      );
    });

    // Update Firestore
    await postRef.update({'likes': updatedLikes, 'likedBy': updatedLikedBy});
    await userRef.update({
      'likedPosts': isLiked
          ? FieldValue.arrayRemove([widget.user.id])
          : FieldValue.arrayUnion([widget.user.id]),
    });
  }



  void openComments() {
    TextEditingController _commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('comments')
                        .where('postId', isEqualTo: widget.user.id)
                        .snapshots(),
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No comments yet'));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (BuildContext context, int index) {
                          var commentData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage('${commentData['profileImg']}'),
                            ),
                            title: Text(
                              commentData['text'],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Comment by: ${commentData['user']}',
                              style: TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          )),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          String commentText = _commentController.text;
                          if (commentText.isNotEmpty) {
                            await FirebaseFirestore.instance.collection('comments').add({
                              'postId': widget.user.id,
                              'text': commentText,
                              'profileImg': widget.photoUrl ?? '',
                              'user': widget.name ?? 'Anonymous',
                              'timestamp': FieldValue.serverTimestamp()
                            });
                            // Update comments count in the 'posts' collection
                            await FirebaseFirestore.instance.collection('posts').doc(widget.user.id).update({
                              'comments': FieldValue.increment(1),
                            });
                            _commentController.clear();
                          }
                        } else {
                          // Handle the case when the user is not authenticated
                        }
                      },
                      child: Text(
                        'Comment',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Color(0xff426D51), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(widget.user.image),
            ),
            title: Text(
              widget.user.name,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${widget.user.timestamp.toDate().day}-${widget.user.timestamp.toDate().month}-${widget.user.timestamp.toDate().year} | ${widget.user.timestamp.toDate().hour}:${widget.user.timestamp.toDate().minute}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    alignment: Alignment.center,
                    image: NetworkImage(widget.user.plantImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    children: [
                      Text(
                        widget.user.plantName,
                        style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).textScaleFactor * 20,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        widget.user.plantDescription,
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: MediaQuery.of(context).textScaleFactor * 15),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.user.likedBy!.contains(FirebaseAuth.instance.currentUser?.uid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.user.likedBy!.contains(FirebaseAuth.instance.currentUser?.uid) ? Colors.red : Colors.black,
                    ),
                    onPressed: toggleLike,
                  ),
                  Text(
                    '${widget.user.likes}',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(
                      FontAwesome.comment_o,
                      color:  Colors.black,
                    ),
                    onPressed: openComments,
                  ),
                  Text(
                    '${widget.user.comments}',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.share, color: Color(0xff426D51)),
                    onPressed: () async{
                      final Uri dynamicLink = await createDynamicLink(widget.user.id);
                      final message =
                          'Check out this amazing medicinal plant: ${widget.user.plantName}.\n\n${widget.user.plantDescription}\n\nSee more: $dynamicLink';
                      Share.share(message);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class UploadScreen extends StatefulWidget {
  String name;
  String image;
  String uid;

   UploadScreen({required this.uid, required this.image, required this.name, super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  final picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> uploadPost() async {
    if (_image == null ||
        _nameController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("All fields are required.")));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('posts/$imageName');
      await ref.putFile(_image!);
      String downloadURL = await ref.getDownloadURL();
      final user = FirebaseAuth.instance.currentUser;

      // Add the post data without the postId
      DocumentReference postRef =
      await FirebaseFirestore.instance.collection('posts').add({
        'name': widget.name ?? 'Anonymous',
        'image': widget.image ?? '',
        'plantname': _nameController.text,
        'plantimage': downloadURL,
        'plantdescription': _descriptionController.text,
        'likes': 0,
        'comments': 0,
        'userId': widget.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get the generated document ID
      String postId = postRef.id;

      // Update the document with the postId
      await postRef.update({'postId': postId});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Post uploaded successfully.")));

      setState(() {
        _image = null;
        _nameController.clear();
        _descriptionController.clear();
        _isUploading = false;
      });

      Navigator.pop(context, true); // Pass 'true' to indicate success
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print("Error uploading post: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error uploading post: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: _isUploading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: 25,
                            color: Color(0xff426D51),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04,
                          ),
                          Text(
                            "Back",
                            style: GoogleFonts.ptSerif(
                              textStyle: TextStyle(
                                fontSize: 20,
                                color: Color(0xff426D51),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                GestureDetector(
                  onTap: getImage,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.35,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: _image != null
                            ? FileImage(_image!)
                            : AssetImage('assets/images/white.jpg') as ImageProvider,
                      ),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _image == null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Color(0xff426D51)),
                          Text(
                            'Tap to select an image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                        : null,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xff426D51)),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1,
                      color: Color(0xff426D51),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Plant Name",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xff426D51)),
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xff426D51),
                    ),
                    maxLines: 6,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Description",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: uploadPost,
                    child: Text(
                      "Upload",
                      style: GoogleFonts.ptSerif(
                        textStyle: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff426D51),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
