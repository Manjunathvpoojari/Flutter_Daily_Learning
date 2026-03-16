import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  //translator - display student data from firestore to app
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

  // Reaading documents
  Stream<List<Student>> getStudents() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((doc) => Student.fromFirestore(doc)).toList());

  // method for creating students
  Future<void> addStudent(Student s) => _col.add(s.toMap());

  // method to update students
  Future<void> updateStudent(Student s) => _col.doc(s.id).update(s.toMap());

  // method to delete students
  Future<void> deleteStudent(String id) => _col.doc(id).delete();

  // method to filterBYgrades
  Stream<List<Student>> getStudentsByGrade(String grade) => _col
      .where('grade', isEqualTo: grade)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((doc) => Student.fromFirestore(doc)).toList());

  Stream<List<Student>> getStudentsQuery({
    required String grade,
    required int minAge,
    required int maxAge,
    required bool ascending,
    required int limit,
  }) {
    Query query = _col;

    //  apply grade filter for specific grades
    if (grade != 'All') {
      query = query.where('grade', isEqualTo: grade);
    }

    // age sorting
    query = query.orderBy('age', descending: !ascending);

    // range filter for age
    query = query
        .where('age', isGreaterThanOrEqualTo: minAge)
        .where('age', isLessThanOrEqualTo: maxAge);

    // applying the limit of students
    query = query.limit(limit);

    return query.snapshots().map(
      (s) => s.docs.map((doc) => Student.fromFirestore(doc)).toList(),
    );
  }
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _service = StudentService();

  // Search OP
  String _searchQuery = '';
  bool _isSearching = false;

  // Filter Grade
  String _selectedGrade = 'All';

  final List<String> _grades = ['All', 'A', 'B', 'C', 'D'];

  // sorting
  bool _ascending = true;

  // age range
  RangeValues _ageRange = RangeValues(1, 100);

  // showmore limit
  int _limit = 5;

  Stream<List<Student>> get _activeStream => _service.getStudentsQuery(
    grade: _selectedGrade,
    minAge: _ageRange.start.toInt(),
    maxAge: _ageRange.end.toInt(),
    ascending: _ascending,
    limit: _limit,
  );

  // Searching name And email
  List<Student> _applySearch(List<Student> students) {
    if (_searchQuery.isEmpty) return students;

    return students
        .where(
          (s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.email.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _openform({Student? student}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StudentForm(
        student: student,
        onSave: (s) async {
          // create new student if id is null, otherwise update existing student
          if (s.id == null) {
            await _service.addStudent(s);
          }
          // if id is not null, update the existing student document with the new data
          else {
            await _service.updateStudent(s);
          }
        },
      ),
    );
  }

  void _confirmDelete(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Student"),
        content: Text("Are you sure you want to delete ${student.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),

          // delete the student document from firestore when user confirms deletion
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteStudent(student.id!);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${student.name} deleted')),
                );
              }
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(
                  color: const Color.fromARGB(255, 232, 187, 80),
                ),
                decoration: InputDecoration(
                  hintText: 'Search by Name or Email',
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(153, 240, 238, 238),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() {
                  _searchQuery = val;
                }),
              )
            : Text("Students List"),
        centerTitle: true,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'CloseSearch' : 'Search',
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
              }
            }),
          ),

          IconButton(
            icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _ascending ? 'Oldest First' : 'Youngest First',

            onPressed: () => setState(() {
              _ascending = !_ascending;
              _limit = 5;
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openform(),
        icon: Icon(Icons.person_add_alt_1_rounded),
        label: Text("Add Student"),
      ),

      body: Column(
        children: [
          Container(
            color: Colors.purple.shade50,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: Row(
                children: _grades.map((grade) {
                  final isSelected = _selectedGrade == grade;

                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        grade == 'All' ? 'All Grades' : 'Grade $grade',
                      ),
                      selected: isSelected,
                      selectedColor: Colors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),

                      onSelected: (_) => setState(() {
                        _selectedGrade = grade;
                        _limit = 5;
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Container(
            color: Colors.purple.shade50,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Age Range: ${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple.shade800,
                  ),
                ),

                RangeSlider(
                  values: _ageRange,
                  min: 1,
                  max: 100,
                  divisions: 99,

                  labels: RangeLabels(
                    _ageRange.start.toInt().toString(),
                    _ageRange.end.toInt().toString(),
                  ),

                  activeColor: Colors.teal,

                  onChanged: (newValue) => setState(() {
                    _ageRange = newValue;
                    _limit = 5;
                  }),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _activeStream,
              builder: (context, snapshot) {
                // Waiting for data to load, show a loading indicator
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Error occurred while loading data, show an error message
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Error loading students: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final students = _applySearch(snapshot.data ?? []);

                // Data Empty, show a message indicating no students found
                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No Students found "$_searchQuery"'
                              : _selectedGrade != 'All'
                              ? 'No Students in Grade "$_selectedGrade"'
                              : 'No students found. Please add some students.',
                        ),
                      ],
                    ),
                  );
                }

                // Data loaded successfully, show the list of students
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${students.length} Student${students.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color.fromARGB(255, 82, 160, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          if (_selectedGrade != 'All') ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Text(
                                'Grade $_selectedGrade',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],

                          SizedBox(width: 8),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _ascending ? 'Age (↑)' : 'Age (↓)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),

                        itemBuilder: (_, i) => _StudentCard(
                          student: students[i],
                          onEdit: () => _openform(student: students[i]),
                          onDelete: () => _confirmDelete(students[i]),
                        ),
                      ),
                    ),

                    if (students.length >= _limit)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.expand_more),
                          label: Text("Show more"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: BorderSide(color: Colors.purple),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () => setState(() {
                            _limit += 5;
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 156, 243, 86),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
          ),
        ),
        title: Text(
          student.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            SizedBox(height: 2),
            Text(student.email, style: TextStyle(fontSize: 12)),
            SizedBox(height: 2),
            Row(
              children: [
                _Chip(label: 'Age ${student.age}'),
                SizedBox(width: 6),
                _Chip(label: 'Grade ${student.grade}'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              color: Colors.blue,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: Colors.white)),
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

    try {
      await widget.onSave(student);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving student: $e")));
      setState(() => _saving = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isEditing ? "Edit Student" : "Add new Student",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            _Field(
              controller: _name,
              label: "Name",
              icon: Icons.person,
              validator: (value) =>
                  value == null || value.isEmpty ? "Please enter a name" : null,
            ),

            SizedBox(height: 12),

            _Field(
              controller: _email,
              label: "Email",
              icon: Icons.email,
              validator: (value) => value == null || value.isEmpty
                  ? "Please enter an email"
                  : null,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter an age";
                      }
                      if (int.tryParse(value) == null) {
                        return "Please enter a valid number";
                      }
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
                    validator: (value) => value == null || value.isEmpty
                        ? "Please enter a grade"
                        : null,
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
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            SizedBox(height: 40),
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
