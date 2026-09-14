/// App-wide string constants, prompts, and inspirational quotes.
class AppStrings {
  AppStrings._();

  static const String appName = 'Daily Reflection';
  static const String welcomeSubtitle = 'Welcome back to Daily Reflection.';

  // Journal CTAs and Prompts
  static const String writeJournalPrompt = "What's on your mind?";
  static const String writeJournalSubtitle =
      'Write freely anytime. Capture your thoughts, feelings, or moments from your day.';
  static const String writeButtonLabel = 'Write Entry';

  // Legacy Question Prompts (preserved for reading historical guided entries)
  static const Map<int, String> questionPrompts = {
    1: 'What are 7 things I am grateful for today?',
    2: 'What are 7 good things I noticed today that I might normally overlook?',
    3: 'What are 7 positive things I did today—for myself or someone else?',
    4: 'What are 7 moments today when I was fully present?',
    5: 'What are 7 things I could have done better today?',
    6: 'What are 7 things I learned about myself today?',
    7: 'What are 7 things I will intentionally do differently tomorrow?',
  };

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
