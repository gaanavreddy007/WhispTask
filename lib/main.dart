import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(WhispTaskApp());
}

class WhispTaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhispTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1976D2),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Color(0xFFFF9800),
          primary: Color(0xFF1976D2),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1976D2),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Color(0xFFFF9800),
          primary: Color(0xFF1976D2),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        } else if (snapshot.hasData) {
          return TaskListScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

// Loading Screen
class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'WhispTask',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Task it. Say it. Done.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.mic,
                  size: 60,
                  color: Color(0xFF1976D2),
                ),
              ),
              SizedBox(height: 30),
              
              // App Name
              Text(
                'WhispTask',
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              
              // Tagline
              Text(
                'Task it. Say it. Done.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              
              Spacer(),
              
              // Sign In Button
              ElevatedButton(
                onPressed: () => _signInAnonymously(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1976D2),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              Text(
                'No signup required - Start using immediately!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    }
  }
}

// Task List Screen (Main Screen)
class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: 8),
            Text('WhispTask'),
          ],
        ),
        backgroundColor: Color(0xFF1976D2),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Task Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTaskScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9800),
                padding: EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 30, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Add New Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tasks List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .collection('tasks')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tap the button above to add your first task!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var task = snapshot.data!.docs[index];
                    return TaskCard(
                      taskId: task.id,
                      title: task['title'],
                      isCompleted: task['isCompleted'],
                      createdAt: task['createdAt'],
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

// Task Card Widget
class TaskCard extends StatelessWidget {
  final String taskId;
  final String title;
  final bool isCompleted;
  final Timestamp createdAt;

  TaskCard({
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          'Created at ${createdAt.toDate().toString().split('.')[0]}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: Icon(
            isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            color: Color(0xFFFF9800),
          ),
          onPressed: () async {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('tasks')
                  .doc(taskId)
                  .update({'isCompleted': !isCompleted});
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update task: $e')),
              );
            }
          },
        ),
        onLongPress: () async {
          // Delete task functionality
          bool? shouldDelete = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Delete Task'),
                content: Text('Are you sure you want to delete this task?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );

          if (shouldDelete == true) {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('tasks')
                  .doc(taskId)
                  .delete();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete task: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

// Add Task Screen
class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Add New Task', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1976D2),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            // Task Input Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What do you need to do?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _controller,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Task Description',
                        hintText: 'Enter your task here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Color(0xFF1976D2),
                            width: 2,
                          ),
                        ),
                      ),
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
            ),
            
            Spacer(),
            
            // Add Task Button
            ElevatedButton(
              onPressed: _isLoading ? null : _addTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9800),
                disabledBackgroundColor: Colors.grey[300],
                padding: EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Adding Task...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a task description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tasks')
          .add({
        'title': _controller.text.trim(),
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}