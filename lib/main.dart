import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ModernStudioApp(),
  ));
}

class ModernStudioApp extends StatefulWidget {
  const ModernStudioApp({super.key});

  @override
  State<ModernStudioApp> createState() => _ModernStudioAppState();
}

class _ModernStudioAppState extends State<ModernStudioApp> {
  // สไตล์วิดีโอ: UGC รีวิว หรือ POV
  String _videoStyle = "UGC"; // 'UGC' หรือ 'POV'

  // ความยาวคลิป: 10, 20, 30 วินาที
  int _duration = 20;

  // ภาษา / สำเนียง
  String _dialect = "กลาง"; // 'กลาง', 'อีสาน', 'เหนือ', 'ใต้'

  // ฉากหลัง
  String _scene = "สตูดิโอมินิมอล";
  final List<String> _scenes = [
    "สตูดิโอมินิมอล",
    "ในห้องนั่งเล่น",
    "คาเฟ่โมเดิร์น",
    "ตลาดนัด",
    "ห้างสรรพสินค้า",
    "โรงงาน / หน้าร้าน",
  ];

  // ตัวละคร / คนรีวิว
  String _character = "หญิง (ลุคสดใส)";
  final List<String> _characters = [
    "หญิง (ลุคสดใส)",
    "หญิง (ลุคทางการ)",
    "ชาย (ลุคสมาร์ท)",
    "ชาย (ลุคเป็นกันเอง)",
  ];

  // ข้อมูลสินค้า
  final TextEditingController _prodNameCtrl =
      TextEditingController(text: "กล้องวงจรปิด CCTV ไร้สาย โซลาร์เซลล์ 3 เลนส์ สีดำ");
  final TextEditingController _sellingPointCtrl =
      TextEditingController(text: "คมชัด 4K ติดตั้งง่าย ไม่ต้องเดินสายไฟ แบตอึดตลอดคืน");

  // ฟังก์ชันสลับไปเปิด Meta AI
  Future<void> _openMetaAI() async {
    final Uri url = Uri.parse('https://www.meta.ai');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  // สร้าง Prompt สไตล์สตูดิโอแบบเรียลไทม์
  String _generatePrompt() {
    final prod = _prodNameCtrl.text.trim();
    final points = _sellingPointCtrl.text.trim();

    String speech = "";
    if (_dialect == "อีสาน") {
      speech = "พี่น้องเอ้ย ตัวนี้เด็ดอีหลี $prod $points ฟังก์ชันจัดเต็ม กดในตะกร้าด้านล่างได้เลยเด้อ!";
    } else if (_dialect == "เหนือ") {
      speech = "ทุกคนเจ้า ตัวนี้ดีแต้ๆ $prod $points ไผสนใจรีบกดในตะกร้าด้านล่างเลยเจ้า!";
    } else if (_dialect == "ใต้") {
      speech = "เหวอเพื่อนเหอ ตัวนี้หรอยแรง $prod $points รีบกดในตะกร้าด้านล่างด่วนเลย!";
    } else {
      speech = "ทุกคน ใครมองหา $prod ฟังทางนี้เลยครับ $points โปรคุ้มมาก รีบกดสั่งในตะกร้าสีเหลืองซ้ายมือด่วนเลยครับ!";
    }

    if (_videoStyle == "POV") {
      return "Vertical 9:16 high-definition commercial POV product showcase. "
          "Close-up first-person view of two hands carefully presenting and rotating the exact product: $prod. "
          "Selling points demonstrated: $points. Background setting: $_scene with soft ambient lighting. "
          "Voiceover speaks fluently in Thai ($_dialect dialect): '$speech'. 4k photorealistic, clean cinematic 35mm lens.";
    } else {
      return "Vertical 9:16 realistic UGC commercial review video. "
          "Featuring a Thai creator ($_character) in a $_scene setting, naturally demonstrating the exact product: $prod. "
          "Duration: $_duration seconds. Performance: Confident camera eye-contact, showcasing product texture ($points), smiling and pointing down toward the bottom-left shopping cart. "
          "Spoken dialogue perfectly lip-synced in Thai ($_dialect dialect): '$speech'. True commercial studio quality.";
    }
  }

  void _copyPrompt() {
    final prompt = _generatePrompt();
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text("คัดลอก Prompt สำเร็จ! พร้อมเปิด Meta AI"),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    _openMetaAI();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "AI Video Creator Pro",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, color: Colors.indigo),
            tooltip: "เปิด Meta AI",
            onPressed: _openMetaAI,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ตัวเลือกสไตล์คลิปแบบ Segmented Control (POV vs UGC)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ],
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _videoStyle = "UGC"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _videoStyle == "UGC" ? const Color(0xFF6366F1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_pin_rounded,
                                size: 18, color: _videoStyle == "UGC" ? Colors.white : Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              "UGC รีวิว (มีคนพูด)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _videoStyle == "UGC" ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _videoStyle = "POV"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _videoStyle == "POV" ? const Color(0xFF6366F1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pan_tool_alt_rounded,
                                size: 18, color: _videoStyle == "POV" ? Colors.white : Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              "POV (เห็นเฉพาะมือ)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _videoStyle == "POV" ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. การ์ดตั้งค่าความยาวและสำเนียง
            _buildCard(
              title: "⏱️ ความยาวคลิป & ภาษาสำเนียง",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ความยาววิดีโอ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [10, 20, 30].map((sec) {
                      final isSelected = _duration == sec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text("$sec วินาที"),
                          selected: isSelected,
                          selectedColor: const Color(0xFFEEF2FF),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _duration = sec);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text("ภาษาและสำเนียงพูด", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ["กลาง", "อีสาน", "เหนือ", "ใต้"].map((d) {
                      final isSelected = _dialect == d;
                      return ChoiceChip(
                        label: Text("ภาษา$d"),
                        selected: isSelected,
                        selectedColor: const Color(0xFFF3E8FF),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF7E22CE) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFA855F7) : Colors.grey.shade300,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _dialect = d);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. การ์ดข้อมูลสินค้า
            _buildCard(
              title: "📦 ข้อมูลสินค้าที่ต้องการโปรโมท",
              child: Column(
                children: [
                  TextField(
                    controller: _prodNameCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: "ชื่อสินค้า",
                      labelStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _sellingPointCtrl,
                    onChanged: (_) => setState(() {}),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "จุดเด่น / จุดขายสำคัญ",
                      labelStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.star_outline_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. การ์ดฉากหลังและตัวละคร (ถ้าเลือกแบบ UGC)
            _buildCard(
              title: "🎬 สภาพแวดล้อมและบรรยากาศ",
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _scene,
                    decoration: InputDecoration(
                      labelText: "ฉากหลังของคลิป",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                    items: _scenes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setState(() => _scene = val!),
                  ),
                  if (_videoStyle == "UGC") ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _character,
                      decoration: InputDecoration(
                        labelText: "บุคลิกคนรีวิว (ครีเอเตอร์)",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        isDense: true,
                      ),
                      items: _characters.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => _character = val!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. กล่อง Prompt Preview แบบไดนามิก
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: Colors.greenAccent, size: 16),
                      SizedBox(width: 6),
                      Text("Prompt ที่ระบบประกอบให้อัตโนมัติ",
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _generatePrompt(),
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, height: 1.4, fontFamily: 'monospace'),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. ปุ่ม Action ด้านล่างสุด
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text(
                  "คัดลอก Prompt แล้วไปเปิด Meta AI",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _copyPrompt,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
