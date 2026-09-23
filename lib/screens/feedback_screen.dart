import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/feedback_service.dart';

const _ink = Color(0xFF172D38);
const _teal = Color(0xFF15766D);
const _muted = Color(0xFF647681);
const _background = Color(0xFFF3F6F7);

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _service = FeedbackService();
  FeedbackType _type = FeedbackType.improvement;
  bool _opening = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    if (_opening || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await _service.compose(_type, _message.text);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is PlatformException &&
              error.code == 'email_unavailable'
          ? 'No email app is available. Install or set up an email app, then try again. Your message is still here.'
          : 'Could not prepare your email. Please try again. Your message is still here.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final problem = _type == FeedbackType.problem;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text('Help & feedback'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: _ink, borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.forum_outlined,
                              color: Color(0xFF9EDBD0), size: 32),
                          SizedBox(height: 18),
                          Text('Make CarAlerts better',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5)),
                          SizedBox(height: 10),
                          Text(
                              'Have an idea or spotted a problem? We’d love to hear from you.',
                              style: TextStyle(
                                  color: Color(0xFFC3D0D6),
                                  fontSize: 14,
                                  height: 1.6)),
                        ]),
                  ),
                  const SizedBox(height: 26),
                  const Text('What would you like to share?',
                      style: TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  RadioGroup<FeedbackType>(
                    groupValue: _type,
                    onChanged: (value) {
                      if (!_opening && value != null) {
                        setState(() => _type = value);
                      }
                    },
                    child: Column(
                        children: FeedbackType.values
                            .map((type) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: _type == type
                                        ? const Color(0xFFE6F3EF)
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                            color: _type == type
                                                ? _teal
                                                : const Color(0xFFE0E7EA))),
                                    clipBehavior: Clip.antiAlias,
                                    child: RadioListTile<FeedbackType>(
                                      value: type,
                                      activeColor: _teal,
                                      enabled: !_opening,
                                      title: Text(type.label,
                                          style: const TextStyle(
                                              color: _ink,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700)),
                                      secondary: Icon(
                                          type == FeedbackType.problem
                                              ? Icons.bug_report_outlined
                                              : Icons.lightbulb_outline,
                                          color: _teal),
                                    ),
                                  ),
                                ))
                            .toList()),
                  ),
                  const SizedBox(height: 12),
                  Text('Email subject: ${_type.subject}',
                      style: const TextStyle(
                          color: _muted, fontSize: 12, height: 1.5)),
                  const SizedBox(height: 20),
                  Text(
                      problem
                          ? 'Tell us what happened'
                          : 'Tell us about your idea',
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: _message,
                    enabled: !_opening,
                    minLines: 7,
                    maxLines: 14,
                    textCapitalization: TextCapitalization.sentences,
                    style:
                        const TextStyle(color: _ink, fontSize: 15, height: 1.5),
                    decoration: InputDecoration(
                      hintText: problem
                          ? 'What went wrong? What were you doing, and what did you expect to happen?'
                          : 'What could we improve, and how would it help you?',
                      hintStyle: const TextStyle(color: _muted, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E7EA))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E7EA))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _teal, width: 2)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please write a message before continuing.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 20, color: _teal),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'To help us understand your feedback, your phone model, OS version, and app version are automatically added at the end of the email.',
                                style: TextStyle(
                                    color: _muted, fontSize: 12, height: 1.6))),
                      ]),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFAD3939), height: 1.5))),
                    const SizedBox(height: 14),
                  ],
                  FilledButton.icon(
                    onPressed: _opening ? null : _compose,
                    style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    icon: _opening
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.email_outlined, size: 20),
                    label: Text(
                        _opening ? 'Preparing email…' : 'Continue to email'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Review and send from your email app.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: _muted, fontSize: 12, height: 1.6)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
