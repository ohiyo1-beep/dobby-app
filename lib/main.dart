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
      TextEditingController(text: "กล้องวงจรปิดโซลาร์เซลล์ 3 เลนส์ สีดำ");

  String _modelType = "female";
  String _productSize = "normal";
  String _background = "home";
  String _duration = "10s";

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

  String _buildImagePrompt() {
    final pName = _notesCtrl.text.trim().isEmpty ? "product" : _notesCtrl.text.trim();
    final person = _modelType == "female" ? "young Thai female creator" : "young Thai male creator";
    final action = (_productSize == "normal")
        ? "holding and demonstrating the exact $pName at chest level"
        : "standing beside the large $pName pointing at its features";

    return "Vertical 9:16 portrait. Hyper-realistic commercial shot of $person $action. "
        "Strictly copy the exact design, lenses, solar panel, and details from the attached product reference image. "
        "Background: $_background. 8k, crisp focus, commercial studio lighting.";
  }

  String _buildAnimatePrompt() {
    final dialogue = _duration == "10s"
        ? "ทุกคน ตัวนี้ตอบโจทย์มาก ฟังก์ชันครบ คุ้มราคา รีบกดสั่งในตะกร้าซ้ายมือเลยครับ!"
        : "เจอปัญหานี้อยู่ใช่ไหม? ตัวนี้ของจริง ดีไซน์สวย ทนทาน คุ้มค่า กดตะกร้าเหลืองด่วนเลยครับ!";

    return "Animate this 9:16 image into a video. Keep vertical 9:16 aspect ratio. "
        "Maintain creator appearance and exact product shape. "
        "Creator speaks with Thai lip-sync: '$dialogue' and points to the bottom-left corner.";
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
      SnackBar(content: Text("$label (คัดลอกข้อความแล้ว)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dobby Studio (Product Match)"),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(true),
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.shade50,
                              ),
                              child: _productImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.inventory_2_outlined, color: Colors.blue),
                                        Text("📦 รูปสินค้า", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                              height: 90,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.purple.shade50,
                              ),
                              child: _modelImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.person_outline, color: Colors.purple),
                                        Text("👤 หน้านางแบบ/นายแบบ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
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
                        labelText: "รายละเอียดสินค้า (เช่น กล้อง 3 เลนส์ สีดำ)",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text("สเต็ป 1: เจนรูป 9:16", style: TextStyle(fontSize: 12)),
                            onPressed: () => _injectToMetaAI(_buildImagePrompt(), "📸 ส่งคำสั่งเจนรูป 9:16 เรียบร้อย"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.movie_creation_outlined, size: 16),
                            label: const Text("สเต็ป 2: เสกคลิป 9:16", style: TextStyle(fontSize: 12)),
                            onPressed: () => _injectToMetaAI(_buildAnimatePrompt(), "🎬 ส่งคำสั่ง Animate คลิป 9:16 เรียบร้อย"),
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
