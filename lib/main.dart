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

  String _modelType = "female";
  String _productSize = "normal";
  String _background = "home";
  String _duration = "20-30s";

  late final WebViewController _webController;
  bool _isLoadingWeb = true;
  bool _isAutoProcessing = false;

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
      ..addJavaScriptChannel(
        'VideoAutoBot',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'PHOTO_DONE') {
            setState(() {
              _isAutoProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🎬 ระบบสั่งสร้างวิดีโอต่อให้อัตโนมัติเรียบร้อย!")),
            );
          }
        },
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
        "The product design, colors, and textures strictly replicate the attached product reference image. "
        "Background: $bgDesc. True-to-life scale, pristine product details, 50mm lens, 8k resolution, crisp photorealism.";
  }

  String _buildAnimatePrompt() {
    final pName = _notesCtrl.text.trim().isEmpty ? "สินค้าตัวนี้" : _notesCtrl.text.trim();
    final hookLine = "ทุกคน ใครเจอปัญหานี้อยู่ ฟังทางนี้ด่วนเลยครับ!";
    final valueLine = "$pName ตัวนี้บอกเลยว่าตอบโจทย์มาก ดีไซน์สวย ใช้งานง่าย ทนทาน คุ้มราคาที่สุด!";
    final ctaLine = "ตอนนี้มีโปรลดพิเศษ รีบกดสั่งในตะกร้าสีเหลืองมุมซ้ายล่างก่อนของจะหมดนะครับ!";
    final fullDialogue = "$hookLine $valueLine $ctaLine";

    return "Animate this 9:16 image into a vertical 9:16 video. "
        "Preserve exact creator identity and product design. "
        "Creator speaks naturally with Thai lip-sync: '$fullDialogue' and points clearly to bottom-left corner.";
  }

  // ฟังก์ชันกดปุ่มเดียวจบ: ส่งรูป -> ตรวจว่ารูปมา -> ส่งเสกคลิปต่อทันที
  void _runFullAutoPipeline() {
    setState(() {
      _isAutoProcessing = true;
    });

    final imgPrompt = _buildImagePrompt().replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', ' ');
    final vidPrompt = _buildAnimatePrompt().replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', ' ');

    final autoJs = """
      (function() {
        function sendText(text, callback) {
          var input = document.querySelector('textarea, div[contenteditable="true"], input[type="text"]');
          if (input) {
            if (input.tagName.toLowerCase() === 'textarea' || input.tagName.toLowerCase() === 'input') {
              input.value = text;
              input.dispatchEvent(new Event('input', { bubbles: true }));
            } else {
              input.innerText = text;
              input.dispatchEvent(new Event('input', { bubbles: true }));
            }
            setTimeout(function() {
              var btn = document.querySelector('button[aria-label*="Send"], button[aria-label*="ส่ง"], div[role="button"][aria-label*="Send"]');
              if (btn) {
                btn.click();
              } else {
                input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true }));
              }
              if (callback) callback();
            }, 400);
          }
        }

        // ขั้นที่ 1: ส่งคำสั่งสร้างรูป 9:16
        var initialImgCount = document.querySelectorAll('img').length;
        sendText('$imgPrompt', function() {
          // ขั้นที่ 2: ตั้ง Loop ตรวจสอบว่ารูปใหม่เจนเสร็จหรือยัง
          var checkCount = 0;
          var interval = setInterval(function() {
            checkCount++;
            var currentImgCount = document.querySelectorAll('img').length;
            var isThinking = document.body.innerText.includes('thinking') || document.body.innerText.includes('กำลังคิด');

            // ถ้ารูปเพิ่มขึ้นและ AI หยุดคิดแล้ว แสดงว่ารูปสร้างเสร็จแล้ว
            if (currentImgCount > initialImgCount && !isThinking && checkCount > 5) {
              clearInterval(interval);
              setTimeout(function() {
                // ขั้นที่ 3: สั่ง Animate เป็นคลิปอัตโนมัติต่อทันที
                sendText('$vidPrompt', function() {
                  if (window.VideoAutoBot) {
                    window.VideoAutoBot.postMessage('PHOTO_DONE');
                  }
                });
              }, 1500);
            }

            // Timeout ป้องกันค้าง (เกิน 90 วิ)
            if (checkCount > 90) {
              clearInterval(interval);
            }
          }, 1000);
        });
      })();
    """;

    _webController.runJavaScript(autoJs);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚡ เริ่มระบบอัตโนมัติ: กำลังสร้างรูป และจะต่อด้วยวิดีโอให้ทันที...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dobby Studio (One-Click Pro)"),
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
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(true),
                            child: Container(
                              height: 75,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.shade50,
                              ),
                              child: _productImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 22),
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
                              height: 75,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.purple.shade50,
                              ),
                              child: _modelImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.person_outline, color: Colors.purple, size: 22),
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
                              DropdownMenuItem(value: "20-30s", child: Text("20-30 วิ (Hook+ปิดการขาย)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo))),
                              DropdownMenuItem(value: "10s", child: Text("10 วินาที", style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) => setState(() => _duration = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ปุ่มกดเดียวจบแบบ All-in-One
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isAutoProcessing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.auto_awesome, size: 20),
                        label: Text(
                          _isAutoProcessing ? "⚡ กำลังทำงานอัตโนมัติ (เจนรูป ➜ ขยับคลิป)..." : "⚡ สร้างคลิปอัตโนมัติ (ปุ่มเดียวจบ)",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isAutoProcessing ? null : _runFullAutoPipeline,
                      ),
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
