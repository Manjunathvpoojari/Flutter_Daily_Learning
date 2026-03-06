import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: StudentsPage());
  }
}

class Student {
  final String? id;
  final String name;
  final int age;
  final String grade;
  final String email;

  Student({
    this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'age': age, 'grade': grade, 'email': email};
  }

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['name'],
      age: data['age'],
      grade: data['grade'],
      email: data['email'],
    );
  }
}

class StudentService {
  final _col = FirebaseFirestore.instance.collection('students');

  Stream<List<Student>> getStudents() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((doc) => Student.fromFirestore(doc)).toList());
}

class StudentsPage extends StatefulWidget {
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final StudentService service = StudentService();

  void _openform(Student? student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StudentForm(
        student: student,
        onSave: (s) async {
          if (s.id == null) {
            await FirebaseFirestore.instance
                .collection('students')
                .add(s.toMap());
          } else {
            await FirebaseFirestore.instance
                .collection('students')
                .doc(s.id)
                .update(s.toMap());
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('students').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Students List"),
        centerTitle: true,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<List<Student>>(
        stream: service.getStudents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!;

          if (students.isEmpty) {
            return Center(child: Text("No students added yet"));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(
                    "${s.email} • Age ${s.age} • Grade ${s.grade}",
                  ),
                  leading: CircleAvatar(child: Text(s.name[0].toUpperCase())),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openform(s),
                      ),

                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(s.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openform(null),
        icon: Icon(Icons.person_add_alt_1_rounded),
        label: Text("Add Student"),
      ),
    );
  }
}

class _StudentForm extends StatefulWidget {
  final Student? student;
  final Future<void> Function(Student) onSave;

  _StudentForm({this.student, required this.onSave});

  @override
  State<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<_StudentForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _age;
  late TextEditingController _grade;
  late TextEditingController _email;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.student?.name ?? '');
    _age = TextEditingController(text: widget.student?.age.toString() ?? '');
    _grade = TextEditingController(text: widget.student?.grade ?? '');
    _email = TextEditingController(text: widget.student?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _grade.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final student = Student(
      id: widget.student?.id,
      name: _name.text,
      age: int.parse(_age.text),
      grade: _grade.text,
      email: _email.text,
    );

    await widget.onSave(student);

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),

      child: Form(
        key: _formKey,

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? "Edit Student" : "Add Student",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            _Field(
              controller: _name,
              label: "Name",
              icon: Icons.person,
              validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
            ),

            SizedBox(height: 12),

            _Field(
              controller: _email,
              label: "Email",
              icon: Icons.email,
              validator: (v) => v == null || v.isEmpty ? "Enter email" : null,
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _age,
                    label: "Age",
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Age";
                      if (int.tryParse(v) == null) return "Number";
                      return null;
                    },
                  ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: _Field(
                    controller: _grade,
                    label: "Grade",
                    icon: Icons.school,
                    validator: (v) => v == null || v.isEmpty ? "Grade" : null,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isEditing ? Icons.save : Icons.add),

              label: Text(isEditing ? "Save Changes" : "Add Student"),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,

      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }
}
