import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState(){
    super.initState();
    _loadSavedEmail();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose(){
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() => _isLoading = true);




    final user = await authService.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en el login. Verifica tus credenciales.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // El AuthWrapper manejará la navegación automáticamente
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: _controller.isCompleted ? 1: 0.8,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.shopping_bag,
                              size: 60,
                              color: Colors.blue[700]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Calzados Luciana',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 40),

                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32 ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Correo Electronico',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 25),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword, // 👈 usa la variable
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: IconButton( // 👈 agrega el ojo
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: Colors.blue.shade700,
                                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                  ),
                                  const Text('Recordar correo'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _loginWithEmail,
                                  child: const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                              fontSize: 17,
                              color: Colors.black),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child :const Text(
                          'Crear usuario',
                          style: TextStyle(
                              fontSize: 17,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ),
        ),
      ),
    );
  }
}