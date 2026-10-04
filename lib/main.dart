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
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesCtrl = TextEditingController();

  String _productSize = "normal";
  String _background = "market";
  String _duration = "10s";
  String _tenSecFocus = "persuade";

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

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  String _buildCurrentPrompt() {
    final note = _notesCtrl.text.trim();
    final pDesc = note.isNotEmpty ? "product ($note) exactly matching reference image" : "product exactly matching reference image";

    String bgDesc = "";
    if (_background == "market") {
      bgDesc = "a vibrant outdoor night market with ambient warm lights";
    } else if (_background == "mall") {
      bgDesc = "a modern upscale shopping mall interior";
    } else {
      bgDesc = "an authentic manufacturing factory with operating conveyor belts";
    }

    String vidAction = "";
    String dialogue = "";

    if (_duration == "10s") {
      if (_tenSecFocus == "persuade") {
        dialogue = "ทุกคน ตัวนี้เด่นเรื่องความทนทาน ใช้งานสะดวก น้ำหนักเบา ตอบโจทย์ชีวิตประจำวันมากครับ!";
        vidAction = (_productSize == "normal")
            ? "holding and turning the $pDesc to showcase its texture and details"
            : "standing beside and pointing closely at key materials of the large $pDesc";
      } else {
        dialogue = "โปรคุ้มมากรอบนี้ ใครมองหาอยู่รีบกดลงตะกร้าสีเหลืองซ้ายมือด่วนเลย ช้าหมดอดนะครับ!";
        vidAction = "smiling confidently and pointing hand down toward the bottom-left basket";
      }
      return "Generate a photorealistic 10-second UGC review video of creator $vidAction in $bgDesc. Gaze: Genuine eye contact with camera. Dialogue: Character naturally speaks: '$dialogue' with realistic Thai lip-sync. 35mm lens.";
    } else {
      dialogue = "ทุกคน เจอปัญหานี้อยู่ใช่ไหม? ตัวนี้ตอบโจทย์มาก วัสดุดี ทนทาน คุ้มค่าสุดๆ รีบกดสั่งในตะกร้าซ้ายมือก่อนของหมดนะครับ!";
      vidAction = (_productSize == "normal")
          ? "holding the $pDesc at chest level, inspecting details, then pointing to bottom-left corner"
          : "standing beside the large $pDesc, caressing surface to show build quality, then gesturing to bottom-left corner";
      return "Generate a seamless photorealistic UGC video (20-30s) featuring creator $vidAction in $bgDesc. Sequence: [Hook] engaging camera gaze, [Value] showcasing craftsmanship, [CTA] smiling and pointing to shopping basket. Dialogue: Character naturally speaks: '$dialogue' synced with accurate Thai lip-sync. 35mm lens.";
    }
  }

  void _sendAutoToMetaAI() {
    final prompt = _buildCurrentPrompt();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚀 ส่งคำสั่งเข้า Meta AI อัตโนมัติเรียบร้อย!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dobby Studio (Image Upload)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text("⚙️ ข้อมูลสินค้า & ภาพอ้างอิง", style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // ส่วนอัปโหลดรูปภาพ
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.indigo.shade200, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                        child: _selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.indigo),
                                  SizedBox(height: 6),
                                  Text("แตะที่นี่เพื่ออัปโหลดรูปสินค้า (จากแคปหน้าจอ/คลังภาพ)",
                                      style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_selectedImage!, fit: BoxFit.contain),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ช่องใส่ข้อความเสริม (ไม่บังคับ)
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: "รายละเอียดเพิ่มเติม (ถ้ามี เช่น กางเกงบูทสีเหลือง)",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ขนาดสินค้า
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("ขนาดปกติ (ถือ)", style: TextStyle(fontSize: 13)),
                            value: "normal",
                            groupValue: _productSize,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _productSize = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("ขนาดใหญ่ (ชี้/ลูบ)", style: TextStyle(fontSize: 13)),
                            value: "large",
                            groupValue: _productSize,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _productSize = val!),
                          ),
                        ),
                      ],
                    ),

                    // ฉากหลัง & ความยาวคลิป
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _background,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ฉากหลัง"),
                            items: const [
                              DropdownMenuItem(value: "market", child: Text("ตลาดนัด")),
                              DropdownMenuItem(value: "mall", child: Text("ห้างสรรพสินค้า")),
                              DropdownMenuItem(value: "factory", child: Text("โรงงาน")),
                            ],
                            onChanged: (val) => setState(() => _background = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _duration,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ความยาว"),
                            items: const [
                              DropdownMenuItem(value: "10s", child: Text("10 วินาที")),
                              DropdownMenuItem(value: "20-30s", child: Text("20-30 วินาที")),
                            ],
                            onChanged: (val) => setState(() => _duration = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text("🚀 สั่งสร้างวิดีโอเข้า Meta AI ทันที"),
                        onPressed: _sendAutoToMetaAI,
                      ),
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
