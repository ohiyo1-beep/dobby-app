import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VideoStudioApp(),
  ));
}

class VideoStudioApp extends StatefulWidget {
  const VideoStudioApp({super.key});

  @override
  State<VideoStudioApp> createState() => _VideoStudioAppState();
}

class _VideoStudioAppState extends State<VideoStudioApp> {
  File? _productImage;
  File? _modelImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesCtrl = TextEditingController(text: "กล้องวงจรปิด CCTV ไร้สาย");

  String _modelType = "female"; // female, male
  String _productSize = "normal"; // normal, large
  String _background = "home"; // home, market, mall, factory
  String _duration = "10s"; // 10s, 20-30s

  late final WebViewController _webController;
  bool _isLoadingWeb = true;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              _isLoadingWeb = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.meta.ai'));
  }

  Future<void> _pickImage(bool isProduct) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isProduct) {
          _productImage = File(picked.path);
        } else {
          _modelImage = File(picked.path);
        }
      });
    }
  }

  // สร้าง Prompt สเต็ปที่ 1: เจนรูปภาพนิ่ง 9:16 ล็อกหน้าคน + หน้าสินค้า
  String _buildImagePrompt() {
    final pName = _notesCtrl.text.trim().isEmpty ? "product" : _notesCtrl.text.trim();
    final personDesc = _modelType == "female" ? "a beautiful young Thai female creator" : "a handsome young Thai male creator";
    
    String bgDesc = "";
    if (_background == "home") {
      bgDesc = "a cozy modern living room interior with warm natural lighting";
    } else if (_background == "market") {
      bgDesc = "a bustling outdoor night market with ambient warm neon lights";
    } else if (_background == "mall") {
      bgDesc = "a luxurious modern department store background";
    } else {
      bgDesc = "an authentic manufacturing factory setting";
    }

    String action = (_productSize == "normal")
        ? "securely holding and showcasing the $pName at chest level toward the camera"
        : "standing beside the large $pName, gently pointing at its key features and details";

    return "A hyper-realistic commercial portrait photography, vertical 9:16 aspect ratio (1080x1920). "
        "Featuring $personDesc (matching the facial identity of the reference person) $action. "
        "The product design, colors, and textures strictly and accurately replicate the reference product image. "
        "Background: $bgDesc. True-to-life scale, pristine product details, 50mm lens, 8k resolution, crisp photorealism.";
  }

  // สร้าง Prompt สเต็ปที่ 2: Animate รูปภาพนิ่งให้เป็นวิดีโอ 9:16 พร้อมเสียงพูด
  String _buildAnimatePrompt() {
    String dialogue = "";
    if (_duration == "10s") {
      dialogue = "ทุกคน ตัวนี้ตอบโจทย์มาก ฟังก์ชันครบ ใช้งานง่าย คุ้มค่าสุดๆ รีบกดสั่งในตะกร้าซ้ายมือก่อนของหมดนะครับ!";
    } else {
      dialogue = "เจอปัญหานี้อยู่ใช่ไหม? บอกเลยว่าตัวนี้ของจริง ดีไซน์สวย ใช้งานทนทาน คุ้มราคาแน่นอน กดสั่งในตะกร้าเหลืองด่วนเลยครับ!";
    }

    return "Animate this 9:16 vertical image into a smooth photorealistic video. "
        "Keep the exact same vertical 9:16 aspect ratio, preserve creator face and accurate product design. "
        "Action: The creator makes confident, friendly eye contact with camera, interacts naturally with the product, smiles, and points toward the bottom-left shopping basket. "
        "Dialogue: The creator naturally speaks with realistic Thai lip-sync: '$dialogue'. Natural realistic motion, cinematic lighting.";
  }

  void _injectToMetaAI(String prompt, String successMsg) {
    final safePrompt = prompt.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r'\n');

    final jsCode = """
      (function() {
        var input = document.querySelector('textarea, div[contenteditable="true"], input[type="text"]');
        if (input) {
          if (input.tagName.toLowerCase() === 'textarea' || input.tagName.toLowerCase() === 'input') {
            input.value = '$safePrompt';
            input.dispatchEvent(new Event('input', { bubbles: true }));
          } else {
            input.innerText = '$safePrompt';
            input.dispatchEvent(new Event('input', { bubbles: true }));
          }
          setTimeout(function() {
            var sendBtn = document.querySelector('button[aria-label*="Send"], button[aria-label*="ส่ง"], div[role="button"][aria-label*="Send"]');
            if (sendBtn) {
              sendBtn.click();
            } else {
              input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true }));
            }
          }, 400);
        }
      })();
    """;

    _webController.runJavaScript(jsCode);
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$successMsg (พร้อมคัดลอกลงคลิปบอร์ดแล้ว)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dobby Studio (Face & Product)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text("⚙️ กำหนดสินค้า & คนรีวิว (สเกล 9:16)", style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    // ส่วนอัปโหลด 2 รูปคู่กัน
                    Row(
                      children: [
                        // อัปโหลดรูปสินค้า
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(true),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue.shade300, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.shade50,
                              ),
                              child: _productImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 28),
                                        SizedBox(height: 4),
                                        Text("📦 1. รูปสินค้า", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                        Text("(แคปจาก Shopee)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.file(_productImage!, fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // อัปโหลดรูปนางแบบ/นายแบบ
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(false),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple.shade300, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.purple.shade50,
                              ),
                              child: _modelImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.person_outline, color: Colors.purple, size: 28),
                                        SizedBox(height: 4),
                                        Text("👤 2. นางแบบ/นายแบบ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                                        Text("(แนบรูปหน้าคน)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.file(_modelImage!, fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ช่องใส่ชื่อสินค้า
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: "ชื่อสินค้า / รายละเอียด",
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // เลือกเพศครีเอเตอร์ & ฉากหลัง
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _modelType,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "เพศครีเอเตอร์", contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                            items: const [
                              DropdownMenuItem(value: "female", child: Text("นางแบบ (หญิง)")),
                              DropdownMenuItem(value: "male", child: Text("นายแบบ (ชาย)")),
                            ],
                            onChanged: (val) => setState(() => _modelType = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _background,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ฉากหลัง", contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                            items: const [
                              DropdownMenuItem(value: "home", child: Text("ในห้อง/บ้าน")),
                              DropdownMenuItem(value: "market", child: Text("ตลาดนัด")),
                              DropdownMenuItem(value: "mall", child: Text("ห้างสรรพสินค้า")),
                              DropdownMenuItem(value: "factory", child: Text("โรงงาน")),
                            ],
                            onChanged: (val) => setState(() => _background = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ปุ่มกด 2 สเต็ป
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text("สเต็ป 1: เจนรูป 9:16", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _injectToMetaAI(_buildImagePrompt(), "📸 ส่งคำสั่งเจนรูปภาพ 9:16 เข้า Meta AI แล้ว"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.movie_creation_outlined, size: 18),
                            label: const Text("สเต็ป 2: เสกคลิป 9:16", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _injectToMetaAI(_buildAnimatePrompt(), "🎬 ส่งคำสั่ง Animate วิดีโอ 9:16 แล้ว"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // หน้าต่างเบราว์เซอร์ Meta AI ด้านล่าง
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webController),
                if (_isLoadingWeb)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
