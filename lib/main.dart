import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
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
  String _duration = "20-30s";
  String _tenSecFocus = "persuade";

  String _imagePromptStyle1 = "";
  String _imagePromptStyle2 = "";
  String _videoPrompt = "";
  String _captionHashtags = "";
  bool _hasGenerated = false;

  void _generatePrompts() {
    final pName = _productCtrl.text.trim().isEmpty
        ? "สินค้าคุณภาพ"
        : _productCtrl.text.trim();

    String bgDesc = "";
    if (_background == "market") {
      bgDesc = "a vibrant outdoor night market with warm ambient lighting";
    } else if (_background == "mall") {
      bgDesc = "a clean modern shopping mall interior";
    } else {
      bgDesc = "an authentic manufacturing factory with modern conveyor belts";
    }

    String actionPerson = "";
    String actionHand = "";
    if (_productSize == "normal") {
      actionPerson = "securely holding and showcasing $pName at chest level";
      actionHand = "a young woman's hands cleanly holding and presenting $pName";
    } else {
      actionPerson =
          "standing beside the life-sized large $pName, gently pointing at its features and brushing hand over its surface";
      actionHand =
          "a woman's hand gently caressing and pointing to details on the large-scale $pName";
    }

    _imagePromptStyle1 =
        "A hyper-realistic photograph of a trendy Thai creator matching reference face, $actionPerson. "
        "Background is $bgDesc. Authentic true-to-life scale and proportion. Strictly accurate readable typography on product labels. 50mm portrait lens, 8k resolution.";

    _imagePromptStyle2 =
        "A hyper-realistic first-person POV shot showing only $actionHand. "
        "Background is $bgDesc. Product shown in true-to-life realistic dimensions. Clear typography on package. Commercial product photography.";

    String dialogue = "";
    String videoAction = "";

    if (_duration == "10s") {
      if (_tenSecFocus == "persuade") {
        dialogue = "ทุกคน ตัวนี้เด่นเรื่องความทนทาน ใช้งานสะดวก น้ำหนักเบา ตอบโจทย์ชีวิตประจำวันมากครับ!";
        videoAction = _productSize == "normal"
            ? "holding and turning $pName to show textures and quality"
            : "pointing closely at the key materials of the large $pName";
      } else {
        dialogue = "โปรคุ้มมากรอบนี้ ใครมองหาอยู่รีบกดลงตะกร้าสีเหลืองซ้ายมือด่วนเลย ช้าหมดอดนะครับ!";
        videoAction = "smiling confidently and pointing hand down toward the bottom-left basket";
      }
      _videoPrompt =
          "A crisp photorealistic 10-second UGC review video of creator $videoAction in $bgDesc. "
          "Gaze: Genuine eye contact with camera. Dialogue: Character naturally speaks: '$dialogue' with realistic Thai lip-sync. 35mm lens.";
    } else {
      dialogue =
          "ทุกคน เจอปัญหานี้อยู่ใช่ไหม? ตัวนี้ตอบโจทย์มาก วัสดุดี ทนทาน คุ้มค่าสุดๆ รีบกดสั่งในตะกร้าซ้ายมือก่อนของหมดนะครับ!";
      videoAction = _productSize == "normal"
          ? "holding $pName at chest level, inspecting details, then pointing to bottom-left corner"
          : "standing beside the large $pName, caressing surface to demonstrate build quality, then gesturing to bottom-left corner";

      _videoPrompt =
          "A seamless photorealistic UGC video (20-30s) featuring creator $videoAction in $bgDesc. "
          "Sequence: [Hook] engaging camera gaze, [Value] showcasing fine craftsmanship, [CTA] smiling and pointing to shopping basket. "
          "Dialogue: Character naturally speaks: '$dialogue' synced with accurate Thai lip-sync. 35mm lens.";
    }

    _captionHashtags =
        "ใครกำลังตามหา $pName บอกเลยว่าตัวนี้ของจริง! คุณภาพดีตอบโจทย์มาก สเกลตรงปกไม่จกตา คุ้มค่าสมราคาแน่นอน สนใจรีบจิ้มพิกัดในตะกร้าได้เลยครับ 👇✨\n\n"
        "#รีวิวของดี #รีวิว$pName #ป้ายยาของใช้ #ของดีบอกต่อ #TikTokShopครีเอเตอร์";

    setState(() {
      _hasGenerated = true;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("คัดลอก $label เรียบร้อยแล้ว")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dobby Studio Builder"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. ข้อมูลและขนาดสินค้า",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _productCtrl,
              decoration: const InputDecoration(
                labelText: "ชื่อสินค้า / รายละเอียด",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const Text("ขนาดสินค้า:", style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("ขนาดปกติ (ถือโชว์)"),
                    value: "normal",
                    groupValue: _productSize,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _productSize = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("ขนาดใหญ่ (ชี้/ลูบ)"),
                    value: "large",
                    groupValue: _productSize,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _productSize = val!),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text("2. สถานที่ / ฉากหลัง",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _background,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: "market", child: Text("ตลาดนัด (Night Market)")),
                DropdownMenuItem(value: "mall", child: Text("ห้างสรรพสินค้า (Shopping Mall)")),
                DropdownMenuItem(value: "factory", child: Text("โรงงานมีสายพานผลิต (Factory)")),
              ],
              onChanged: (val) => setState(() => _background = val!),
            ),
            const Divider(height: 24),
            const Text("3. ความยาววิดีโอ & สไตล์บทพูด",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("10 วินาที")),
                    selected: _duration == "10s",
                    onSelected: (val) => setState(() => _duration = "10s"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("20–30 วินาที (ครบ 3 ช่วง)")),
                    selected: _duration == "20-30s",
                    onSelected: (val) => setState(() => _duration = "20-30s"),
                  ),
                ),
              ],
            ),
            if (_duration == "10s") ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("เน้นโน้มน้าว"),
                      value: "persuade",
                      groupValue: _tenSecFocus,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _tenSecFocus = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("เน้นปิดการขาย"),
                      value: "cta",
                      groupValue: _tenSecFocus,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _tenSecFocus = val!),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text("สร้างชุดคำสั่ง Prompt ทั้งหมด"),
                onPressed: _generatePrompts,
              ),
            ),
            if (_hasGenerated) ...[
              const Divider(height: 32),
              _buildResultCard("🖼️ Image Prompt แบบที่ 1 (คนถือ/สัมผัส)", _imagePromptStyle1),
              _buildResultCard("✋ Image Prompt แบบที่ 2 (POV มือผู้หญิง)", _imagePromptStyle2),
              _buildResultCard("🎬 Video Prompt (รวมบทพูดภาษาไทย)", _videoPrompt),
              _buildResultCard("📝 แคปชั่น + แฮชแท็ก (#)", _captionHashtags),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: Colors.indigo),
                  onPressed: () => _copyToClipboard(content, title),
                ),
              ],
            ),
            Text(content, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
