import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String? id;
  final String name;
  final int age;
  final String department;
  final double salary;
  final String email;

  Employee({
    this.id,
    required this.name,
    required this.age,
    required this.department,
    required this.salary,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'department': department,
      'salary': salary,
      'email': email,
    };
  }

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Employee(
      id: doc.id,
      name: data['name'],
      age: data['age'],
      department: data['department'],
      salary: (data['salary'] as num).toDouble(),
      email: data['email'],
    );
  }
}

class EmployeeService {
  final _col = FirebaseFirestore.instance.collection('employees');

  Stream<List<Employee>> getEmployees() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => Employee.fromFirestore(d)).toList());

  Future<void> addEmployee(Employee e) => _col.add(e.toMap());

  Future<void> updateEmployee(Employee e) => _col.doc(e.id).update(e.toMap());

  Future<void> deleteEmployee(String id) => _col.doc(id).delete();

  Stream<List<Employee>> getEmployeesByDepartment(String dept) => _col
      .where('department', isEqualTo: dept)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => Employee.fromFirestore(d)).toList());
}

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final _service = EmployeeService();

  String _searchQuery = '';
  bool _isSearching = false;

  String _selectedDept = "All";

  final List<String> _departments = ["All", "HR", "IT", "Finance", "Marketing"];

  Stream<List<Employee>> get _activeStream {
    if (_selectedDept == "All") return _service.getEmployees();
    return _service.getEmployeesByDepartment(_selectedDept);
  }

  List<Employee> _applySearch(List<Employee> employees) {
    if (_searchQuery.isEmpty) return employees;

    return employees
        .where(
          (e) =>
              e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.email.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _openForm({Employee? employee}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EmployeeForm(
        employee: employee,
        onSave: (e) async {
          if (e.id == null) {
            await _service.addEmployee(e);
          } else {
            await _service.updateEmployee(e);
          }
        },
      ),
    );
  }

  void _confirmDelete(Employee e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Employee"),
        content: Text("Delete ${e.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteEmployee(e.id!);
              Navigator.pop(context);
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
                decoration: InputDecoration(
                  hintText: "Search by name or email",
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text("Employees"),

        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchQuery = '';
              });
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: Icon(Icons.person_add),
        label: Text("Add Employee"),
      ),

      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _departments.map((dept) {
                  final selected = _selectedDept == dept;

                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(dept),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedDept = dept),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Employee>>(
              stream: _activeStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final employees = _applySearch(snapshot.data ?? []);

                int total = employees.length;

                double avgSalary = 0;
                if (employees.isNotEmpty) {
                  avgSalary =
                      employees.map((e) => e.salary).reduce((a, b) => a + b) /
                      employees.length;
                }

                if (employees.isEmpty) {
                  return Center(child: Text("No employees found"));
                }

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            "Showing $total Employees",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),

                          if (_selectedDept != "All") ...[
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
                                _selectedDept,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: employees.length,
                        itemBuilder: (_, i) {
                          final e = employees[i];

                          return _EmployeeCard(
                            employee: e,
                            onEdit: () => _openForm(employee: e),
                            onDelete: () => _confirmDelete(e),
                          );
                        },
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.all(12),
                      color: Colors.grey.shade200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Employees: $total",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Avg Salary: ₹${avgSalary.toStringAsFixed(0)}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
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

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(employee.name[0].toUpperCase())),
        title: Text(employee.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.email),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Chip(label: "Age ${employee.age}"),
                SizedBox(width: 6),
                _Chip(label: employee.department),
                SizedBox(width: 6),
                _Chip(label: "₹${employee.salary}"),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
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

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

class _EmployeeForm extends StatefulWidget {
  final Employee? employee;
  final Future<void> Function(Employee) onSave;

  const _EmployeeForm({this.employee, required this.onSave});

  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _age;
  late TextEditingController _department;
  late TextEditingController _salary;
  late TextEditingController _email;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(text: widget.employee?.name ?? '');
    _age = TextEditingController(text: widget.employee?.age.toString() ?? '');
    _department = TextEditingController(
      text: widget.employee?.department ?? '',
    );
    _salary = TextEditingController(
      text: widget.employee?.salary.toString() ?? '',
    );
    _email = TextEditingController(text: widget.employee?.email ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      id: widget.employee?.id,
      name: _name.text,
      age: int.parse(_age.text),
      department: _department.text,
      salary: double.parse(_salary.text),
      email: _email.text,
    );

    await widget.onSave(employee);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return Padding(
      padding: EdgeInsets.all(16),

      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? "Edit Employee" : "Add Employee",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            _Field(controller: _name, label: "Name"),

            SizedBox(height: 10),

            _Field(controller: _email, label: "Email"),

            SizedBox(height: 10),

            _Field(
              controller: _age,
              label: "Age",
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 10),

            _Field(controller: _department, label: "Department"),

            SizedBox(height: 10),

            _Field(
              controller: _salary,
              label: "Salary",
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 20),

            FilledButton(
              onPressed: _submit,
              child: Text(isEditing ? "Save Changes" : "Add Employee"),
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
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
