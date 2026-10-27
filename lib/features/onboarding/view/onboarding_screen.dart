import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool _isNavigating = false;

  static const Color blue = Color(0xFF1769FF);
  static const Color navy = Color(0xFF102A56);

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Home Repairs Made Easy',
      description:
          'Request trusted technicians for fan, motor, '
          'and appliance repairs right at your doorstep.',
      icon: Icons.home_repair_service_rounded,
      label: 'RELIABLE HOME SERVICES',
      color: Color(0xFFE7EFFF),
    ),
    _OnboardingData(
      title: 'Know When They Arrive',
      description:
          'Track your assigned technician and find your '
          'home location easily with GPS and maps.',
      icon: Icons.location_on_rounded,
      label: 'GPS LOCATION TRACKING',
      color: Color(0xFFE3F6F2),
    ),
    _OnboardingData(
      title: 'Track Every Update',
      description:
          'Follow your request from technician assignment '
          'to arrival, repair, and completion.',
      icon: Icons.task_alt_rounded,
      label: 'SERVICE STATUS UPDATES',
      color: Color(0xFFFFF0DF),
    ),
  ];

  Future<void> _finishOnboarding() async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save permanently on this device.
      await prefs.setBool('hasSeenOnboarding', true);

      if (!mounted) return;

      // Replace onboarding so Back won't reopen it.
      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isNavigating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to continue. Please try again.')),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.handyman_rounded, color: blue, size: 27),
                  const SizedBox(width: 9),
                  const Text(
                    'Fsm',
                    style: TextStyle(
                      color: navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isNavigating ? null : _finishOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Swipeable pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        // Illustration
                        Expanded(
                          flex: 6,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: page.color,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  top: 30,
                                  right: 28,
                                  child: _decorativeCircle(45),
                                ),
                                Positioned(
                                  bottom: 45,
                                  left: 25,
                                  child: _decorativeCircle(28),
                                ),
                                Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: blue.withValues(alpha: 0.08),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    page.icon,
                                    size: 100,
                                    color: blue,
                                  ),
                                ),
                                Positioned(
                                  bottom: 28,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      page.label,
                                      style: const TextStyle(
                                        color: navy,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Heading
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 27,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: navy,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Description
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Animated page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 27 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? blue
                        : const Color(0xFFD7E0EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 22),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isNavigating ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: _isNavigating
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final String label;
  final Color color;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.label,
    required this.color,
  });
}
