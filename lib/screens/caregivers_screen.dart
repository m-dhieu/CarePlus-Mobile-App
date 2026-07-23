import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class CaregiversScreen extends ConsumerWidget {
  const CaregiversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregivers = ref.watch(caregiversProvider);
    void back() => ref.read(screenProvider.notifier).go('profile');

    return Column(
      children: [
        TopBar(
          title: 'Caregivers',
          onBack: back,
          rightIcon: Icons.person_add,
          onRight: () => _showAddDialog(context, ref),
        ),
        Expanded(
          child: caregivers.isEmpty
              ? const Center(child: Text('No caregivers added', style: TextStyle(color: slate400)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: caregivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CaregiverCard(caregiver: caregivers[i]),
                ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    CaregiverRole role = CaregiverRole.viewOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Caregiver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: slate900)),
              const SizedBox(height: 16),
              _SheetField(ctrl: nameCtrl, label: 'Name', hint: 'e.g. Grace Mugisha'),
              const SizedBox(height: 12),
              _SheetField(ctrl: relationCtrl, label: 'Relation', hint: 'e.g. Spouse'),
              const SizedBox(height: 12),
              _SheetField(ctrl: phoneCtrl, label: 'Phone', hint: '+250 788 000 000'),
              const SizedBox(height: 12),
              const Text('Access level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<CaregiverRole>(
                initialValue: role,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: slate200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: CaregiverRole.values.map((r) {
                  final labels = {
                    CaregiverRole.fullAccess: 'Full access',
                    CaregiverRole.viewOnly: 'View only',
                    CaregiverRole.medsOnly: 'Meds only',
                  };
                  return DropdownMenuItem(value: r, child: Text(labels[r]!));
                }).toList(),
                onChanged: (v) => setS(() => role = v!),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  ref.read(caregiversProvider.notifier).add(Caregiver(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    relation: relationCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: role,
                  ));
                  Navigator.pop(ctx);
                  ref.read(toastProvider.notifier).show('Caregiver added');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                  child: const Text('Add caregiver', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaregiverCard extends ConsumerWidget {
  final Caregiver caregiver;
  const _CaregiverCard({required this.caregiver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColors = {
      CaregiverRole.fullAccess: teal600,
      CaregiverRole.viewOnly: slate500,
      CaregiverRole.medsOnly: const Color(0xFFD97706),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: teal100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: teal50, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    caregiver.name.split(' ').map((w) => w[0]).take(2).join(),
                    style: const TextStyle(color: teal700, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caregiver.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: slate900)),
                    Text('${caregiver.relation} · ${caregiver.phone}',
                        style: const TextStyle(fontSize: 11, color: slate400)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColors[caregiver.role]!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(caregiver.roleLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: roleColors[caregiver.role])),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CaregiverRole>(
                  initialValue: caregiver.role,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Access',
                    labelStyle: const TextStyle(fontSize: 11, color: slate400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: slate200)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  items: CaregiverRole.values.map((r) {
                    const labels = {
                      CaregiverRole.fullAccess: 'Full access',
                      CaregiverRole.viewOnly: 'View only',
                      CaregiverRole.medsOnly: 'Meds only',
                    };
                    return DropdownMenuItem(value: r, child: Text(labels[r]!, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (v) => ref.read(caregiversProvider.notifier).updateRole(caregiver.id, v!),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Text('Notify', style: TextStyle(fontSize: 12, color: slate500)),
                  Switch(
                    value: caregiver.notificationsEnabled,
                    activeThumbColor: teal600,
                    onChanged: (_) => ref.read(caregiversProvider.notifier).toggleNotifications(caregiver.id),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ref.read(caregiversProvider.notifier).remove(caregiver.id),
                child: const Icon(Icons.delete_outline, size: 18, color: slate400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  const _SheetField({required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal700)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: slate200)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
