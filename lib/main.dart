import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: KubdeeStudioApp(),
  ));
}

// โมเดลข้อมูลสินค้าแต่ละรายการ
class ProductItem {
  final String id;
  String name;
  String sellingPoints;
  String price;
  String? imagePath;
  bool isSelected;

  // การตั้งค่าวิดีโอประจำสินค้านั้นๆ
  String videoStyle; // 'UGC' หรือ 'POV'
  int duration; // 10, 20, 30
  String dialect; // กลาง, เหนือ, อีสาน, ใต้
  String scene;

  ProductItem({
    required this.id,
    required this.name,
    required this.sellingPoints,
    required this.price,
    this.imagePath,
    this.isSelected = true,
    this.videoStyle = "UGC",
    this.duration = 20,
    this.dialect = "กลาง",
    this.scene = "ในห้องนั่งเล่น",
  });
}

class KubdeeStudioApp extends StatefulWidget {
  const KubdeeStudioApp({super.key});

  @override
  State<KubdeeStudioApp> createState() => _KubdeeStudioAppState();
}

class _KubdeeStudioAppState extends State<KubdeeStudioApp> {
  final ImagePicker _picker = ImagePicker();

  // แพลตฟอร์มเป้าหมาย
  int _selectedPlatform = 0;
  final List<String> _platforms = ["TikTok", "Shopee", "Lazada", "Facebook", "IG"];

  // รายการสินค้าในคลัง (มีตัวอย่างตั้งต้นให้ทดสอบทันที)
  final List<ProductItem> _products = [
    ProductItem(
      id: "PROD-001",
      name: "กล้องวงจรปิด CCTV ไร้สาย โซลาร์เซลล์ 3 เลนส์ สีดำ",
      sellingPoints: "คมชัด 4K กันน้ำ กันฝน แบตอึด โซลาร์เซลล์ชาร์จไฟตลอดวัน",
      price: "899",
      isSelected: true,
      videoStyle: "UGC",
      duration: 20,
      dialect: "กลาง",
      scene: "ในห้องนั่งเล่น",
    ),
    ProductItem(
      id: "PROD-002",
      name: "กางเกงบูทกันน้ำ ลุยโคลน ทำการเกษตร พื้นยางหนาพิเศษ",
      sellingPoints: "ยางเหนียวทนทาน ไม่รั่วซึม ลุยโคลน ลุยน้ำขัง สวมใส่สบาย",
      price: "350",
      isSelected: true,
      videoStyle: "POV",
      duration: 10,
      dialect: "อีสาน",
      scene: "โรงงาน / หน้าร้าน",
    ),
    ProductItem(
      id: "PROD-003",
      name: "หมวกแก๊ป Unisex ผ้ายีนส์ฟอก ทรงสวย ระบายอากาศดี",
      sellingPoints: "ดีไซน์มินิมอล ใส่ได้ทั้งชายหญิง แมตช์ง่ายทุกชุด",
      price: "189",
      isSelected: false,
      videoStyle: "UGC",
      duration: 20,
      dialect: "กลาง",
      scene: "คาเฟ่โมเดิร์น",
    ),
  ];

