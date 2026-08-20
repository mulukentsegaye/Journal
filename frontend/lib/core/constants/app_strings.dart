/// App-wide string constants, prompts, and inspirational quotes.
class AppStrings {
  AppStrings._();

  static const String appName = 'Daily Reflection';
  static const String welcomeSubtitle = 'Welcome back to your quiet space.';

  // Reflection CTA
  static const String startReflection = "Start Today's Reflection →";
  static const String reflectionPromptTitle = "Today's Reflection";
  static const String reflectionPromptDesc =
      'Ground your thoughts. Taking just 5 minutes tonight will help clear your mind for rest.';
  static const String reflectionOpenNote =
      'Your evening reflection typically opens at 6:00 PM.';

  // Quotes pool
  static const List<Map<String, String>> dailyQuotes = [
    {
      'quote': 'Quiet the mind and the soul will speak.',
      'author': 'Ma Jaya Sati Bhagavati',
    },
    {
      'quote': 'Almost everything will work again if you unplug it for a few minutes, including you.',
      'author': 'Anne Lamott',
    },
    {
      'quote': 'In the middle of difficulty lies opportunity.',
      'author': 'Albert Einstein',
    },
    {
      'quote': 'The present moment is filled with joy and happiness. If you are attentive, you will see it.',
      'author': 'Thich Nhat Hanh',
    },
  ];
}
