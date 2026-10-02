import 'package:flutter/material.dart';
import '../models/users_table_model.dart';
import '../services/firebase_users_table_service.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'All'; // 'All', 'customer', 'admin'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddUserDialog(
    BuildContext context, [
    UsersTableModel? existingUser,
  ]) {
    final isEditing = existingUser != null;
    final firstNameCtrl = TextEditingController(text: isEditing ? existingUser.firstName : '');
    final middleNameCtrl = TextEditingController(text: isEditing ? existingUser.middleName : '');
    final lastNameCtrl = TextEditingController(text: isEditing ? existingUser.lastName : '');
    final emailCtrl = TextEditingController(text: isEditing ? existingUser.emailAddress : '');
    final phoneCtrl = TextEditingController(text: isEditing ? existingUser.phoneNumber : '');
    final birthdayCtrl = TextEditingController(text: isEditing ? existingUser.birthday : '');
    final addressCtrl = TextEditingController(text: isEditing ? existingUser.address : '');
    String selectedRole = isEditing ? existingUser.role : 'customer';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.manage_accounts : Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit User' : 'Add New User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: middleNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Middle Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailCtrl,
                        enabled: !isEditing,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: birthdayCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Birthday (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Role selector
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'customer', child: Text('Customer')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedRole = v ?? 'customer'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          final firstName = firstNameCtrl.text.trim();
                          final lastName = lastNameCtrl.text.trim();

                          if (email.isEmpty || firstName.isEmpty || lastName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter First Name, Last Name, and Email'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          final newUser = UsersTableModel(
                            firstName: firstName,
                            middleName: middleNameCtrl.text.trim(),
                            lastName: lastName,
                            birthday: birthdayCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            emailAddress: email,
                            phoneNumber: phoneCtrl.text.trim(),
                            role: selectedRole,
                          );

                          final success = await FirebaseUsersTableService.saveUserToFirestore(newUser);

                          if (mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '${isEditing ? "Updated" : "Added"} $email in Supabase users_table ✅'
                                      : 'Failed to save user',
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Add User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleUserRole(BuildContext context, UsersTableModel user) async {
    final newRole = user.isAdmin ? 'customer' : 'admin';
    final action = user.isAdmin ? 'Demote to Customer' : 'Promote to Admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action),
        content: Text(
          '${action} "${user.fullName}" (${user.emailAddress})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isAdmin ? Colors.orange : const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await FirebaseUsersTableService.updateUserRole(user.emailAddress, newRole);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${user.fullName} is now a $newRole ✅'
                : 'Failed to update role',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteUser(BuildContext context, String emailAddress) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$emailAddress" from users_table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await FirebaseUsersTableService.deleteUserFromFirestore(emailAddress);
              if (context.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Deleted $emailAddress ✅' : 'Failed to delete user',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final padding = isMobile ? 16.0 : 32.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                spacing: 16,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Management',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supabase users_table — live data',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Search + Role Filter ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or phone…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _roleFilter,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(10),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Roles')),
                      DropdownMenuItem(value: 'customer', child: Text('Customers')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v ?? 'All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Live Table ───────────────────────────────────────────────────
              StreamBuilder<List<UsersTableModel>>(
                stream: FirebaseUsersTableService.streamUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final query = _searchQuery.toLowerCase();
                  final allUsers = snapshot.data ?? [];

                  final filteredUsers = allUsers.where((u) {
                    final matchesRole = _roleFilter == 'All' || u.role == _roleFilter;
                    final matchesSearch = query.isEmpty ||
                        u.fullName.toLowerCase().contains(query) ||
                        u.emailAddress.toLowerCase().contains(query) ||
                        u.phoneNumber.toLowerCase().contains(query);
                    return matchesRole && matchesSearch;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            allUsers.isEmpty
                                ? 'No user records found in Supabase users_table'
                                : 'No users match your search/filter',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          if (allUsers.isEmpty)
                            TextButton.icon(
                              onPressed: () => _showAddUserDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add your first user'),
                            ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row count badge
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Text(
                            '${filteredUsers.length} user${filteredUsers.length == 1 ? '' : 's'} found',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: (constraints.maxWidth - (padding * 2)).clamp(700.0, double.infinity),
                            ),
                            child: DataTable(
                              columnSpacing: isMobile ? 16 : 24,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columns: const [
                                DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Birthday', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredUsers.map((user) {
                                return DataRow(
                                  cells: [
                                    // Full Name
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: (user.isAdmin
                                                  ? const Color(0xFF2563EB)
                                                  : brandColor)
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                            style: TextStyle(
                                              color: user.isAdmin ? const Color(0xFF2563EB) : brandColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    )),
                                    // Email
                                    DataCell(Text(user.emailAddress, style: const TextStyle(color: Color(0xFF475569)))),
                                    // Phone
                                    DataCell(Text(user.phoneNumber.isNotEmpty ? user.phoneNumber : 'N/A')),
                                    // Birthday
                                    DataCell(Text(user.birthday.isNotEmpty ? user.birthday : 'N/A')),
                                    // Address
                                    DataCell(SizedBox(
                                      width: 160,
                                      child: Text(
                                        user.address.isNotEmpty ? user.address : 'N/A',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    )),
                                    // Role badge
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: user.isAdmin
                                              ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                              : Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          user.isAdmin ? '👑 Admin' : '🛒 Customer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: user.isAdmin ? const Color(0xFF2563EB) : Colors.green[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Actions
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () => _showAddUserDialog(context, user),
                                          style: TextButton.styleFrom(foregroundColor: brandColor),
                                          child: const Text('Edit'),
                                        ),
                                        // Promote / Demote toggle
                                        Tooltip(
                                          message: user.isAdmin ? 'Demote to Customer' : 'Promote to Admin',
                                          child: IconButton(
                                            onPressed: () => _toggleUserRole(context, user),
                                            icon: Icon(
                                              user.isAdmin
                                                  ? Icons.arrow_downward_rounded
                                                  : Icons.arrow_upward_rounded,
                                              size: 18,
                                              color: user.isAdmin ? Colors.orange : const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _confirmDeleteUser(context, user.emailAddress),
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
