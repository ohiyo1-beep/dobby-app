import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DobbyStudioApp(),
  ));
}

// -------------------------------------------------------------
// 1. DATA MODELS
// -------------------------------------------------------------

enum AiEngine { metaAi, flowAi }

class GlobalConfig {
  int defaultDuration;
  String delayRange;
  bool enableAiCaption;
  bool enableAiHashtags;
  bool enableAiCta;
  bool enableRewriteOnError;
  bool autoNextProject;

  GlobalConfig({
    this.defaultDuration = 20,
    this.delayRange = "ปกติ (5-10 วินาที)",
    this.enableAiCaption = false,
    this.enableAiHashtags = false,
    this.enableAiCta = false,
    this.enableRewriteOnError = true,
    this.autoNextProject = false,
  });
}

class ProductItem {
  final String id;
  final String sku;
  String name;
  String price;
  String sellingPoints;
  String? imagePath;
  bool isSelected;

  // Video Config
  String videoStyle; // 'UGC' หรือ 'POV'
  int duration; // 10, 20, 30
  bool enableAiVoice;
  String voiceSource;
  String voiceModel;
  String tone;
  String ageGroup;
  String dialect;
  String presenter;
  String scene;
  String customPrompt;

  ProductItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.sellingPoints,
    this.imagePath,
    this.isSelected = true,
    this.videoStyle = "UGC",
    this.duration = 20,
    this.enableAiVoice = true,
    this.voiceSource = "ระบบ",
    this.voiceModel = "Despina (เริ่มต้น)",
    this.tone = "เป็นกันเอง",
    this.ageGroup = "วัยรุ่น",
    this.dialect = "กลาง",
    this.presenter = "นางแบบ (ลุคสดใส)",
    this.scene = "สตูดิโอขาว",
    this.customPrompt = "Review [product] with [product_image] again [character_image_1]",
  });

  void applySettingsFrom(ProductItem source) {
    videoStyle = source.videoStyle;
    duration = source.duration;
    enableAiVoice = source.enableAiVoice;
    voiceSource = source.voiceSource;
    voiceModel = source.voiceModel;
    tone = source.tone;
    ageGroup = source.ageGroup;
    dialect = source.dialect;
    presenter = source.presenter;
    scene = source.scene;
    customPrompt = source.customPrompt;
  }
}

// -------------------------------------------------------------
// 2. MAIN APP
// -------------------------------------------------------------

class DobbyStudioApp extends StatefulWidget {
  const DobbyStudioApp({super.key});

  @override
  State<DobbyStudioApp> createState() => _DobbyStudioAppState();
}

class _DobbyStudioAppState extends State<DobbyStudioApp> {
  AiEngine _selectedEngine = AiEngine.metaAi;
  int _selectedPlatform = 0;
  final List<String> _platforms = ["TikTok", "Shopee", "Lazada", "Facebook", "IG"];

  final GlobalConfig _globalConfig = GlobalConfig();
  final ImagePicker _picker = ImagePicker();

  final List<ProductItem> _products = [
    ProductItem(
      id: "PROD-001",
      sku: "173233520379980503",
      name: "หมวกแก๊ป Unisex มีให้เลือก 3 สี M10Z221",
      price: "350",
      sellingPoints: "ผ้าคอตตอนแท้ ระบายอากาศดี ทรงสวย ปรับสายได้",
      isSelected: true,
      videoStyle: "UGC",
      duration: 20,
    ),
    ProductItem(
      id: "PROD-002",
      sku: "173073496281046743",
      name: "กระเป๋าสะพายอเนกประสงค์ มีให้เลือก 2 สี",
      price: "690",
      sellingPoints: "จุของได้เยอะ กันน้ำ พกพาสะดวก ช่องซิปหลายชั้น",
      isSelected: true,
      videoStyle: "POV",
      duration: 20,
      scene: "คาเฟ่",
    ),
  ];

