import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
  final TextEditingController _notesCtrl =
      TextEditingController(text: "กล้องวงจรปิด CCTV ไร้สาย โซลาร์เซลล์ 3 เลนส์ สีดำ");

  String _modelType = "female"; // female, male
  String _productSize = "normal"; // normal, large
  String _background = "home"; // home, market, mall, factory
  String _duration = "20-30s"; // 10s, 20-30s
  String _tenSecFocus = "persuade"; // persuade, cta (สำหรับ 10 วิ)

  late final WebViewController _webController;
  bool _isLoadingWeb = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
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

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setOnShowFileSelector((FileSelectorParams fileParams) async {
        final XFile? file =
            await _picker.pickImage(source: ImageSource.gallery);
        if (file != null) {
          return [Uri.file(file.path).toString()];
        }
        return [];
      });
    }

    _webController = controller;
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

  // สร้าง Prompt สเต็ป 1: ภาพนิ่ง 9:16 ล็อกหน้าคน + หน้าสินค้า
  String _buildImagePrompt() {
    final pName = _notesCtrl.text.trim().isEmpty ? "product" : _notesCtrl.text.trim();
    final person = _modelType == "female" ? "a professional charming Thai female creator" : "a professional friendly Thai male creator";
    
    String bgDesc = "";
    if (_background == "home") {
      bgDesc = "a cozy modern living room interior with soft natural lighting";
    } else if (_background == "market") {
      bgDesc = "a vibrant outdoor night market with ambient warm lights";
    } else if (_background == "mall") {
      bgDesc = "a luxurious upscale shopping mall interior";
    } else {
      bgDesc = "an authentic manufacturing factory setting";
    }

    final action = (_productSize == "normal")
        ? "holding and showcasing the exact $pName at chest level toward the camera"
        : "standing beside the large $pName, naturally pointing at its key features";

    return "A hyper-realistic commercial portrait photography, vertical 9:16 aspect ratio (1080x1920). "
        "Featuring $person (matching identity and facial features of reference person) $action. "
        "The product design, colors, and textures must strictly replicate the reference product image. "
        "Background: $bgDesc. True-to-life scale, pristine product details, 50mm lens, 8k resolution, crisp photorealism.";
  }

  // สร้าง Prompt สเต็ป 2: เสกคลิป 9:16 รองรับทั้ง 10 วิ และ 20-30 วิ (Hook + โน้มน้าว + ปิดการขาย)
  String _buildAnimatePrompt() {
    final pName = _notesCtrl.text.trim().isEmpty ? "สินค้าตัวนี้" : _notesCtrl.text.trim();
    
    if (_duration == "10s") {
      String dialogue = "";
      String action = "";
      if (_tenSecFocus == "persuade") {
        dialogue = "ทุกคน $pName เด่นเรื่องความคุ้มค่า ใช้งานง่าย ฟังก์ชันครบ ตอบโจทย์ชีวิตประจำวันมากครับ!";
        action = (_productSize == "normal")
            ? "holding and rotating the product to show details"
            : "pointing closely at key features of the product";
      } else {
        dialogue = "โปรคุ้มมากรอบนี้ ใครมองหาอยู่รีบกดลงตะกร้าสีเหลืองซ้ายมือด่วนเลย ช้าหมดอดนะครับ!";
        action = "smiling warmly and pointing hand directly toward bottom-left corner";
      }

      return "Animate this 9:16 vertical image into a 10-second photorealistic review video. "
          "Maintain strict 9:16 vertical aspect ratio, creator identity, and precise product design. "
          "Action: Creator $action with eye contact. "
          "Dialogue: Character speaks naturally with accurate Thai lip-sync: '$dialogue'. 35mm lens.";
    } else {
      // โหมดเต็ม 20-30 วินาที: 3 ท่อนครบสูตร
      final hookLine = "ทุกคน ใครเจอปัญหานี้อยู่ ฟังทางนี้ด่วนเลยครับ!";
      final valueLine = "$pName ตัวนี้บอกเลยว่าตอบโจทย์มาก ดีไซน์สวย ใช้งานง่าย วัสดุทนทาน คุ้มราคาที่สุด!";
      final ctaLine = "ตอนนี้มีโปรลดพิเศษ รีบกดสั่งในตะกร้าสีเหลืองมุมซ้ายล่างก่อนของจะหมดนะครับ!";
      final fullDialogue = "$hookLine $valueLine $ctaLine";

      final actionSequence = (_productSize == "normal")
          ? "[Phase 1 - Hook]: eye contact with camera, introducing the product at chest level. "
            "[Phase 2 - Value]: turns and inspects product details and texture enthusiastically. "
            "[Phase 3 - CTA]: smiles broadly, looks at camera, and repeatedly points down toward bottom-left corner basket."
          : "[Phase 1 - Hook]: eye contact, welcoming viewers next to the large product. "
            "[Phase 2 - Value]: gently touches surface, pointing at build quality and durability. "
            "[Phase 3 - CTA]: smiles and gestures down clearly toward bottom-left corner basket.";

      return "Animate this 9:16 vertical image into a full 20-30 second seamless photorealistic UGC review video. "
          "Maintain strict vertical 9:16 aspect ratio, accurate product design, and creator face. "
          "Performance Timeline: $actionSequence "
          "Dialogue: Creator speaks fluently with precise Thai lip-sync: '$fullDialogue'. Natural body motion, cinematic lighting.";
    }
  }

  void _injectToMetaAI(String prompt, String label) {
    Clipboard.setData(ClipboardData(text: prompt));
    final safe = prompt.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r' ');

    final js = """
      (function() {
        var input = document.querySelector('textarea, div[contenteditable="true"], input[type="text"]');
        if (input) {
          if (input.tagName.toLowerCase() === 'textarea' || input.tagName.toLowerCase() === 'input') {
            input.value = '$safe';
            input.dispatchEvent(new Event('input', { bubbles: true }));
          } else {
            input.innerText = '$safe';
            input.dispatchEvent(new Event('input', { bubbles: true }));
          }
          setTimeout(function() {
            var btn = document.querySelector('button[aria-label*="Send"], button[aria-label*="ส่ง"], div[role="button"][aria-label*="Send"]');
            if (btn) btn.click();
          }, 300);
        }
      })();
    """;
    _webController.runJavaScript(js);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label (คัดลอกคำสั่งพร้อมส่งแล้ว)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dobby Studio (UGC Pro 9:16)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text("⚙️ กำหนดสินค้า & คนรีวิว (สเกล 9:16)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  children: [
                    // ส่วนอัปโหลด 2 รูป
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(true),
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.shade50,
                              ),
                              child: _productImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 24),
                                        Text("📦 รูปสินค้า", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.file(_productImage!, fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(false),
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.purple.shade50,
                              ),
                              child: _modelImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.person_outline, color: Colors.purple, size: 24),
                                        Text("👤 หน้านายแบบ/นางแบบ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
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
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: "ชื่อสินค้า / รายละเอียด",
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // แถวตั้งค่า: ขนาดสินค้า + เพศ
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _productSize,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ขนาดสินค้า", contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                            items: const [
                              DropdownMenuItem(value: "normal", child: Text("ขนาดปกติ (ถือ)", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: "large", child: Text("ขนาดใหญ่ (ชี้/ลูบ)", style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) => setState(() => _productSize = val!),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _modelType,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "เพศครีเอเตอร์", contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                            items: const [
                              DropdownMenuItem(value: "female", child: Text("นางแบบ (หญิง)", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: "male", child: Text("นายแบบ (ชาย)", style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) => setState(() => _modelType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // แถวตั้งค่า: ฉากหลัง + ความยาวคลิป (10 วิ หรือ 20-30 วิ)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _background,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ฉากหลัง", contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                            items: const [
                              DropdownMenuItem(value: "home", child: Text("ในห้อง/บ้าน", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: "market", child: Text("ตลาดนัด", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: "mall", child: Text("ห้างสรรพสินค้า", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: "factory", child: Text("โรงงาน", style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) => setState(() => _background = val!),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _duration,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ความยาวคลิป", contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                            items: const [
                              DropdownMenuItem(value: "20-30s", child: Text("20-30 วิ (ครบ 3 จังหวะ)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo))),
                              DropdownMenuItem(value: "10s", child: Text("10 วินาที", style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) => setState(() => _duration = val!),
                          ),
                        ),
                      ],
                    ),
                    if (_duration == "10s") ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              title: const Text("เน้นโน้มน้าว", style: TextStyle(fontSize: 11)),
                              value: "persuade",
                              groupValue: _tenSecFocus,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _tenSecFocus = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              title: const Text("เน้นปิดการขาย", style: TextStyle(fontSize: 11)),
                              value: "cta",
                              groupValue: _tenSecFocus,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _tenSecFocus = val!),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    // ปุ่ม 2 สเต็ป
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text("สเต็ป 1: เจนรูป 9:16", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _injectToMetaAI(_buildImagePrompt(), "📸 ส่งคำสั่งเจนรูป 9:16 เรียบร้อย"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.movie_creation_outlined, size: 16),
                            label: Text(_duration == "20-30s" ? "สเต็ป 2: เสกคลิป 20-30วิ" : "สเต็ป 2: เสกคลิป 10วิ", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _injectToMetaAI(_buildAnimatePrompt(), "🎬 ส่งคำสั่ง Animate คลิป ($_duration) เรียบร้อย"),
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
