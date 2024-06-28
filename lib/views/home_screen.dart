import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task_app/core/constants/app_colors.dart';
import 'package:task_app/feature/project/project_item.dart';
import 'package:task_app/feature/project/project_model.dart';
import 'package:task_app/widget/common/nav_bar.dart';
import 'package:task_app/widget/common/custom_bottom_navigation_bar.dart';
import 'package:task_app/widget/searchBtn.dart';
import 'package:task_app/feature/task/widgets/add_task_button.dart';
import 'package:task_app/feature/task/model/task_model.dart'; // Import TaskModel
import 'package:task_app/feature/task/widgets/card_todo_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:task_app/feature/project/project_model.dart'; // Adjust the import path based on your project structure

class ProjectCard extends StatelessWidget {
  final Project project;

  ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name!,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: project.members!.map((member) {
                    return CircleAvatar(
                      radius: 15,
                      backgroundImage: AssetImage(member),
                      // You can use actual member images here if available
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(value: project.progress),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<Project> projects = [
    Project(
      name: 'Todo App',
      members: ['assets/images/avatar/avatar-4.png', 'assets/images/avatar/avatar-5.png', 'assets/images/avatar/avatar-6.png'],
      progress: 0.75,
    ),
    Project(
      name: 'Course system',
      members: ['assets/images/avatar/avatar-1.png', 'assets/images/avatar/avatar-2.png', 'assets/images/avatar/avatar-3.png'],
      progress: 0.4,
    ),
  ];
  late User? _currentUser;
  DocumentSnapshot<Map<String, dynamic>>? _userData;
  late String _userId;
  bool _isUserDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUser = user;
      _userId = user?.uid ?? '';
    });
    if (user != null) {
      _getUserData(user.uid);
    } else {
      print('No user signed in');
    }
  }

  void _getUserData(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userData =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _userData = userData;
        _isUserDataLoaded = true;
      });
      print('User Data: ${_userData?.data()}');
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var scaffoldKey = GlobalKey<ScaffoldState>();
    final today = DateFormat('M/dd/yyyy').format(DateTime.now());

    print('Today\'s Date: $today'); // Log today's date

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white, // Set the background color to white
      drawer: NavBar(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: _currentUser != null && _isUserDataLoaded && _userData != null
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/avatar/avatar-3.png'),
                    radius: 25,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hi, ${_userData!['username'] ?? 'User'}!',
                    style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Text('Loading...'),
        leading: IconButton(
          icon: const Icon(Icons.list),
          onPressed: () => scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SearchPage(),
              ));
            },
            icon: const Icon(
              Icons.search,
              size: 40,
              color: Colors.black,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Projects',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      SizedBox(
        height: 200, // Adjust the height as needed
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.all(10),
              child: ProjectCard(project: projects[index]),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "Today's Tasks",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: _userId)
                  .where('dueDate', isEqualTo: today) // Filter for today's tasks
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<TaskModel> tasks = snapshot.data!.docs.map((doc) {
                    final task = TaskModel.fromFirestore(doc);
                    print('Task Due Date: ${task.dueDate}'); // Log task due date
                    return task;
                  }).toList();

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/onBoarding/1.png',
                            height: 150,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No tasks for today!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }else {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0), // Adjust the padding as needed
    child: ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return CardTodoListWidget(task: tasks[index]);
      },
    ),
  );
}

                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: AddTaskButton(userId: _currentUser!.uid),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