  String _buildResolvedPrompt(ProductItem p) {
    String speech = "";
    if (p.dialect == "อีสาน") {
      speech = "พี่น้องเอ้ย ตัวนี้เด็ดอีหลี ${p.name} ราคาเพียง ${p.price} บาท ${p.sellingPoints} กดสั่งซื้อในตะกร้าด้านล่างได้เลยเด้อ!";
    } else if (p.dialect == "เหนือ") {
      speech = "ทุกคนเจ้า ตัวนี้ดีแต้ๆ ${p.name} แค่ ${p.price} บาทแต๊ๆ ${p.sellingPoints} ไผสนใจรีบกดในตะกร้าด้านล่างเลยเจ้า!";
    } else if (p.dialect == "ใต้") {
      speech = "เหวอเพื่อนเหอ ตัวนี้หรอยแรง ${p.name} ${p.price} บาทเท่านั้น ${p.sellingPoints} รีบกดในตะกร้าด้านล่างด่วนเลย!";
    } else {
      speech = "ทุกคน ใครกำลังมองหา ${p.name} ราคาแค่ ${p.price} บาท แนะนำเลยครับ ${p.sellingPoints} รีบกดสั่งในตะกร้าด้านล่างด่วนเลยครับ!";
    }

    if (_selectedEngine == AiEngine.flowAi) {
      return "Google Flow Cinematic Commercial 9:16 vertical video. "
          "Subject: ${p.videoStyle == 'POV' ? 'First-person hands showing and rotating' : p.presenter}. "
          "Featuring product: ${p.name}. Action: Showcase features (${p.sellingPoints}) in high dynamic range. "
          "Environment: ${p.scene}. High photorealism, stable lighting, fluent gesture. "
          "Audio track in Thai (${p.dialect}): '$speech'.";
    }

    if (p.videoStyle == "POV") {
      return "Vertical 9:16 high-definition commercial POV showcase. "
          "First-person perspective showing two hands holding, rotating, and testing the exact product from attached image: ${p.name}. "
          "Demonstrating features: ${p.sellingPoints}. Setting: ${p.scene}. "
          "Spoken dialogue in Thai (${p.dialect} dialect, tone: ${p.tone}): '$speech'. 4K photorealistic.";
    } else {
      return "Vertical 9:16 realistic commercial review. "
          "Featuring Thai presenter (${p.presenter}) enthusiastically holding and demonstrating the exact product from attached image: ${p.name}. "
          "Duration: ${p.duration}s. Scene: ${p.scene}. Action: Smiles, showcasing texture (${p.sellingPoints}), points to cart. "
          "Spoken dialogue lip-synced in Thai (${p.dialect} dialect, tone: ${p.tone}): '$speech'. 4K studio quality.";
    }
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController(text: "SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}");
    final pointCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? pickedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
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
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        pickedImagePath = image.path;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1)),
                    ),
                    child: pickedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(File(pickedImagePath!), fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Color(0xFF4F46E5), size: 32),
                              SizedBox(height: 6),
                              Text("แตะเพื่อเลือกรูปภาพสินค้าจากเครื่อง",
                                  style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "ชื่อสินค้า", border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skuCtrl,
                        decoration: const InputDecoration(labelText: "รหัส SKU", border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "ราคา (บาท)", border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pointCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "จุดเด่น / จุดขายสำคัญ", border: OutlineInputBorder(), isDense: true),
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
                            sku: skuCtrl.text.trim(),
                            name: nameCtrl.text.trim(),
                            sellingPoints: pointCtrl.text.trim(),
                            price: priceCtrl.text.trim().isEmpty ? "0" : priceCtrl.text.trim(),
                            imagePath: pickedImagePath,
                            duration: _globalConfig.defaultDuration,
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
      ),
    );
  }

  void _showProductSettingsSheet(ProductItem item) {
    final promptCtrl = TextEditingController(text: item.customPrompt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "⚙️ ตั้งค่า: ${item.name}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: item.imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEEF2FF),
                              foregroundColor: const Color(0xFF4F46E5),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text("เปลี่ยนรูปสินค้า", style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                              if (img != null) {
                                setSheetState(() => item.imagePath = img.path);
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: item.videoStyle == "UGC" ? const Color(0xFFEEF2FF) : Colors.white,
                                side: BorderSide(
                                  color: item.videoStyle == "UGC" ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(Icons.record_voice_over, color: item.videoStyle == "UGC" ? const Color(0xFF4F46E5) : Colors.grey),
                              label: Text("UGC รีวิว", style: TextStyle(color: item.videoStyle == "UGC" ? const Color(0xFF4F46E5) : Colors.black87, fontWeight: FontWeight.bold)),
                              onPressed: () => setSheetState(() => item.videoStyle = "UGC"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: item.videoStyle == "POV" ? const Color(0xFFEEF2FF) : Colors.white,
                                side: BorderSide(
                                  color: item.videoStyle == "POV" ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(Icons.pan_tool_outlined, color: item.videoStyle == "POV" ? const Color(0xFF4F46E5) : Colors.grey),
                              label: Text("POV", style: TextStyle(color: item.videoStyle == "POV" ? const Color(0xFF4F46E5) : Colors.black87, fontWeight: FontWeight.bold)),
                              onPressed: () => setSheetState(() => item.videoStyle = "POV"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Prompt Template", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: TextField(
                          controller: promptCtrl,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          decoration: const InputDecoration.collapsed(hintText: "พิมพ์ Prompt..."),
                          onChanged: (val) => item.customPrompt = val,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ["[สินค้า]", "[รูปสินค้า]", "[รูปตัวละคร]", "[ฉาก]", "[ตัวอย่าง]"].map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                              backgroundColor: const Color(0xFFFEF3C7),
                              onPressed: () {
                                setSheetState(() {
                                  promptCtrl.text = "${promptCtrl.text} $tag";
                                  item.customPrompt = promptCtrl.text;
                                });
                              },
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("ความยาววิดีโอ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Row(
                            children: [10, 20, 30].map((s) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text("$s"),
                                selected: item.duration == s,
                                onSelected: (val) => setSheetState(() => item.duration = s),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("เสียงพากย์ AI", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Switch(
                            value: item.enableAiVoice,
                            activeColor: const Color(0xFF4F46E5),
                            onChanged: (val) => setSheetState(() => item.enableAiVoice = val),
                          ),
                        ],
                      ),
                      if (item.enableAiVoice) ...[
                        DropdownButtonFormField<String>(
                          value: item.voiceModel,
                          decoration: const InputDecoration(isDense: true, labelText: "โมเดลเสียง AI", border: OutlineInputBorder()),
                          items: ["Despina (เริ่มต้น)", "Erinome", "Puck", "Charon", "Ferrir", "Orus"]
                              .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) => setSheetState(() => item.voiceModel = val ?? item.voiceModel),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: ["เป็นกันเอง", "สุภาพ", "สนุกสนาน"].map((t) => ChoiceChip(
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            selected: item.tone == t,
                            onSelected: (val) => setSheetState(() => item.tone = t),
                          )).toList(),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: ["กลาง", "เหนือ", "อีสาน", "ใต้"].map((d) => ChoiceChip(
                            label: Text("ภาษา$d", style: const TextStyle(fontSize: 11)),
                            selected: item.dialect == d,
                            onSelected: (val) => setSheetState(() => item.dialect = d),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text("ฉากหลัง (Scene)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ["สตูดิโอขาว", "โต๊ะไม้", "คาเฟ่", "ห้องนอน", "สวนธรรมชาติ", "หน้าร้าน"].map((sc) => ChoiceChip(
                          label: Text(sc, style: const TextStyle(fontSize: 11)),
                          selected: item.scene == sc,
                          onSelected: (val) => setSheetState(() => item.scene = sc),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        setState(() {
                          for (var p in _products) {
                            p.applySettingsFrom(item);
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ นำการตั้งค่านี้ไปใช้กับทุกสินค้าเรียบร้อยแล้ว")),
                        );
                      },
                      child: const Text("ใช้กับทุกสินค้า", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text("เสร็จสิ้น", style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _launchAutomationScreen() {
    final selectedItems = _products.where((p) => p.isSelected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณาเลือกสินค้าอย่างน้อย 1 รายการ")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => InAppAutomationView(
          engine: _selectedEngine,
          items: selectedItems,
          globalConfig: _globalConfig,
          buildPromptCallback: _buildResolvedPrompt,
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
        title: const Text("Kubdee AI (Dobby Studio)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          GestureDetector(
            onTap: () => setState(() => _selectedEngine = AiEngine.metaAi),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedEngine == AiEngine.metaAi ? const Color(0xFFEEF2FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedEngine == AiEngine.metaAi ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.hub_outlined, size: 16, color: _selectedEngine == AiEngine.metaAi ? const Color(0xFF4F46E5) : Colors.grey),
                  const SizedBox(width: 4),
                  Text("Meta", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedEngine == AiEngine.metaAi ? const Color(0xFF4F46E5) : Colors.grey)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedEngine = AiEngine.flowAi),
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedEngine == AiEngine.flowAi ? const Color(0xFFFFF7ED) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedEngine == AiEngine.flowAi ? Colors.orange.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "F",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _selectedEngine == AiEngine.flowAi ? Colors.orange.shade800 : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text("Flow", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedEngine == AiEngine.flowAi ? Colors.orange.shade800 : Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, size: 18, color: _selectedEngine == AiEngine.metaAi ? const Color(0xFF4F46E5) : Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text("ตั้งค่าพื้นฐาน (${_selectedEngine == AiEngine.metaAi ? 'Meta AI' : 'Google Flow'})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _globalConfig.defaultDuration,
                          decoration: const InputDecoration(labelText: "ความยาวรวม", isDense: true, border: OutlineInputBorder()),
                          items: [10, 20, 30].map((d) => DropdownMenuItem(value: d, child: Text("$d วินาที", style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => setState(() => _globalConfig.defaultDuration = val ?? 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _globalConfig.delayRange,
                          decoration: const InputDecoration(labelText: "หน่วงเวลา", isDense: true, border: OutlineInputBorder()),
                          items: ["ปกติ (5-10 วินาที)", "ช้า (10-20 วินาที)", "เร็ว (2-5 วินาที)"]
                              .map((dr) => DropdownMenuItem(value: dr, child: Text(dr, style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (val) => setState(() => _globalConfig.delayRange = val ?? _globalConfig.delayRange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("AI ช่วย Caption", style: TextStyle(fontSize: 13)),
                    value: _globalConfig.enableAiCaption,
                    onChanged: (v) => setState(() => _globalConfig.enableAiCaption = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("AI rewrite prompt เมื่อเกิด error", style: TextStyle(fontSize: 13)),
                    value: _globalConfig.enableRewriteOnError,
                    onChanged: (v) => setState(() => _globalConfig.enableRewriteOnError = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("📦 ข้อมูลสินค้า (${_products.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              itemCount: _products.length,
              itemBuilder: (context, idx) {
                final item = _products[idx];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: item.isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
                      width: item.isSelected ? 1.5 : 1,
                    ),
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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
                                )
                              : const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5), size: 28),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("# ${item.sku}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text("฿${item.price} • ${item.videoStyle} • ${item.duration}วิ • ${item.dialect}",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _showProductSettingsSheet(item),
                                child: const Row(
                                  children: [
                                    Icon(Icons.tune, size: 14, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 4),
                                    Text("ตั้งค่าสไตล์, เสียง และฉาก", style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
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
              backgroundColor: _selectedEngine == AiEngine.metaAi ? const Color(0xFF4F46E5) : Colors.orange.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              "เริ่มรันบอทสร้างด้วย ${_selectedEngine == AiEngine.metaAi ? 'Meta AI' : 'Flow AI'} ($selectedCount)",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: _launchAutomationScreen,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. IN-APP AUTOMATION SCREEN (พร้อม Advanced JS Automation Engine)
// -------------------------------------------------------------

class InAppAutomationView extends StatefulWidget {
  final AiEngine engine;
  final List<ProductItem> items;
  final GlobalConfig globalConfig;
  final String Function(ProductItem) buildPromptCallback;

  const InAppAutomationView({
    super.key,
    required this.engine,
    required this.items,
    required this.globalConfig,
    required this.buildPromptCallback,
  });

  @override
  State<InAppAutomationView> createState() => _InAppAutomationViewState();
}

class _InAppAutomationViewState extends State<InAppAutomationView> {
  late final WebViewController _webViewController;
  int _currentIndex = 0;
  bool _isLoadingWeb = true;
  String _botStatus = "กำลังเชื่อมต่อระบบ...";

  @override
  void initState() {
    super.initState();
    final targetUrl = widget.engine == AiEngine.metaAi
        ? 'https://www.meta.ai'
        : 'https://labs.google/flow';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoadingWeb = true;
              _botStatus = "กำลังเปิดหน้าเว็บ $url...";
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoadingWeb = false;
              _botStatus = "หน้าเว็บพร้อมแล้ว - รอกดส่งคำสั่งเข้าบอท";
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  // -------------------------------------------------------------
  // ADVANCED JAVASCRIPT INJECTION (Auto-Type + Dispatch Event + Submit)
  // -------------------------------------------------------------
  Future<void> _injectPromptToChat({bool autoSubmit = true}) async {
    final currentItem = widget.items[_currentIndex];
    final promptText = widget.buildPromptCallback(currentItem);

    setState(() {
      _botStatus = "กำลังสั่งพิมพ์ข้อความลงช่องแชต...";
    });

    // สำรองข้อมูลลงคลิปบอร์ดไว้ก่อนเสมอ
    await Clipboard.setData(ClipboardData(text: promptText));

    final encodedText = jsonEncode(promptText);

    // สคริปต์ JavaScript จำลองการพิมพ์และจำลองการกดส่ง
    final jsScript = """
      (function() {
        var text = $encodedText;
        var autoSend = ${autoSubmit ? 'true' : 'false'};

        // 1. สแกนหาตัวรับข้อความ (Editor / Textarea / ContentEditable)
        var inputEl = document.querySelector('div[contenteditable="true"]') ||
                      document.querySelector('textarea[placeholder*="Ask"], textarea') ||
                      document.querySelector('input[type="text"]');

        if (!inputEl) {
          return "ERROR_INPUT_NOT_FOUND";
        }

        // โฟกัสไปที่กล่องข้อความ
        inputEl.focus();

        if (inputEl.isContentEditable) {
          // สำหรับ Rich Text Editor (Meta AI / Flow)
          inputEl.innerText = text;
          
          // ส่ง Events ให้ React / Slate State อัปเดต
          inputEl.dispatchEvent(new Event('input', { bubbles: true }));
          inputEl.dispatchEvent(new Event('change', { bubbles: true }));
        } else {
          // สำหรับ Textarea / Input ทั่วไป
          inputEl.value = text;
          inputEl.dispatchEvent(new Event('input', { bubbles: true }));
          inputEl.dispatchEvent(new Event('change', { bubbles: true }));
        }

        if (autoSend) {
          // 2. สแกนหาปุ่มส่ง (Submit/Send button)
          setTimeout(function() {
            var sendBtn = document.querySelector('button[aria-label*="Send"], button[aria-label*="ส่ง"]') ||
                          document.querySelector('button[type="submit"]') ||
                          document.querySelector('button svg path[d*="M2.01 21L23 12 2.01 3"]')?.closest('button');

            if (sendBtn && !sendBtn.disabled) {
              sendBtn.click();
            } else {
              // ถ้าหาปุ่มไม่เจอ ลองยิง Keyboard Event 'Enter'
              var enterEvent = new KeyboardEvent('keydown', {
                key: 'Enter',
                code: 'Enter',
                keyCode: 13,
                which: 13,
                bubbles: true,
                cancelable: true
              });
              inputEl.dispatchEvent(enterEvent);
            }
          }, 400);
        }

        return "SUCCESS";
      })();
    """;

    try {
      final result = await _webViewController.runJavaScriptReturningResult(jsScript);
      final resStr = result.toString();

      if (resStr.contains("SUCCESS")) {
        setState(() {
          _botStatus = autoSubmit
              ? "ส่ง Prompt สำเร็จ! (ส่งคำสั่งเข้าแชตเรียบร้อย)"
              : "พิมพ์ Prompt ลงช่องเรียบร้อยแล้ว";
        });
      } else {
        setState(() {
          _botStatus = "ไม่พบช่องพิมพ์ (คัดลอกลงคลิปบอร์ดแล้ว แตะวางด้วยตนเองได้)";
        });
      }
    } catch (e) {
      setState(() {
        _botStatus = "คัดลอกลงคลิปบอร์ดแล้ว พร้อมแตะวางในแชต";
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🚀 บอทจัดการ Prompt #${_currentIndex + 1} (${currentItem.name}) แล้ว"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _nextProduct() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() {
        _currentIndex++;
        _botStatus = "สลับไปยังสินค้าตัวถัดไป (${_currentIndex + 1}/${widget.items.length})";
      });
    } else {
      setState(() {
        _botStatus = "🎉 ทำงานครบคิวทั้งหมดแล้ว!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.engine == AiEngine.metaAi ? "Meta AI Automator" : "Google Flow Automator",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: currentItem.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(File(currentItem.imagePath!), fit: BoxFit.cover),
                            )
                          : const Icon(Icons.image, color: Colors.white54, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "คิว ${_currentIndex + 1}/${widget.items.length} : ${currentItem.name}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "หน่วงเวลา: ${widget.globalConfig.delayRange.split(' ')[0]}",
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _botStatus,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.auto_fix_high, size: 14),
                        label: const Text("พิมพ์ & สั่งส่งทันที", style: TextStyle(fontSize: 12)),
                        onPressed: () => _injectPromptToChat(autoSubmit: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      onPressed: _nextProduct,
                      child: const Text("ถัดไป >>", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoadingWeb)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