  Future<void> _openMetaAI() async {
    final Uri url = Uri.parse('https://www.meta.ai');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  // สร้าง Prompt ตามข้อมูลของสินค้าแต่ละชิ้น
  String _buildPromptFor(ProductItem p) {
    String speech = "";
    if (p.dialect == "อีสาน") {
      speech = "พี่น้องเอ้ย ตัวนี้เด็ดอีหลี ${p.name} ราคาเพียง ${p.price} บาท ${p.sellingPoints} กดในตะกร้าด้านล่างได้เลยเด้อ!";
    } else if (p.dialect == "เหนือ") {
      speech = "ทุกคนเจ้า ตัวนี้ดีแต้ๆ ${p.name} แค่ ${p.price} บาทแต๊ๆ ${p.sellingPoints} ไผสนใจรีบกดในตะกร้าด้านล่างเลยเจ้า!";
    } else if (p.dialect == "ใต้") {
      speech = "เหวอเพื่อนเหอ ตัวนี้หรอยแรง ${p.name} ${p.price} บาทเท่านั้น ${p.sellingPoints} รีบกดในตะกร้าด้านล่างด่วนเลย!";
    } else {
      speech = "ทุกคน ใครกำลังหา ${p.name} ในราคา ${p.price} บาท ฟังทางนี้เลยครับ ${p.sellingPoints} รีบกดสั่งในตะกร้าสีเหลืองซ้ายมือด่วนเลยครับ!";
    }

    if (p.videoStyle == "POV") {
      return "Vertical 9:16 commercial POV showcase. Close-up first-person view showing hands inspecting and rotating: ${p.name}. Features: ${p.sellingPoints}. Setting: ${p.scene}. Thai voiceover (${p.dialect} dialect): '$speech'. 4k photorealistic.";
    } else {
      return "Vertical 9:16 realistic UGC commercial review. Featuring a Thai creator in ${p.scene} naturally holding and demonstrating: ${p.name}. Duration: ${p.duration}s. Action: Smiles, points down to bottom-left shopping cart. Thai lip-sync (${p.dialect} dialect): '$speech'. True commercial studio quality.";
    }
  }

  // เพิ่มสินค้าใหม่เข้าคลัง
  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final pointCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? pickedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📦 เพิ่มสินค้าเข้าคลังใหม่", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        setModalState(() => pickedImagePath = img.path);
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: pickedImagePath == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 24, color: Colors.indigo),
                                SizedBox(height: 4),
                                Text("ใส่รูปสินค้า", style: TextStyle(fontSize: 10, color: Colors.indigo)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(File(pickedImagePath!), fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: "ชื่อสินค้า", isDense: true, border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "ราคา (บาท)", isDense: true, border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pointCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "จุดเด่น / จุดขาย", isDense: true, border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _products.add(ProductItem(
                          id: "PROD-00${_products.length + 1}",
                          name: nameCtrl.text.trim(),
                          sellingPoints: pointCtrl.text.trim(),
                          price: priceCtrl.text.trim().isEmpty ? "0" : priceCtrl.text.trim(),
                          imagePath: pickedImagePath,
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("บันทึกลงคลังสินค้า", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // หน้าต่างปรับการตั้งค่าสไตล์คลิปรายสินค้า (พร้อมปุ่ม 'ใช้กับทุกสินค้า')
  void _showSettingsSheet(ProductItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text("⚙️ ตั้งค่าคลิป: ${item.name}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 6),
              // สไตล์คลิป
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("UGC มีคนพูด")),
                      selected: item.videoStyle == "UGC",
                      onSelected: (val) => setSheetState(() => item.videoStyle = "UGC"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("POV มือถือโชว์")),
                      selected: item.videoStyle == "POV",
                      onSelected: (val) => setSheetState(() => item.videoStyle = "POV"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ความยาวคลิป
              const Text("ความยาววิดีโอ:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: [10, 20, 30].map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text("$s วิ"),
                    selected: item.duration == s,
                    onSelected: (val) => setSheetState(() => item.duration = s),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              // สำเนียง
              const Text("ภาษาสำเนียงพูด:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ["กลาง", "อีสาน", "เหนือ", "ใต้"].map((d) => ChoiceChip(
                  label: Text("ภาษา$d"),
                  selected: item.dialect == d,
                  onSelected: (val) => setSheetState(() => item.dialect = d),
                )).toList(),
              ),
              const SizedBox(height: 20),
              // ปุ่มกดใช้งาน
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // ใช้การตั้งค่านี้กับสินค้าทุกตัวในคลัง
                        setState(() {
                          for (var p in _products) {
                            p.videoStyle = item.videoStyle;
                            p.duration = item.duration;
                            p.dialect = item.dialect;
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✨ ใช้การตั้งค่านี้กับสินค้าทุกตัวเรียบร้อย!")),
                        );
                      },
                      child: const Text("ใช้กับทุกสินค้า", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text("บันทึก"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // หน้าจอแสดงคิว Prompt พร้อมส่งไป Meta AI
  void _startBatchQueue() {
    final selectedItems = _products.where((p) => p.isSelected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาติ๊กเลือกสินค้าอย่างน้อย 1 รายการก่อนครับ")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("🚀 คิวสร้างวิดีโอ (${selectedItems.length} รายการ)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text("เปิด Meta AI"),
                  onPressed: _openMetaAI,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text("แตะปุ่มคัดลอกในแต่ละสินค้า แล้วนำไปวางส่งพร้อมแนบรูปใน Meta AI ได้ทันที:",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: selectedItems.length,
                itemBuilder: (context, idx) {
                  final p = selectedItems[idx];
                  final prompt = _buildPromptFor(p);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFF4F46E5),
                                child: Text("${idx + 1}", style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Color(0xFF4F46E5), size: 20),
                                tooltip: "คัดลอก Prompt",
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: prompt));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("คัดลอก Prompt #${idx + 1} เรียบร้อย!")),
                                  );
                                },
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                            child: Text(prompt, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _products.where((p) => p.isSelected).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Kubdee Studio AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Color(0xFF4F46E5)),
            tooltip: "เปิด Meta AI",
            onPressed: _openMetaAI,
          ),
        ],
      ),
      body: Column(
        children: [
          // แถบไอคอน Social Platforms แบบในคลิป
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: List.generate(_platforms.length, (i) {
                  final isSel = _selectedPlatform == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_platforms[i]),
                      selected: isSel,
                      selectedColor: const Color(0xFFEEF2FF),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSel ? const Color(0xFF4F46E5) : Colors.black87,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) => setState(() => _selectedPlatform = i),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),

          // แถบควบคุมคลังสินค้า
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("📦 ข้อมูลสินค้า (${_products.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        final allSelected = _products.every((p) => p.isSelected);
                        setState(() {
                          for (var p in _products) {
                            p.isSelected = !allSelected;
                          }
                        });
                      },
                      child: Text(_products.every((p) => p.isSelected) ? "ยกเลิกเลือก" : "เลือกทั้งหมด",
                          style: const TextStyle(fontSize: 12)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("เพิ่มสินค้า", style: TextStyle(fontSize: 12)),
                      onPressed: _showAddProductDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // รายการการ์ดสินค้าในคลัง
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _products.length,
              itemBuilder: (context, idx) {
                final item = _products[idx];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: item.isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: item.isSelected ? 1.5 : 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: item.isSelected,
                          activeColor: const Color(0xFF4F46E5),
                          onChanged: (val) => setState(() => item.isSelected = val ?? false),
                        ),
                        // รูปสินค้า
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: item.imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
                                )
                              : const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 26),
                        ),
                        const SizedBox(width: 10),
                        // รายละเอียด
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                    child: Text("#${idx + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("฿${item.price} • ${item.videoStyle} • ${item.duration}วิ • ภาษา${item.dialect}",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _showSettingsSheet(item),
                                child: const Row(
                                  children: [
                                    Icon(Icons.tune, size: 14, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 4),
                                    Text("ตั้งค่าสไตล์คลิปตัวนี้",
                                        style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                          onPressed: () => setState(() => _products.removeAt(idx)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ปุ่มสร้างคิวแบบในคลิป Kubdee AI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text("เริ่มต้นสร้างวิดีโอ Meta AI ($selectedCount รายการ)",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: _startBatchQueue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
