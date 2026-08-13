import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/brand_colors.dart';
import 'display_screen.dart';
import 'login_screen.dart';

/// Painel de administração — só quem loga com role "admin" chega aqui
/// (ver login_screen.dart). Deixa liberar/bloquear cada comunidade e
/// cadastrar comunidades novas, sem precisar abrir o Console do Firebase.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<OperatorInfo>? _operators;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AuthService.listOperators();
      if (!mounted) return;
      setState(() {
        _operators = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleActive(OperatorInfo op) async {
    // Atualiza a lista na hora (otimista) e desfaz se der erro, pra não
    // deixar o toggle "travado" esperando a rede.
    final novoStatus = !op.active;
    setState(() {
      _operators = _operators!
          .map(
            (o) => o.uid == op.uid
                ? OperatorInfo(
                    uid: o.uid,
                    community: o.community,
                    active: novoStatus,
                    expiresAt: o.expiresAt,
                  )
                : o,
          )
          .toList();
    });
    try {
      await AuthService.setOperatorActive(op.uid, novoStatus);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _operators = _operators!
            .map(
              (o) => o.uid == op.uid
                  ? OperatorInfo(
                      uid: o.uid,
                      community: o.community,
                      active: op.active,
                      expiresAt: o.expiresAt,
                    )
                  : o,
            )
            .toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openRenewDialog(OperatorInfo op) async {
    final renewed = await showDialog<bool>(
      context: context,
      builder: (context) => _RenewAccessDialog(operator: op),
    );
    if (renewed == true) _load();
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateOperatorDialog(),
    );
    if (created == true) _load();
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthService.currentSession;
    return Scaffold(
      backgroundColor: BrandColors.darkGreen,
      appBar: AppBar(
        backgroundColor: BrandColors.darkGreen,
        elevation: 0,
        title: const Text('Painel de admin'),
        actions: [
          IconButton(
            tooltip: 'Ir pro sorteio (usando sua conta)',
            icon: const Icon(Icons.confirmation_number_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DisplayScreen())),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: BrandColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Nova comunidade'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: BrandColors.gold,
        child: _buildBody(session),
      ),
    );
  }

  Widget _buildBody(AuthSession? session) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.gold),
      );
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _load,
              child: const Text('Tentar de novo'),
            ),
          ),
        ],
      );
    }

    final operators = _operators ?? [];
    if (operators.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'Nenhuma comunidade cadastrada ainda.\nToque em "Nova comunidade" pra começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: operators.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final op = operators[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                activeColor: BrandColors.gold,
                value: op.active,
                onChanged: (_) => _toggleActive(op),
                title: Text(
                  op.community,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _statusLabel(op),
                  style: TextStyle(color: _statusColor(op), fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openRenewDialog(op),
                      icon: const Icon(Icons.event_available, size: 18),
                      label: const Text('Validade'),
                      style: TextButton.styleFrom(
                        foregroundColor: BrandColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(OperatorInfo op) {
    if (!op.active) return 'Bloqueada manualmente';
    if (op.expiresAt == null) return 'Liberada · sem prazo de validade';
    final days = op.daysRemaining!;
    if (days < 0) return 'Acesso vencido';
    if (days == 0) return 'Liberada · vence hoje';
    return 'Liberada · vence em $days dia${days == 1 ? '' : 's'}';
  }

  Color _statusColor(OperatorInfo op) {
    if (!op.active || op.isExpired) return Colors.redAccent;
    if (op.expiresAt != null && op.daysRemaining! <= 5)
      return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}

class _CreateOperatorDialog extends StatefulWidget {
  const _CreateOperatorDialog();

  @override
  State<_CreateOperatorDialog> createState() => _CreateOperatorDialogState();
}

class _CreateOperatorDialogState extends State<_CreateOperatorDialog> {
  final _communityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int? _selectedDays = 30; // padrão: 30 dias. null = sem prazo de validade.
  bool _loading = false;
  String? _error;

  static const _dayOptions = [1, 7, 30, 365];

  Future<void> _submit() async {
    final community = _communityController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (community.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Preencha todos os campos.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.createOperator(
        community: community,
        email: email,
        password: password,
        days: _selectedDays,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BrandColors.darkGreen,
      title: const Text(
        'Nova comunidade',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _communityController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nome da comunidade',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'E-mail de login',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Senha (mín. 6 caracteres)',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dias de acesso',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _dayOptions)
                  ChoiceChip(
                    label: Text('${d}d'),
                    selected: _selectedDays == d,
                    onSelected: (_) => setState(() => _selectedDays = d),
                    selectedColor: BrandColors.gold,
                    labelStyle: TextStyle(
                      color: _selectedDays == d ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white.withOpacity(0.06),
                  ),
                ChoiceChip(
                  label: const Text('Sem prazo'),
                  selected: _selectedDays == null,
                  onSelected: (_) => setState(() => _selectedDays = null),
                  selectedColor: BrandColors.gold,
                  labelStyle: TextStyle(
                    color: _selectedDays == null
                        ? Colors.black
                        : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.06),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }
}

class _RenewAccessDialog extends StatefulWidget {
  final OperatorInfo operator;
  const _RenewAccessDialog({required this.operator});

  @override
  State<_RenewAccessDialog> createState() => _RenewAccessDialogState();
}

class _RenewAccessDialogState extends State<_RenewAccessDialog> {
  int? _selectedDays = 30;
  bool _loading = false;
  String? _error;

  static const _dayOptions = [1, 7, 30, 365];

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.setOperatorExpiry(widget.operator.uid, _selectedDays);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final op = widget.operator;
    return AlertDialog(
      backgroundColor: BrandColors.darkGreen,
      title: Text(
        'Validade — ${op.community}',
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            op.expiresAt == null
                ? 'Hoje: sem prazo de validade definido.'
                : 'Hoje: vence em ${op.daysRemaining} dia(s).',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          const Text(
            'Renovar a partir de hoje por:',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _dayOptions)
                ChoiceChip(
                  label: Text('${d}d'),
                  selected: _selectedDays == d,
                  onSelected: (_) => setState(() => _selectedDays = d),
                  selectedColor: BrandColors.gold,
                  labelStyle: TextStyle(
                    color: _selectedDays == d ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.06),
                ),
              ChoiceChip(
                label: const Text('Sem prazo'),
                selected: _selectedDays == null,
                onSelected: (_) => setState(() => _selectedDays = null),
                selectedColor: BrandColors.gold,
                labelStyle: TextStyle(
                  color: _selectedDays == null ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white.withOpacity(0.06),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
