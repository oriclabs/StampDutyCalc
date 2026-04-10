import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_mode_provider.dart';
import '../services/onboarding_service.dart';
import '../widgets/mode_picker.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  UserMode _selectedMode = UserMode.simple;

  Future<void> _finish() async {
    await context.read<UserModeProvider>().setMode(_selectedMode);
    await OnboardingService.markCompleted();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),

            // Slides
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  // Slide 1: Welcome
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 72,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Welcome to Vehicle Calculator',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Stamp duty, on-road costs, finance, and more for Australia & New Zealand. Free, accurate, always up to date.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Slide 2: Mode picker
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Who are you?',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pick a mode that fits how you use the app. You can change this anytime in settings.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ModePicker(
                          selected: _selectedMode,
                          onChanged: (mode) =>
                              setState(() => _selectedMode = mode),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Next / Get Started
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: FilledButton.icon(
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                label: Text(isLast ? 'Get Started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
