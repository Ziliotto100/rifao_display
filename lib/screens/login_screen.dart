import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import 'admin_screen.dart';
import 'display_screen.dart';

enum _Stage { checking, form, blocked, expiredOffline }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Stage _stage = _Stage.checking;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _obscure = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final result = await AuthService.resolveSavedSession();
    if (!mounted) return;
    switch (result) {
      case SessionResult.ok:
        _goToApp();
        break;
      case SessionResult.blocked:
        setState(() => _stage = _Stage.blocked);
        break;
      case SessionResult.expiredOffline:
        setState(() => _stage = _Stage.expiredOffline);
        break;
      case SessionResult.needsLogin:
        await _prefillRememberedCredentials();
        if (!mounted) return;
        setState(() => _stage = _Stage.form);
        break;
    }
  }

  /// Preenche e-mail/senha se a pessoa marcou "Lembrar-me" numa vez
  /// anterior — assim só precisa clicar em "Entrar", sem digitar de novo.
  Future<void> _prefillRememberedCredentials() async {
    final saved = await AuthService.getRememberedCredentials();
    if (saved == null || !mounted) return;
    final (email, password) = saved;
    _emailController.text = email;
    _passwordController.text = password;
  }

  void _goToApp() {
    final isAdmin = AuthService.currentSession?.role == 'admin';
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isAdmin ? const AdminScreen() : const DisplayScreen(),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await AuthService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      if (result == SessionResult.ok) {
        if (_rememberMe) {
          await AuthService.saveRememberedCredentials(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } else {
          await AuthService.clearRememberedCredentials();
        }
        if (!mounted) return;
        _goToApp();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.darkGreen,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_stage) {
      case _Stage.checking:
        return const Center(
          child: CircularProgressIndicator(color: BrandColors.gold),
        );
      case _Stage.blocked:
        return _MessageCard(
          icon: Icons.lock_outline,
          title: 'Acesso bloqueado',
          message:
              'O acesso da sua comunidade está bloqueado no momento. Fale '
              'com o suporte pra regularizar.',
          buttonLabel: 'Tentar outro login',
          onPressed: () async {
            await AuthService.signOut();
            if (mounted) setState(() => _stage = _Stage.form);
          },
        );
      case _Stage.expiredOffline:
        return _MessageCard(
          icon: Icons.wifi_off,
          title: 'Sem internet',
          message:
              'Faz tempo que este computador não se conecta à internet pra '
              'confirmar seu acesso. Conecte-se e tente de novo.',
          buttonLabel: 'Tentar de novo',
          onPressed: _checkSavedSession,
        );
      case _Stage.form:
        return _buildForm();
    }
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 110,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Entrar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Login da sua comunidade pra liberar o rifão',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'E-mail',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: BrandColors.gold),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          style: const TextStyle(color: Colors.white),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Senha',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: BrandColors.gold),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE0A0A0), fontSize: 13),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                activeColor: BrandColors.gold,
                checkColor: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: const Text(
                  'Lembrar e-mail e senha neste computador',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text('Entrar'),
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: BrandColors.gold, size: 40),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.gold,
            foregroundColor: Colors.black,
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
