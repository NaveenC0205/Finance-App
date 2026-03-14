import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../widgets/drawer/app_drawer.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _nameCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _inviteCtrl.dispose(); super.dispose(); }

  void _showCreateDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Create Family'),
      content: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Family Name', hintText: 'e.g. The Sharma Family')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty) return;
            final ok = await context.read<FamilyProvider>().createFamily(_nameCtrl.text.trim());
            if (mounted) { Navigator.pop(context); if (!ok) _showError(); }
          },
          child: const Text('Create'),
        ),
      ],
    ));
  }

  void _showJoinDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Join Family'),
      content: TextField(controller: _inviteCtrl, decoration: const InputDecoration(labelText: 'Invite Code', hintText: 'e.g. ABC12345')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final ok = await context.read<FamilyProvider>().joinFamily(_inviteCtrl.text.trim());
            if (mounted) { Navigator.pop(context); if (!ok) _showError('Invalid invite code'); }
          },
          child: const Text('Join'),
        ),
      ],
    ));
  }

  void _showError([String msg = 'Something went wrong']) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      drawer: const AppDrawer(),
      body: family.loading
          ? const Center(child: CircularProgressIndicator())
          : !family.hasFamily
              ? _NoFamilyView(onCreate: _showCreateDialog, onJoin: _showJoinDialog)
              : _FamilyView(family: family),
    );
  }
}

class _NoFamilyView extends StatelessWidget {
  final VoidCallback onCreate, onJoin;
  const _NoFamilyView({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.people_rounded, color: AppColors.primary, size: 40)),
        const SizedBox(height: 20),
        const Text('No Family Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Create a family or join one with an invite code.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create Family')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onJoin, icon: const Icon(Icons.link), label: const Text('Join with Invite Code')),
      ]),
    ),
  );
}

class _FamilyView extends StatelessWidget {
  final FamilyProvider family;
  const _FamilyView({required this.family});

  void _copyInviteLink(BuildContext context) {
    final link = 'https://familyfinance.app/join/${family.family!.inviteCode}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite link copied!')));
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Family header card
      Card(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 26)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(family.family!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('${family.members.length} members', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Invite Code', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Text(family.family!.inviteCode,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 4, color: AppColors.primary)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _copyInviteLink(context),
              icon: const Icon(Icons.copy_rounded),
              style: IconButton.styleFrom(backgroundColor: AppColors.primaryLight, foregroundColor: AppColors.primary),
            ),
          ]),
        ]),
      )),
      const SizedBox(height: 20),

      // Members
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('${family.members.length} total', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 12),
      ...family.members.map((m) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: m.picture != null ? NetworkImage(m.picture!) : null,
            backgroundColor: AppColors.primary,
            child: m.picture == null ? Text(m.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
          ),
          title: Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(m.email, style: const TextStyle(fontSize: 12)),
          trailing: _RoleBadge(role: m.role),
        ),
      )),
    ]),
  );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: role == 'admin' ? AppColors.primaryLight : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(role.toUpperCase(), style: TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: role == 'admin' ? AppColors.primary : AppColors.textSecondary,
    )),
  );
}
