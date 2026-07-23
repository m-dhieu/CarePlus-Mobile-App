import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toast(String msg) => ref.read(toastProvider.notifier).show(msg);
    void back() => ref.read(screenProvider.notifier).go('home');
    final tokens = ref.watch(shareTokensProvider);
    final docs = ref.watch(documentsProvider);
    final ocrResult = ref.watch(ocrProvider);

    return Column(
      children: [
        TopBar(
          title: 'Medical Records',
          onBack: back,
          rightIcon: Icons.share,
          onRight: () => _showShareDialog(context, ref),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // OR Record Exchange
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: teal100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('END-TO-END ENCRYPTED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: slate400, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      const Text(
                        'One complete medical history — across every doctor and hospital that has treated you.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showShareDialog(context, ref),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share, size: 14, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Share with a new doctor',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active share tokens
                if (tokens.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Active share tokens', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                  const SizedBox(height: 8),
                  ...tokens.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.isExpired ? slate100 : teal50,
                      border: Border.all(color: t.isExpired ? slate200 : teal100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.token,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: slate900)),
                              Text('${t.doctorName} · ${t.isExpired ? 'Expired' : 'Active'}',
                                  style: TextStyle(fontSize: 11, color: t.isExpired ? slate400 : teal600)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: t.token));
                            toast('Token copied');
                          },
                          child: const Icon(Icons.copy, size: 16, color: slate400),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => ref.read(shareTokensProvider.notifier).revoke(t.token),
                          child: const Icon(Icons.close, size: 16, color: slate400),
                        ),
                      ],
                    ),
                  )),
                ],

                const SizedBox(height: 20),
                // OCR Lab Import
                const Text('Import Lab Results (OCR)', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                _OcrImportCard(ocrResult: ocrResult),

                const SizedBox(height: 20),
                const Text('Hospitals', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mockHospitals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final h = mockHospitals[i];
                      return Container(
                        width: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [teal600, teal500], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h['name'] as String,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${h['visits']}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('VISITS', style: TextStyle(fontSize: 10, color: teal100)),
                                    Text('since ${h['since']}', style: const TextStyle(fontSize: 10, color: teal100)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Documents', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                ...docs.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: teal100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconCircle(icon: d.icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                            Text(d.source,
                                style: const TextStyle(fontSize: 11, color: slate400)),
                            if (d.ocrText != null)
                              const Text('OCR imported', style: TextStyle(fontSize: 10, color: teal600)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => toast('Downloading "${d.name}" needs a backend connection'),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(border: Border.all(color: slate200), shape: BoxShape.circle),
                          child: const Icon(Icons.download, size: 14, color: slate500),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                const Text('Doctor feedback', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                ...mockDoctorFeedback.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: teal100), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: teal100, shape: BoxShape.circle),
                            child: Center(child: Text(f['initials'] as String,
                                style: const TextStyle(color: teal700, fontWeight: FontWeight.w700, fontSize: 13))),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f['name'] as String,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: slate900)),
                              Text(f['role'] as String,
                                  style: const TextStyle(fontSize: 11, color: slate400)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Color(0xFF99F6E4), width: 2)),
                        ),
                        child: Text(f['note'] as String,
                            style: const TextStyle(fontSize: 12, color: slate700, fontStyle: FontStyle.italic, height: 1.5)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showShareDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: slate900)),
            const SizedBox(height: 16),
            const Text('Doctor name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal700)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. Dr. Amara Diallo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: slate200)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (controller.text.trim().isEmpty) return;
                final token = ref.read(shareTokensProvider.notifier).generate(controller.text.trim());
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: token.token));
                ref.read(toastProvider.notifier).show('Token ${token.token} copied — valid 24h');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                child: const Text('Generate & copy token', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrImportCard extends ConsumerWidget {
  final String? ocrResult;
  const _OcrImportCard({required this.ocrResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(_ocrLoadingProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: teal100), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconCircle(icon: Icons.document_scanner),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan lab document', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                    Text('Extract values automatically via OCR', style: TextStyle(fontSize: 11, color: slate400)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: isProcessing ? null : () => _runOcr(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                  child: isProcessing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Scan', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          if (ocrResult != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: teal50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Extracted values', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal700)),
                  const SizedBox(height: 6),
                  Text(ocrResult!, style: const TextStyle(fontSize: 12, color: slate700, height: 1.6)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(documentsProvider.notifier).addOcrDocument(
                        MedicalDocument(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          icon: Icons.science,
                          name: 'OCR Lab Import ${DateTime.now().day}/${DateTime.now().month}',
                          source: 'Scanned · ${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                          ocrText: ocrResult,
                        ),
                      );
                      ref.read(ocrProvider.notifier).clear();
                      ref.read(toastProvider.notifier).show('Lab results saved to documents');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                      child: const Text('Save to documents', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runOcr(BuildContext context, WidgetRef ref) async {
    ref.read(_ocrLoadingProvider.notifier).set(true);
    await ref.read(ocrProvider.notifier).processImage('simulated_path');
    ref.read(_ocrLoadingProvider.notifier).set(false);
  }

  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// Local loading state for OCR button
class _OcrLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final _ocrLoadingProvider = NotifierProvider<_OcrLoadingNotifier, bool>(_OcrLoadingNotifier.new);
