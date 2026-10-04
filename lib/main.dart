import 'package:flutter/material.dart';
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
  final TextEditingController _productCtrl =
      TextEditingController(text: "รองเท้าผ้าใบสีขาวพื้นนุ่ม");

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

  String _buildCurrentPrompt() {
    final pName = _productCtrl.text.trim().isEmpty
        ? "สินค้า"
        : _productCtrl.text.trim();

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
            ? "holding and turning $pName to show textures"
            : "pointing closely at key materials of the large $pName";
      } else {
        dialogue = "โปรคุ้มมากรอบนี้ ใครมองหาอยู่รีบกดลงตะกร้าสีเหลืองซ้ายมือด่วนเลย ช้าหมดอดนะครับ!";
        vidAction = "smiling confidently and pointing hand down toward bottom-left corner";
      }
      return "Generate a photorealistic 10-second UGC review video of creator $vidAction in $bgDesc. Gaze: Genuine eye contact with camera. Dialogue: Character naturally speaks: '$dialogue' with realistic Thai lip-sync. 35mm lens.";
    } else {
      dialogue = "ทุกคน เจอปัญหานี้อยู่ใช่ไหม? ตัวนี้ตอบโจทย์มาก วัสดุดี ทนทาน คุ้มค่าสุดๆ รีบกดสั่งในตะกร้าซ้ายมือก่อนของหมดนะครับ!";
      vidAction = (_productSize == "normal")
          ? "holding $pName at chest level, inspecting details, then pointing to bottom-left corner"
          : "standing beside the large $pName, caressing surface, then gesturing to bottom-left corner";
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
        title: const Text("Dobby Studio (Auto Meta AI)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ส่วนตั้งค่าสินค้าด้านบน (พับย่อได้)
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text("⚙️ ตั้งค่าสินค้า & วิดีโอ", style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _productCtrl,
                      decoration: const InputDecoration(
                        labelText: "ชื่อสินค้า",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _background,
                            isDense: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "ฉากหลัง"),
                            items: const [
                              DropdownMenuItem(value: "market", child: Text("ตลาดนัด")),
                              DropdownMenuItem(value: "mall", child: Text("ห้างหรู")),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
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
