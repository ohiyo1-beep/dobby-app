import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DobbyStudioApp(),
  ));
}

class ProductItem {
  final String id;
  String name;
  String sellingPoints;
  String price;
  bool isSelected;

  String videoStyle;
  int duration;
  String dialect;
  String presenter;
  String scene;

  ProductItem({
    required this.id,
    required this.name,
    required this.sellingPoints,
    required this.price,
    this.isSelected = true,
    this.videoStyle = "UGC",
    this.duration = 20,
    this.dialect = "กลาง",
    this.presenter = "นางแบบ (ลุคสดใส)",
    this.scene = "สตูดิโอมินิมอล",
  });
}

class DobbyStudioApp extends StatefulWidget {
  const DobbyStudioApp({super.key});

  @override
  State<DobbyStudioApp> createState() => _DobbyStudioAppState();
}

class _DobbyStudioAppState extends State<DobbyStudioApp> {
  int _selectedPlatform = 0;
  final List<String> _platforms = ["TikTok", "Shopee", "Lazada", "Facebook", "IG"];

  final List<ProductItem> _products = [
    ProductItem(
      id: "PROD-001",
      name: "ผ้าไมโครไฟเบอร์ 3D เกรดพรีเมี่ยม หนานุ่ม ซับน้ำไว สีเหลืองเทา 30x30",
      sellingPoints: "ซับน้ำดีเยี่ยม แห้งไว ไม่อับชื้น เช็ดสะอาดไม่ทิ้งรอย ขนนุ่มถนอมผิวรถ ไม่เป็นขุย",
      price: "6",
      isSelected: true,
      videoStyle: "UGC",
      duration: 20,
      dialect: "กลาง",
      presenter: "นางแบบ (ลุคสดใส)",
      scene: "สตูดิโอมินิมอล",
    ),
    ProductItem(
      id: "PROD-002",
      name: "ปั๊มน้ำออโต้ TOMA JAPAN 750W แรงดันคงที่",
      sellingPoints: "มอเตอร์ทองแดงแท้ ทนทาน ปลอดภัย เสียงเงียบ เหมาะกับบ้าน 2-3 ชั้น",
      price: "1290",
      isSelected: true,
      videoStyle: "POV",
      duration: 20,
      dialect: "กลาง",
      presenter: "นายแบบ (ลุคสมาร์ท)",
      scene: "โรงงาน / หน้าร้าน",
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

  String _buildPromptFor(ProductItem p) {
    String speech = "";
    if (p.dialect == "อีสาน") {
      speech = "พี่น้องเอ้ย ตัวนี้เด็ดอีหลี ${p.name} ราคาเพียง ${p.price} บาท ${p.sellingPoints} กดสั่งซื้อในตะกร้าด้านล่างได้เลยเด้อ!";
    } else if (p.dialect == "เหนือ") {
      speech = "ทุกคนเจ้า ตัวนี้ดีแต้ๆ ${p.name} แค่ ${p.price} บาทแต๊ๆ ${p.sellingPoints} ไผสนใจรีบกดในตะกร้าด้านล่างเลยเจ้า!";
    } else if (p.dialect == "ใต้") {
      speech = "เหวอเพื่อนเหอ ตัวนี้หรอยแรง ${p.name} ${p.price} บาทเท่านั้น ${p.sellingPoints} รีบกดในตะกร้าด้านล่างด่วนเลย!";
    } else {
      speech = "ทุกคน ใครกำลังมองหา ${p.name} ราคาแค่ ${p.price} บาท ฟังทางนี้เลยครับ ${p.sellingPoints} รีบกดสั่งในตะกร้าสีเหลืองซ้ายมือด่วนเลยครับ!";
    }

    if (p.videoStyle == "POV") {
      return "Vertical 9:16 high-definition commercial POV showcase. "
          "First-person perspective showing two hands holding, rotating, and testing the exact product from attached image: ${p.name}. "
          "Demonstrating features: ${p.sellingPoints}. Setting: ${p.scene}. "
          "Spoken dialogue in Thai (${p.dialect} dialect): '$speech'. 4k photorealistic.";
    } else {
      return "Vertical 9:16 realistic commercial review. "
          "Featuring Thai presenter (${p.presenter}) enthusiastically holding and demonstrating the exact product from attached image: ${p.name}. "
          "Duration: ${p.duration}s. Action: Smiles, showcasing texture (${p.sellingPoints}), points to bottom-left cart. "
          "Spoken dialogue lip-synced in Thai (${p.dialect} dialect): '$speech'. 4K studio quality.";
    }
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController(text: "ผ้าไมโครไฟเบอร์ 3D เกรดพรีเมี่ยม ซับน้ำไว 30x30");
    final pointCtrl = TextEditingController(text: "ซับน้ำดีเยี่ยม แห้งไว เช็ดสะอาดไม่ทิ้งรอย ขนนุ่มถนอมผิวรถ ไม่เป็นขุย");
    final priceCtrl = TextEditingController(text: "6");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("📦 เพิ่มสินค้าเข้าคลัง (Dobby Studio)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6366F1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.photo_library_outlined, color: Color(0xFF4F46E5), size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "รูปสินค้าที่แคปไว้จาก Shopee/TikTok สามารถเปิดแชต Meta AI แล้วกดแนบรูปส่งคู่กับ Prompt ได้ทันที",
                        style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "ชื่อสินค้า", isDense: true, border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "ราคา (บาท)", isDense: true, border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pointCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "จุดเด่น / จุดขายสำคัญ", isDense: true, border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _products.add(ProductItem(
                          id: "PROD-00${_products.length + 1}",
                          name: nameCtrl.text.trim(),
                          sellingPoints: pointCtrl.text.trim(),
                          price: priceCtrl.text.trim().isEmpty ? "0" : priceCtrl.text.trim(),
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
                    child: Text("⚙️ ตั้งค่า: ${item.name}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("UGC คนรีวิว")),
                      selected: item.videoStyle == "UGC",
                      onSelected: (val) => setSheetState(() => item.videoStyle = "UGC"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("POV โชว์สินค้า")),
                      selected: item.videoStyle == "POV",
                      onSelected: (val) => setSheetState(() => item.videoStyle = "POV"),
                    ),
                  ),
                ],
              ),
              if (item.videoStyle == "UGC") ...[
                const SizedBox(height: 10),
                const Text("เลือกคนรีวิว (Presenter):", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ["นางแบบ (ลุคสดใส)", "นางแบบ (ลุคทางการ)", "นายแบบ (ลุคสมาร์ท)", "นายแบบ (ลุคเป็นกันเอง)"].map((g) => ChoiceChip(
                    label: Text(g),
                    selected: item.presenter == g,
                    onSelected: (val) => setSheetState(() => item.presenter = g),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          for (var p in _products) {
                            p.videoStyle = item.videoStyle;
                            p.duration = item.duration;
                            p.dialect = item.dialect;
                            p.presenter = item.presenter;
                          }
                        });
                        Navigator.pop(ctx);
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

  void _startBatchQueue() {
    final selectedItems = _products.where((p) => p.isSelected).toList();
    if (selectedItems.isEmpty) return;

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
                Text("🚀 คิวสร้างคลิป Meta AI (${selectedItems.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text("เปิด Meta AI"),
                  onPressed: _openMetaAI,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text("คัดลอก Prompt $\rightarrow$ เปิด Meta AI $\rightarrow$ แนบรูปสินค้าแล้ววางสร้างคลิปได้ทันที",
                style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                              Expanded(
                                child: Text(p.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.copy, size: 14),
                                label: const Text("คัดลอก", style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: prompt));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("คัดลอก Prompt #${idx + 1} เรียบร้อย!")),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
        title: const Text("Dobby Studio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("📦 ข้อมูลสินค้า (${_products.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                      child: Text(_products.every((p) => p.isSelected) ? "ยกเลิกเลือก" : "เลือกทั้งหมด", style: const TextStyle(fontSize: 12)),
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
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5), size: 26),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text("฿${item.price} • ${item.videoStyle} • ${item.presenter} • ${item.duration}วิ • ${item.dialect}",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _showSettingsSheet(item),
                                child: const Row(
                                  children: [
                                    Icon(Icons.tune, size: 14, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 4),
                                    Text("เปลี่ยนนายแบบ/นางแบบ & สไตล์", style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
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
                label: Text("เริ่มต้นสร้างคลิป Meta AI ($selectedCount รายการ)",
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
