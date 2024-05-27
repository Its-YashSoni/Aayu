import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:ayu/screens/screen_builder.dart';
import 'package:lottie/lottie.dart';

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
      likes: data['likes'] ?? '',
      comments: data['comments'] ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }
}

class Community extends StatefulWidget {
  bool isGuest;

  Community({required this.isGuest, super.key});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  bool __isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signInWithGoogle() async {
    setState(() {
      __isLoading = true; // Start loading indicator
    });

    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the authentication details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      var user = userCredential.user;

      // Check if the user already exists in Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();

      if (!userDoc.exists) {
        // User does not exist, create a new record
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastSignInTime': user.metadata.lastSignInTime,
          'creationTime': user.metadata.creationTime,
        });
      }

      // Navigate to the next screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenBuilder(isGuest: false),
        ),
      );
    } catch (e) {
      // Handle sign-in error
      print('Error signing in with Google: $e');
    } finally {
      setState(() {
        __isLoading = false; // Stop loading indicator
      });
    }
  }

  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('posts');


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return __isLoading
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
                            Image.asset('assets/google.png',
                                width: MediaQuery.of(context).size.width * 0.1),
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
                                  style: GoogleFonts.ptSerif(
                                    textStyle: TextStyle(fontSize: 28),
                                  ),
                                ),
                                Text(
                                  "Uniting for Herbal Wisdom and Wellness",
                                  style: GoogleFonts.ptSerif(
                                    textStyle: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UploadScreen(),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.add_box_outlined,
                                size: MediaQuery.of(context).size.width * 0.09,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      Expanded(
                        child: StreamBuilder(
                          stream: _postsCollection.snapshots(),
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (snapshot.data!.docs.isEmpty) {
                              return Center(child: Text('No posts available'));
                            }
                            List<User> users = snapshot.data!.docs
                                .map((doc) => User.fromFirestore(doc))
                                .toList();
                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: PostItem(user: users[index]),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          );
  }
}

class PostItem extends StatefulWidget {
  final User user;

  PostItem({required this.user});

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool isExpanded = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  void toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.user.id);

    // Check if the user has already liked the post
    final likedBy = widget.user.likedBy ?? [];

    if (likedBy.contains(user?.uid)) {
      // Unlike the post
      likedBy.remove(user?.uid);
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': likedBy,
      });
    } else {
      // Like the post
      likedBy.add(user!.uid);
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': likedBy,
      });
    }
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
          padding:  EdgeInsets.only(
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
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
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
                          var commentData = snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                          // commentData['text']
                          // commentData['user']
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage('${commentData['profileImg']}'),
                            ),
                            title: Text(
                              commentData['text'],
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
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
                            await FirebaseFirestore.instance
                                .collection('comments')
                                .add({
                              'postId': widget.user.id,
                              'text': commentText,
                              'profileImg': currentUser!.photoURL,
                              'user': user.displayName ?? 'Anonymous',
                              'timestamp': FieldValue.serverTimestamp()
                            });
                            // Update comments count in the 'posts' collection
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(widget.user.id)
                                .update({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 1, spreadRadius: 0.1),
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.user.image),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.04,
                    ),
                    Text(
                      widget.user.name,
                      style: GoogleFonts.ptSerif(
                        textStyle: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Icon(
                  FontAwesome5Solid.ellipsis_v,
                  size: 20,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
          Divider(height: 3),
          LayoutBuilder(builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxWidth * 0.75,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(widget.user.plantImage),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                InkWell(
                  onTap: toggleLike,
                  child: Icon(
                    FontAwesome5Solid.heart,
                    color: widget.user.likedBy?.contains(
                                FirebaseAuth.instance.currentUser?.uid) ??
                            false
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.02,
                ),
                Text(
                  "${widget.user.likes}",
                  style: TextStyle(
                      fontFamily: "Rockford Sans",
                      fontSize: 15,
                      fontWeight: FontWeight.w400),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.06,
                ),
                GestureDetector(
                  onTap: openComments,
                  child: Icon(FontAwesome5Solid.comment),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.02,
                ),
                Text(
                  "${widget.user.comments}",
                  style: TextStyle(
                      fontFamily: "Rockford Sans",
                      fontSize: 15,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            child: Text(
              widget.user.plantName,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.plantDescription,
                  maxLines: isExpanded ? null : 3,
                  overflow:
                      isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    textStyle:
                        TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: Text(
                    isExpanded ? "Show less" : "View more",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

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
        'name': user?.displayName ?? 'Anonymous',
        'image': user?.photoURL ?? '',
        'plantname': _nameController.text,
        'plantimage': downloadURL,
        'plantdescription': _descriptionController.text,
        'likes': 0,
        'comments': 0,
        'userId': user?.uid,
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
      body: _isUploading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                child: Column(
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
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.04,
                              ),
                              Text(
                                "Back",
                                style: GoogleFonts.ptSerif(
                                  textStyle: TextStyle(fontSize: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: getImage,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.4,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              image: _image != null
                                  ? FileImage(_image!)
                                  : NetworkImage(
                                      '',
                                    ) as ImageProvider,
                            ),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: _image == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt),
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
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: EdgeInsets.only(left: 8.0),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            hintText: "Plant Name",
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: EdgeInsets.only(left: 8.0),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 6,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            hintText: "Description",
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: uploadPost,
                        child: Text(
                          "Upload",
                          style: GoogleFonts.ptSerif(
                            textStyle:
                                TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
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
    );
  }
}
