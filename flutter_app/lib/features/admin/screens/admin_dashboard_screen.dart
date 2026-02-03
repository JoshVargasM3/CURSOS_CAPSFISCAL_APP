import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin CAPFISCAL'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cursos'),
            Tab(text: 'Sesiones'),
            Tab(text: 'Enrollments'),
            Tab(text: 'Roles'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CoursesTab(),
          _SessionsTab(),
          _EnrollmentsTab(),
          _RolesTab(),
        ],
      ),
    );
  }
}

class _CoursesTab extends ConsumerStatefulWidget {
  const _CoursesTab();

  @override
  ConsumerState<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<_CoursesTab> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final stateController = TextEditingController();
  final sedeController = TextEditingController();
  final priceController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  String paymentModeAllowed = 'both';
  bool isActive = true;

  Future<void> _submit() async {
    final firestore = ref.read(firestoreProvider);
    await firestore.collection('courses').add({
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'stateId': stateController.text.trim(),
      'sedeId': sedeController.text.trim(),
      'startDate': Timestamp.fromDate(startDate ?? DateTime.now()),
      'endDate': Timestamp.fromDate(endDate ?? DateTime.now().add(const Duration(days: 1))),
      'priceFull': double.tryParse(priceController.text) ?? 0,
      'paymentModeAllowed': paymentModeAllowed,
      'isActive': isActive,
    });
    titleController.clear();
    descriptionController.clear();
    stateController.clear();
    sedeController.clear();
    priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
          TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descripción')),
          TextField(controller: stateController, decoration: const InputDecoration(labelText: 'State ID')),
          TextField(controller: sedeController, decoration: const InputDecoration(labelText: 'Sede ID')),
          TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Precio completo')),
          DropdownButtonFormField<String>(
            value: paymentModeAllowed,
            decoration: const InputDecoration(labelText: 'Modo de pago'),
            items: const [
              DropdownMenuItem(value: 'full_only', child: Text('Solo completo')),
              DropdownMenuItem(value: 'per_session_only', child: Text('Solo sesiones')),
              DropdownMenuItem(value: 'both', child: Text('Ambos')),
            ],
            onChanged: (value) => setState(() => paymentModeAllowed = value ?? 'both'),
          ),
          SwitchListTile(
            value: isActive,
            onChanged: (value) => setState(() => isActive = value),
            title: const Text('Activo'),
          ),
          ElevatedButton(onPressed: _submit, child: const Text('Crear curso')),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore.collection('courses').snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return ListTile(
                      title: Text(doc.data()['title'] as String? ?? doc.id),
                      subtitle: Text(doc.id),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _SessionsTab extends ConsumerStatefulWidget {
  const _SessionsTab();

  @override
  ConsumerState<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends ConsumerState<_SessionsTab> {
  String? selectedCourseId;
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  DateTime? dateTime;
  bool isActive = true;

  Future<void> _createSession() async {
    if (selectedCourseId == null) return;
    final firestore = ref.read(firestoreProvider);
    await firestore.collection('courses/$selectedCourseId/sessions').add({
      'title': titleController.text.trim(),
      'dateTime': Timestamp.fromDate(dateTime ?? DateTime.now()),
      'price': double.tryParse(priceController.text) ?? 0,
      'isActive': isActive,
    });
    titleController.clear();
    priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore.collection('courses').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                value: selectedCourseId,
                decoration: const InputDecoration(labelText: 'Curso'),
                items: docs
                    .map((doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc.data()['title'] as String? ?? doc.id),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedCourseId = value),
              );
            },
          ),
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título sesión')),
          TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Precio sesión')),
          SwitchListTile(
            value: isActive,
            onChanged: (value) => setState(() => isActive = value),
            title: const Text('Activa'),
          ),
          ElevatedButton(onPressed: _createSession, child: const Text('Crear sesión')),
          const SizedBox(height: 16),
          if (selectedCourseId != null)
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestore.collection('courses/$selectedCourseId/sessions').snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return ListTile(
                        title: Text(doc.data()['title'] as String? ?? doc.id),
                        subtitle: Text(doc.id),
                      );
                    },
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}

class _EnrollmentsTab extends ConsumerStatefulWidget {
  const _EnrollmentsTab();

  @override
  ConsumerState<_EnrollmentsTab> createState() => _EnrollmentsTabState();
}

class _EnrollmentsTabState extends ConsumerState<_EnrollmentsTab> {
  final stateController = TextEditingController();
  final sedeController = TextEditingController();
  final courseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);
    Query<Map<String, dynamic>> query = firestore.collection('enrollments');
    if (stateController.text.isNotEmpty) {
      query = query.where('stateId', isEqualTo: stateController.text.trim());
    }
    if (sedeController.text.isNotEmpty) {
      query = query.where('sedeId', isEqualTo: sedeController.text.trim());
    }
    if (courseController.text.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseController.text.trim());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: stateController, decoration: const InputDecoration(labelText: 'Filtro stateId')),
          TextField(controller: sedeController, decoration: const InputDecoration(labelText: 'Filtro sedeId')),
          TextField(controller: courseController, decoration: const InputDecoration(labelText: 'Filtro courseId')),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return ListTile(
                      title: Text(data['uid'] as String? ?? doc.id),
                      subtitle: Text('Curso: ${data['courseId']} - Estado: ${data['status']}'),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _RolesTab extends ConsumerStatefulWidget {
  const _RolesTab();

  @override
  ConsumerState<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends ConsumerState<_RolesTab> {
  final emailController = TextEditingController();
  String role = 'checker';
  String? message;

  Future<void> _assignRole() async {
    final firestore = ref.read(firestoreProvider);
    final functions = ref.read(functionsProvider);
    setState(() => message = null);
    final users = await firestore
        .collection('users')
        .where('email', isEqualTo: emailController.text.trim())
        .limit(1)
        .get();
    if (users.docs.isEmpty) {
      setState(() => message = 'Usuario no encontrado');
      return;
    }
    final uid = users.docs.first.id;
    final callable = functions.httpsCallable('setRole');
    await callable.call({ 'uid': uid, 'role': role });
    setState(() => message = 'Rol asignado a $uid');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText: 'Rol'),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'checker', child: Text('Checker')),
              DropdownMenuItem(value: 'customer', child: Text('Customer')),
            ],
            onChanged: (value) => setState(() => role = value ?? 'checker'),
          ),
          ElevatedButton(onPressed: _assignRole, child: const Text('Asignar rol')),
          if (message != null) Padding(
            padding: const EdgeInsets.all(8),
            child: Text(message!),
          )
        ],
      ),
    );
  }
}
