import 'package:flutter/material.dart';

const teal600 = Color(0xFF0D9488);
const teal700 = Color(0xFF0F766E);
const teal500 = Color(0xFF14B8A6);
const teal100 = Color(0xFFCCFBF1);
const teal50 = Color(0xFFF0FDFA);
const slate900 = Color(0xFF0F172A);
const slate700 = Color(0xFF334155);
const slate500 = Color(0xFF64748B);
const slate400 = Color(0xFF94A3B8);
const slate300 = Color(0xFFCBD5E1);
const slate200 = Color(0xFFE2E8F0);
const slate100 = Color(0xFFF1F5F9);

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final IconData rightIcon;
  final VoidCallback? onRight;

  const TopBar({
    super.key,
    required this.title,
    this.onBack,
    this.rightIcon = Icons.settings,
    this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: slate700),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: slate900),
            ),
          ),
          GestureDetector(
            onTap: onRight,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: teal600, shape: BoxShape.circle),
              child: Icon(rightIcon, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  final IconData icon;
  final Color bgColor;

  const IconCircle({super.key, required this.icon, this.bgColor = teal50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: teal700),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final bool rose;

  const TagChip({super.key, required this.label, this.rose = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: rose ? const Color(0xFFFFF1F2) : teal50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: rose ? const Color(0xFFE11D48) : teal700,
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final String active;
  final ValueChanged<String> onNavigate;

  const BottomNav({super.key, required this.active, required this.onNavigate});

  static const _items = [
    {'key': 'home',    'label': 'Home',    'icon': Icons.home},
    {'key': 'journal', 'label': 'Journal', 'icon': Icons.calendar_month},
    {'key': 'meds',    'label': 'Meds',    'icon': Icons.medication},
    {'key': 'records', 'label': 'Records', 'icon': Icons.description},
    {'key': 'profile', 'label': 'Profile', 'icon': Icons.person},
  ];

  static const _navKeys = {'home', 'journal', 'meds', 'records', 'profile'};

  @override
  Widget build(BuildContext context) {
    final displayActive = _navKeys.contains(active) ? active : 'profile';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: _items.map((item) {
          final isActive = displayActive == item['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onNavigate(item['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? teal600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: isActive ? Colors.white : slate500),
                    const SizedBox(height: 2),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
