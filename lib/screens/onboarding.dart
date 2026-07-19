import 'package:flutter/material.dart';
import 'auth.dart'; 

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // theme colors
  final Color primaryTeal = const Color(0xFF2E938A);
  final Color bgLight = const Color(0xFFF1FAF9);

  // onboarding content data
  final List<Map<String, String>> onboardingData = const [
    {
      "title": "Welcome to Care+",
      "desc":
          "Your health companion. Access informed medical care and track your wellness journey seamlessly.",
    },
    {
      "title": "Inform Your Doctors",
      "desc":
          "Update your doctors with the latest information and access informed consultations instantly.",
    },
    {
      "title": "Secure Medical Records",
      "desc":
          "Keep your prescriptions, lab results, and health history safely stored and accessible anywhere.",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // logo branding
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
              child: Row(
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
            ),

            // pageView for content carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // visual placeholder
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          index == 0
                              ? Icons.local_hospital_outlined
                              : index == 1
                                  ? Icons.healing_outlined
                                  : Icons.verified_user_outlined,
                          size: 80,
                          color: primaryTeal.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Text(
                        onboardingData[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        onboardingData[index]["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // indicators & nav button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // dot indicators showing current page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryTeal
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // nav button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_currentPage < onboardingData.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        } else {
                          // nav to auth
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(),
                            ),
                          );
                        }
                      },
                      child: Text(
                        _currentPage == onboardingData.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}