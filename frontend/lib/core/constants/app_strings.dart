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
      'quote':
          'Almost everything will work again if you unplug it for a few minutes, including you.',
      'author': 'Anne Lamott',
    },
    {
      'quote': 'In the middle of difficulty lies opportunity.',
      'author': 'Albert Einstein',
    },
    {
      'quote':
          'The present moment is filled with joy and happiness. If you are attentive, you will see it.',
      'author': 'Thich Nhat Hanh',
    },
    {
      'quote':
          'Within you, there is a stillness and a sanctuary to which you can retreat at any time.',
      'author': 'Hermann Hesse',
    },
    {
      'quote':
          'Feelings come and go like clouds in a windy sky. Conscious breathing is my anchor.',
      'author': 'Thich Nhat Hanh',
    },
    {
      'quote':
          'You cannot always control what goes on outside. But you can always control what goes on inside.',
      'author': 'Wayne Dyer',
    },
    {
      'quote':
          'Peace comes from within. Do not seek it without.',
      'author': 'Buddha',
    },
    {
      'quote':
          'Look at the trees, look at the birds, look at the clouds, look at the stars… and if you have eyes you will see that the whole existence is joyful.',
      'author': 'Osho',
    },
    {
      'quote':
          'Let go of the battle. Breathe quietly and let it be. Let your body relax and your heart soften.',
      'author': 'Jack Kornfield',
    },
    {
      'quote':
          'Give yourself the permission to pause, breathe, and begin again with gentleness.',
      'author': 'Mindful Living',
    },
    {
      'quote':
          'The soul should always stand ajar, ready to welcome the ecstatic experience.',
      'author': 'Emily Dickinson',
    },
  ];

  /// Returns a daily rotated quote based on the day of the year.
  static Map<String, String> get quoteOfTheDay {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return dailyQuotes[dayOfYear % dailyQuotes.length];
  }
}
