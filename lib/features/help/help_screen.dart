import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../auth/legal_webview_screen.dart';

/// In-app Help / FAQ. Answers the questions users, judges, and investors
/// ask within the first 30 seconds. Grouped by topic, searchable by eye.
///
/// Design principle: every answer is written in the user's words, not in
/// technical jargon. If an answer must mention something technical, it
/// explains why in plain English first.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // Which section indices are expanded. We open #0 by default so the user
  // sees content immediately on arrival rather than a wall of titles.
  final Set<int> _open = {0};

  static const _supportEmail = 'phantomtracealerts@gmail.com';

  // ── Content model ──────────────────────────────────────────────────────
  List<_Section> _sections() => [
        _Section(
          icon: Icons.rocket_launch,
          title: 'Getting started',
          items: const [
            _QA(
              q: 'How does PhantomTrace work?',
              a: 'PhantomTrace has three parts that work together:\n\n'
                 '1. A small program on your laptop (the agent) that runs '
                 'silently in the background.\n'
                 '2. This mobile app, where you see your laptops and send '
                 'commands.\n'
                 '3. A cloud service that lets the two talk to each other.\n\n'
                 'When you install the agent on your laptop, it registers '
                 'itself with your account using a one-time pairing code. '
                 'From then on, the laptop sends a heartbeat to the cloud '
                 'every few seconds, and the app shows it as ONLINE. If '
                 'your laptop is ever stolen, you tap "Mark as Stolen" in '
                 'this app and the agent immediately takes a webcam photo, '
                 'captures the screen, locks the laptop, and more.',
            ),
            _QA(
              q: 'How do I protect a new laptop?',
              a: 'Open this app, tap "Add device", and you get a 6-character '
                 'pairing code. On the laptop, download PhantomTraceAgent.exe '
                 'and double-click to run it. A small dialog appears asking '
                 'for the pairing code. Paste it, press "Pair device", and '
                 'the laptop appears in your dashboard within a few seconds.',
            ),
            _QA(
              q: 'What laptops does PhantomTrace support?',
              a: 'Any Windows 10 or Windows 11 laptop. Support for macOS and '
                 'Linux is on our roadmap. Chromebooks are not supported '
                 'because they use a different security model.',
            ),
          ],
        ),
        _Section(
          icon: Icons.privacy_tip,
          title: 'Privacy and data safety',
          items: const [
            _QA(
              q: 'Is my data safe?',
              a: 'Yes. Here is exactly who can see what:\n\n'
                 '• You can see all of your own data — devices, locations, '
                 'photos, screenshots — in this app.\n'
                 '• Nobody else can access your account unless you give them '
                 'your password or add them as an emergency contact.\n'
                 '• Emergency contacts only get a copy of the recovery report '
                 '(by email) when you mark a device as stolen. They do not '
                 'get continuing access to your account.\n\n'
                 'Please read the full Privacy Policy from the link at the '
                 'bottom of this screen.',
            ),
            _QA(
              q: 'Does the agent record my screen, camera, or audio all the time?',
              a: 'No. The agent captures a webcam photo ONLY when you send '
                 'the PHOTO command from this app, or automatically when you '
                 'mark the device as stolen or the agent detects a factory '
                 'reset attempt. The same rule applies to screenshots. The '
                 'agent does not record audio and does not log your keystrokes.',
            ),
            _QA(
              q: 'Can PhantomTrace staff see my photos or files?',
              a: 'No. The platform operator has administrative access to the '
                 'database for maintenance, but will not look at the '
                 'contents of individual accounts unless you specifically '
                 'ask for support that requires it, or we are legally '
                 'compelled.',
            ),
            _QA(
              q: 'Where is my data stored?',
              a: 'Account information, device records, locations, and '
                 'commands are stored in a secure cloud database. Webcam '
                 'photos and screenshots are stored by a dedicated '
                 'image-hosting provider. All transfers use HTTPS. Specific '
                 'provider names are in our Sub-processor list, linked from '
                 'the Privacy Policy.',
            ),
          ],
        ),
        _Section(
          icon: Icons.shield,
          title: 'If my laptop is stolen',
          items: const [
            _QA(
              q: 'What should I do if my laptop is stolen?',
              a: '1. Open this app and tap "Mark as Stolen" on the device.\n'
                 '2. The agent instantly takes a webcam photo + screenshot + '
                 'location fix, locks the screen, disables USB storage, and '
                 'enables BitLocker encryption.\n'
                 '3. Your emergency contacts get the recovery report by '
                 'email automatically.\n'
                 '4. From the device Overview, tap "Recovery Report" and '
                 '"Capture fresh" to get a current PDF to share with police.',
            ),
            _QA(
              q: 'What if the thief turns off the laptop?',
              a: 'As soon as they turn it back on, the agent comes back '
                 'online and sends you a fresh webcam photo, screenshot, and '
                 'location. We call this a "last-online snapshot" and it '
                 'often catches thieves logging in for the first time at '
                 'home or in a pawn shop.',
            ),
            _QA(
              q: 'What if the thief tries to factory-reset the laptop?',
              a: 'The agent watches for the Reset-This-PC screen. The moment '
                 'it appears, we capture a photo, a screenshot, and the '
                 'location — then lock the screen — all before the reset '
                 'actually begins. The evidence is already safe in the '
                 'cloud before the laptop is wiped.',
            ),
            _QA(
              q: 'What if the thief boots the laptop from a USB stick to install Windows?',
              a: 'This is the hardest attack to stop because the agent is '
                 'not running yet during USB boot. Three defences work '
                 'together: (1) if you set a BIOS password following our '
                 'wizard, the thief cannot boot from USB at all; (2) '
                 'BitLocker encrypts the drive so even a successful wipe '
                 'cannot read your old files; (3) you still have the '
                 'webcam photo captured before the shutdown.',
            ),
          ],
        ),
        _Section(
          icon: Icons.lock,
          title: 'Security and passwords',
          items: const [
            _QA(
              q: 'How do I enable two-factor authentication?',
              a: 'Go to Settings → Security → Two-factor authentication. '
                 'Scan the QR code with Google Authenticator or any TOTP '
                 'app, then type the 6-digit code to confirm. From then on, '
                 'logging in on a new device will ask for the code.',
            ),
            _QA(
              q: 'What if I forget my password?',
              a: 'Tap "Forgot password?" on the login screen. We will send a '
                 '6-digit code to the phone number on your account. Enter '
                 'the code, set a new password, and sign in. This two-channel '
                 'proof (email + phone) stops anyone with only one of them '
                 'from taking over your account.',
            ),
            _QA(
              q: 'What if I forget my BIOS password?',
              a: 'We cannot help with BIOS passwords because they are set '
                 'in your laptop\'s firmware, not in our system. Contact '
                 'your laptop\'s manufacturer (HP, Dell, Lenovo etc.) with '
                 'proof of ownership — they can usually reset it. Keep the '
                 'password somewhere safe when you first set it.',
            ),
            _QA(
              q: 'Can I use fingerprint sign-in?',
              a: 'Yes, if your phone has a fingerprint sensor. After your '
                 'first password login we offer to enable fingerprint '
                 'sign-in. The next time you open the app, it unlocks with '
                 'your fingerprint. You can turn this off at any time in '
                 'Settings → Security.',
            ),
          ],
        ),
        _Section(
          icon: Icons.build,
          title: 'Troubleshooting',
          items: const [
            _QA(
              q: 'My laptop shows as OFFLINE but it is on and connected.',
              a: 'The agent sends a heartbeat every few seconds. If it has '
                 'not reached our server for 30 seconds, we show it as '
                 'OFFLINE. Common causes: slow Wi-Fi, a VPN that blocks our '
                 'server, or antivirus software quarantining the agent. '
                 'Open Task Manager on the laptop and look for '
                 '"PhantomTraceAgent.exe"; if it is not running, launch it '
                 'manually from where you installed it.',
            ),
            _QA(
              q: 'I pressed Capture Fresh and the photos never came.',
              a: 'The agent needs to receive the command and upload the '
                 'image, which takes 15 to 30 seconds total. If the device '
                 'is offline or has very slow internet, the capture may not '
                 'arrive in time. Try again when the device shows a strong '
                 'ONLINE indicator.',
            ),
            _QA(
              q: 'I accepted the fingerprint prompt but it never asks me.',
              a: 'Open your phone Settings → Security and make sure at least '
                 'one fingerprint is enrolled. In this app, sign in with '
                 'your password once, choose "Enable" when offered, and '
                 'confirm with your fingerprint.',
            ),
            _QA(
              q: 'The pairing code did not work.',
              a: 'Pairing codes expire after 30 minutes. If yours is older '
                 'than that, generate a new one from this app. Codes are '
                 'case-insensitive but must be typed exactly otherwise. If '
                 'you still get an error, make sure the laptop can reach '
                 'the internet.',
            ),
          ],
        ),
        _Section(
          icon: Icons.help_outline,
          title: 'Other',
          items: const [
            _QA(
              q: 'How much does PhantomTrace cost?',
              a: 'Right now PhantomTrace is free while in beta. Paid plans '
                 'may come later for teams and institutions; personal use '
                 'will remain free or very low cost.',
            ),
            _QA(
              q: 'How do I uninstall PhantomTrace?',
              a: 'In this app, tap the trash icon on the device tile. We '
                 'send an uninstall signal to the laptop that removes the '
                 'agent and all its traces, and we delete your evidence '
                 'from our servers. If the laptop is offline, the '
                 'uninstall completes when it next comes online.',
            ),
            _QA(
              q: 'How do I delete my account?',
              a: 'Go to Settings → Account → Delete account. You will be '
                 'asked to type your email to confirm. All of your devices, '
                 'photos, locations, and account data are removed within '
                 '30 days. This cannot be undone.',
            ),
            _QA(
              q: 'How do I get help?',
              a: 'Email us. The contact button is at the bottom of this '
                 'screen. Please include your email address, what you were '
                 'trying to do, and what happened. Screenshots help a lot.',
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Help & FAQ'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text('ANSWERS AT A GLANCE',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'If something is missing from this page, email us and we will '
              'add it. Your questions make the next version better.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            ...sections.asMap().entries.map(
                  (e) => _sectionTile(e.key, e.value),
                ),
            const SizedBox(height: 28),
            _contactCard(),
            const SizedBox(height: 16),
            _legalLinks(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTile(int index, _Section s) {
    final open = _open.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              if (open) {
                _open.remove(index);
              } else {
                _open.add(index);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(s.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5)),
                ),
                Icon(open ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white60),
              ]),
            ),
          ),
          if (open) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: s.items.map(_qaTile).toList(),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _qaTile(_QA qa) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(qa.q, style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
            const SizedBox(height: 6),
            SelectableText(qa.a, style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.5)),
          ],
        ),
      );

  Widget _contactCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Still stuck?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Email us with your issue and we usually reply within 24 hours.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(_supportEmail,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: _supportEmail));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied')),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
            ]),
          ],
        ),
      );

  Widget _legalLinks() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalWebviewScreen(
                  title: 'Terms of Service', path: '/terms',
                ),
              ),
            ),
            child: const Text('Terms of Service',
                style: TextStyle(color: Colors.white54)),
          ),
          const Text(' · ', style: TextStyle(color: Colors.white24)),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalWebviewScreen(
                  title: 'Privacy Policy', path: '/privacy',
                ),
              ),
            ),
            child: const Text('Privacy Policy',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      );
}

class _Section {
  final IconData icon;
  final String title;
  final List<_QA> items;
  const _Section({required this.icon, required this.title, required this.items});
}

class _QA {
  final String q;
  final String a;
  const _QA({required this.q, required this.a});
}
