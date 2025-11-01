import 'package:flutter/material.dart';
import 'package:language_app/avatar_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: const AvatarDemoPage());
  }
}

class AvatarDemoPage extends StatelessWidget {
  const AvatarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USDZ Demo')),
      body: const Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AvatarView(),
        ),
      ),
    );
  }
}
/*
class AvatarScene extends StatefulWidget {
  const AvatarScene({super.key});

  @override
  State<AvatarScene> createState() => _AvatarSceneState();
}

class _AvatarSceneState extends State<AvatarScene> {
  O3DController controller = O3DController();
  final js = r"""
function dumpMorphTargets(el){
  const names = new Set();
  el.scene?.traverse(obj => {
    if (obj.isMesh && obj.morphTargetDictionary) {
      for (const k of Object.keys(obj.morphTargetDictionary)) names.add(k);
    }
  });
  try { log.postMessage('morphTargets: ' + JSON.stringify([...names])); } catch(e){}
}
(function() {
  // Liefert das model-viewer-Element, egal ob per o3d-Var oder Query
  function getEl() {
    if (window.o3davatar3d) return window.o3davatar3d;
    return document.getElementById('avatar3d') || document.querySelector('model-viewer');
  }

  // Warten bis Element existiert
  function waitForElement() {
    return new Promise(resolve => {
      const tick = () => {
        const el = getEl();
        if (el) return resolve(el);
        requestAnimationFrame(tick);
      };
      tick();
    });
  }

  // Warten bis GLB geladen ist
  function onModelReady(el){
    return new Promise(resolve => {
      if (el?.model) return resolve();
      el.addEventListener('load', () => resolve(), { once: true });
    });
  }

  async function makeApi(){
    const el = await waitForElement();
    await onModelReady(el);

    function resetAll(){
      el.scene?.traverse(obj => {
        if (obj.isMesh && obj.morphTargetInfluences) {
          for (let i=0; i<obj.morphTargetInfluences.length; i++){
            obj.morphTargetInfluences[i] = 0;
          }
        }
      });
    }

    function setViseme(name, weight){
      el.scene?.traverse(obj => {
        if (obj.isMesh && obj.morphTargetDictionary && obj.morphTargetInfluences) {
          const dict = obj.morphTargetDictionary;
          if (name in dict) {
            const idx = dict[name];
            obj.morphTargetInfluences[idx] = weight;
          }
        }
      });
    }

    function setSingleViseme(name, weight){
      resetAll();
      setViseme(name, weight);
    }

    async function playSequence(seq){
      for (const step of seq){
        setSingleViseme(step.name, step.weight ?? 1.0);
        await new Promise(r => setTimeout(r, step.ms ?? 80));
      }
      resetAll();
    }

    // Dispatch-Bridge für Flutter
    window.viseme_dispatch = async function(payloadJson){
      try{
        const msg = JSON.parse(payloadJson);
        if (msg.type === 'single'){ setSingleViseme(msg.name, msg.weight ?? 1.0); }
        else if (msg.type === 'set'){ setViseme(msg.name, msg.weight ?? 1.0); }
        else if (msg.type === 'reset'){ resetAll(); }
        else if (msg.type === 'sequence'){ await playSequence(msg.items || []); }
      } catch(e){ console.error('viseme_dispatch error', e); }
    };

    // Exponiere API & Ready-Flag
    window.o3dVisemes = { resetAll, setViseme, setSingleViseme, playSequence };
    window.o3dVisemesReady = true;
    console.log('o3dVisemes ready');
  }

  // Boot
  makeApi().catch(e => console.error('o3dVisemes init error', e));
})();
""";

  Future<void> setSingleViseme(String name, double weight) async {
    await _waitForVisemeApi();
    final payload = {"type": "single", "name": name, "weight": weight};
    await _wv.runJavaScript('window.viseme_dispatch(${jsonEncode(payload)})');
  }

  late WebViewController _wv;
  Future<void> playVisemeSequence() async {
    await _waitForVisemeApi();
    final seq = [
      {"name": "viseme_aa", "weight": 0.8, "ms": 80},
      {"name": "viseme_CH", "weight": 0.8, "ms": 80},
      {"name": "viseme_E", "weight": 0.8, "ms": 80},
      {"name": "viseme_O", "weight": 0.8, "ms": 80},
      {"name": "viseme_PP", "weight": 0.8, "ms": 80},
      {"name": "viseme_FF", "weight": 0.8, "ms": 80},
      {"name": "viseme_DD", "weight": 0.8, "ms": 80},
      {"name": "viseme_U", "weight": 0.8, "ms": 80},
    ];
    final payload = {"type": "sequence", "items": seq};
    await _wv.runJavaScript('window.viseme_dispatch(${jsonEncode(payload)})');
  }

// Alle auf 0
  Future<void> resetVisemes(WebViewController c) async {
    await _wv.runJavaScript(
        'window.viseme_dispatch(${jsonEncode({"type": "reset"})})');
  }

  Future<void> _waitForVisemeApi(
      {Duration timeout = const Duration(seconds: 10)}) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      final res = await _wv.runJavaScriptReturningResult(
          '(typeof window.o3dVisemesReady !== "undefined" && window.o3dVisemesReady) ? "true" : "false"');
      final s = '$res'.replaceAll('"', '');
      if (s == 'true') return;
      await Future.delayed(const Duration(milliseconds: 80));
    }
    throw TimeoutException('o3dVisemes did not appear in time');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Avatar Test'),
        actions: [
          IconButton(
              onPressed: () => controller.cameraOrbit(20, 20, 5),
              icon: const Icon(Icons.change_circle)),
          IconButton(
              onPressed: () => controller.cameraTarget(1.2, 1, 4),
              icon: const Icon(Icons.change_circle_outlined)),
          ElevatedButton(
            onPressed: () async {
              // optional: warte-sicherheit, falls du sie nicht schon hast
              await _waitForVisemeApi();
              final payload = {
                "type": "sequence",
                "items": [
                  {"name": "viseme_aa", "weight": 0.9, "ms": 120},
                  {"name": "viseme_CH", "weight": 0.9, "ms": 120},
                  {"name": "viseme_E", "weight": 0.9, "ms": 120},
                ]
              };
              await _wv.runJavaScript(
                  'window.viseme_dispatch(${jsonEncode(payload)})');
            },
            child: const Text('Viseme-Test'),
          )
        ],
      ),
      body: O3D.asset(
        src: 'assets/avatar.glb',
        id: 'avatar3d', // <— passt zum JS
        debugLogging: true,
        controller: controller,
        relatedJs: js,
        javascriptChannels: {
          JavascriptChannel(
            'viseme',
            onMessageReceived: (msg) => debugPrint('viseme: ${msg.message}'),
          ),
          JavascriptChannel(
            'log',
            onMessageReceived: (m) => debugPrint('JS: ${m.message}'),
          ),
        },
        onWebViewCreated: (ctrl) async {
          _wv = ctrl;

          await _wv.setNavigationDelegate(NavigationDelegate(
            onPageFinished: (url) async {
              try {
                // check: JS überhaupt lauffähig
                await _wv.runJavaScript('void 0;');
                await _waitForVisemeApi();
                debugPrint('o3dVisemes ready ✅');

                // hier könntest du testweise ein Viseme setzen:
                await _wv.runJavaScript('window.viseme_dispatch(${jsonEncode({
                      "type": "single",
                      "name": "viseme_aa",
                      "weight": 0.7
                    })})');
                await Future.delayed(const Duration(milliseconds: 300));
                await _wv.runJavaScript(
                    'window.viseme_dispatch(${jsonEncode({"type": "reset"})})');
              } catch (e) {
                debugPrint('waitForVisemeApi error: $e');
              }
            },
          ));
        },
      ),
    );
  }
}
*/
