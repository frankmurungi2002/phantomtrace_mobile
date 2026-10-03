import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';

/// Shows the Terms of Service or Privacy Policy page in-app.
///
/// We DO NOT add webview_flutter as a dependency (it bloats the APK by
/// ~15 MB and needs native wiring). Instead, we fetch the HTML text from
/// the backend and parse the semantic elements (h1/h2/p/ul/li) into
/// styled Flutter widgets. The source of truth remains the HTML on the
/// backend — change the text there and every client sees the update.
class LegalWebviewScreen extends StatefulWidget {
  final String title;
  final String path;    // e.g. '/terms' or '/privacy'

  const LegalWebviewScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  State<LegalWebviewScreen> createState() => _LegalWebviewScreenState();
}

class _LegalWebviewScreenState extends State<LegalWebviewScreen> {
  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));
  bool _loading = true;
  String? _error;
  List<_Block> _blocks = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await _dio.get(
        '${ApiConstants.baseUrl}${widget.path}',
        options: Options(responseType: ResponseType.plain),
      );
      if (r.statusCode == 200 && r.data is String) {
        _blocks = _parseHtml(r.data as String);
      } else {
        _error = 'Could not load this page (code ${r.statusCode}).';
      }
    } catch (_) {
      _error = 'Could not reach the server. Check your internet and try again.';
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Minimal HTML parser ──────────────────────────────────────────────
  // We only care about h1, h2, h3, p, ul>li, and inline <a href>. Anything
  // else is dropped. This keeps the APK small and the renderer predictable.
  List<_Block> _parseHtml(String html) {
    final blocks = <_Block>[];
    // Grab just the body.
    final bodyMatch = RegExp(r'<body[^>]*>([\s\S]*?)</body>', caseSensitive: false)
        .firstMatch(html);
    final body = bodyMatch?.group(1) ?? html;

    // Match tag by tag, in order. We keep p, h1, h2, h3, ul, li and <a>.
    final tagRe = RegExp(
      r'<(h1|h2|h3|p|ul|li|a|table|tr|th|td)[^>]*>([\s\S]*?)</\1>',
      caseSensitive: false,
    );
    for (final m in tagRe.allMatches(body)) {
      final tag = m.group(1)!.toLowerCase();
      final raw = m.group(2) ?? '';
      switch (tag) {
        case 'h1':
          blocks.add(_Block(_BlockKind.h1, _stripInline(raw)));
          break;
        case 'h2':
          blocks.add(_Block(_BlockKind.h2, _stripInline(raw)));
          break;
        case 'h3':
          blocks.add(_Block(_BlockKind.h3, _stripInline(raw)));
          break;
        case 'p':
          blocks.add(_Block(_BlockKind.p, _stripInline(raw)));
          break;
        case 'ul':
          // Pull <li> items out, each as its own bullet block.
          final items = RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false)
              .allMatches(raw)
              .map((lm) => _stripInline(lm.group(1) ?? ''))
              .toList();
          for (final i in items) {
            blocks.add(_Block(_BlockKind.li, i));
          }
          break;
      }
    }
    return blocks;
  }

  String _stripInline(String s) {
    // Replace inline tags with their text content, then strip remaining tags
    // and collapse whitespace.
    s = s.replaceAll(RegExp(r'<a[^>]*>|</a>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<b>|</b>|<strong>|</strong>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll('&amp;', '&')
         .replaceAll('&lt;', '<')
         .replaceAll('&gt;', '>')
         .replaceAll('&middot;', '·')
         .replaceAll('&quot;', '"')
         .replaceAll(RegExp(r'\s+'), ' ')
         .trim();
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white54, size: 46),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() { _loading = true; _error = null; });
                            _fetch();
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                    itemCount: _blocks.length,
                    itemBuilder: (ctx, i) => _render(_blocks[i]),
                  ),
                ),
    );
  }

  Widget _render(_Block b) {
    switch (b.kind) {
      case _BlockKind.h1:
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: Text(b.text, style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        );
      case _BlockKind.h2:
        return Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text(b.text, style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
        );
      case _BlockKind.h3:
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(b.text, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        );
      case _BlockKind.p:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(b.text, style: const TextStyle(
              color: Colors.white70, fontSize: 14.5, height: 1.55)),
        );
      case _BlockKind.li:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 7, right: 10),
                child: Icon(Icons.circle, size: 5, color: Colors.white60),
              ),
              Expanded(
                child: Text(b.text, style: const TextStyle(
                    color: Colors.white70, fontSize: 14.5, height: 1.55)),
              ),
            ],
          ),
        );
    }
  }
}

enum _BlockKind { h1, h2, h3, p, li }

class _Block {
  final _BlockKind kind;
  final String text;
  const _Block(this.kind, this.text);
}
