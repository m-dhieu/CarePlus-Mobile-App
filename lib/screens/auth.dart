import 'package:flutter/material.dart';
import 'forgot_password.dart';
import 'home.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // track active auth tab
  bool isLoginTab = true;

  // track hover state for forgot pass link
  bool isForgotPasswordHovered = false;

  // control pass visibility
  bool _hideLoginPassword = true;
  bool _hideSignUpPassword = true;
  bool _hideConfirmPassword = true;

  // form keys
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();

  // login controllers
  final TextEditingController _loginPhoneController =
      TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // sign up controllers
  final TextEditingController _fullNameController =
      TextEditingController();
  final TextEditingController _signUpPhoneController =
      TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // theme colors
  final Color primaryTeal = const Color(0xFF2E938A);
  final Color bgLight = const Color(0xFFF1FAF9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // logo header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Care',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.add_box_rounded,
                    size: 38,
                    color: primaryTeal,
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // auth tab selector
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: primaryTeal,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [

                    // login tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isLoginTab = true;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isLoginTab
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: isLoginTab
                                  ? primaryTeal
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // sign up tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isLoginTab = false;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !isLoginTab
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              color: !isLoginTab
                                  ? primaryTeal
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // auth content card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isLoginTab
                    ? _buildLoginView()
                    : _buildSignUpView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

    // login subview
  Widget _buildLoginView() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // login heading
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // phone number
          _buildInputField(
            controller: _loginPhoneController,
            label: 'Phone Number',
            hint: '78X XXX XXX',
            keyboardType: TextInputType.phone,
            prefixText: '+250 ',
            autofillHints: const [
              AutofillHints.telephoneNumber,
            ],
            validator: _validatePhoneNumber,
          ),

          const SizedBox(height: 20),

          // pass
          _buildInputField(
            controller: _loginPasswordController,
            label: 'Password',
            hint: 'Enter your password',
            isObscure: _hideLoginPassword,
            autofillHints: const [
              AutofillHints.password,
            ],
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _hideLoginPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _hideLoginPassword = !_hideLoginPassword;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          // forgot pass link
          Align(
            alignment: Alignment.centerRight,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                setState(() {
                  isForgotPasswordHovered = true;
                });
              },
              onExit: (_) {
                setState(() {
                  isForgotPasswordHovered = false;
                });
              },
              child: GestureDetector(
                onTap: () =>
                    _navigateToForgotPasswordFlow(context),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isForgotPasswordHovered
                        ? primaryTeal
                        : Colors.black54,
                    decoration: TextDecoration.underline,
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),
            ),
          ),

          const SizedBox(height: 35),

          // login button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_loginFormKey.currentState!.validate()) {

                  /*
                  for backend;
                  1 verify user's phone number
                  2 authenticate pass
                  3 retrieve user profile
                  4 create login session
                  5 nav to Home

                  eg;
                  await AuthService.login(
                    phoneNumber:
                        '+250${_loginPhoneController.text}',
                    password:
                        _loginPasswordController.text,
                  );

                  if (success) {
                    ...
                  }
                  */

                  // temp prototype nav
                  _navigateToHomeDirectly(context);
                }
              },
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

    // create account subview
  Widget _buildSignUpView() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // heading
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // full name
          _buildInputField(
            controller: _fullNameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // phone number
          _buildInputField(
            controller: _signUpPhoneController,
            label: 'Phone Number',
            hint: '78X XXX XXX',
            keyboardType: TextInputType.phone,
            prefixText: '+250 ',
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.telephoneNumber,
            ],
            validator: _validatePhoneNumber,
          ),

          const SizedBox(height: 18),

          // pass
          _buildInputField(
            controller: _signUpPasswordController,
            label: 'Password',
            hint: 'Create a password',
            isObscure: _hideSignUpPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _hideSignUpPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _hideSignUpPassword = !_hideSignUpPassword;
                });
              },
            ),
          ),

          const SizedBox(height: 18),

          // confirm pass
          _buildInputField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            isObscure: _hideConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }

              if (value != _signUpPasswordController.text) {
                return 'Passwords do not match';
              }

              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _hideConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _hideConfirmPassword = !_hideConfirmPassword;
                });
              },
            ),
          ),

          const SizedBox(height: 35),

          // create account button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_signUpFormKey.currentState!.validate()) {

                  /*
                  for backend;
                  1 check whether phone number already exists
                  2 create new user account
                  3 save user's info
                  4 create login session
                  5 nav to Home

                  eg;
                  await AuthService.register(
                    fullName: _fullNameController.text,
                    phoneNumber:
                        '+250${_signUpPhoneController.text}',
                    password:
                        _signUpPasswordController.text,
                  );

                  if (success) {
                    ...
                  }
                  */

                  // temp prototype nav
                  _navigateToHomeDirectly(context);
                }
              },
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

    // helper component for text input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool isObscure = false,
    String? prefixText,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: primaryTeal.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: isObscure,
          autofillHints: autofillHints,
          validator: validator,
          maxLength: keyboardType == TextInputType.phone ? 9 : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            counterText: '',
            hintStyle: const TextStyle(
              color: Colors.black38,
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: primaryTeal,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // validate Rwandan phone numbers
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    if (!RegExp(r'^(72|73|78|79)\d{7}$').hasMatch(value.trim())) {
      return 'Enter a valid Rwandan phone number';
    }

    return null;
  }

  // validate passwords
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // nav to forgot pass
  void _navigateToForgotPasswordFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  // nav to Home
  void _navigateToHomeDirectly(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    // login controllers
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();

    // sign up controllers
    _fullNameController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }
}

