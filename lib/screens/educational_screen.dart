import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'article_detail_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/coach_mark_overlay.dart';
import '../services/tutorial_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ArticleColor {
  final Color surface;
  final Color accent;
  final Color deep;
  const ArticleColor({
    required this.surface,
    required this.accent,
    required this.deep,
  });
}

class ArticleSection {
  final String heading;
  final String body;
  const ArticleSection({required this.heading, required this.body});
}

class ArticleCallout {
  final String label;
  final String text;
  final String colorKey;
  const ArticleCallout({
    required this.label,
    required this.text,
    required this.colorKey,
  });
}

class Article {
  final int id;
  final String category;
  final String tag;
  final String colorKey;
  final String emoji;
  final String readTime;
  final String title;
  final String desc;
  final String intro;
  final String pullQuote;
  final List<ArticleSection> sections;
  final ArticleCallout callout;
  final List<String> pills;
  final String sourceUrl;
  final String sourceName;

  const Article({
    required this.id,
    required this.category,
    required this.tag,
    required this.colorKey,
    required this.emoji,
    required this.readTime,
    required this.title,
    required this.desc,
    required this.intro,
    required this.pullQuote,
    required this.sections,
    required this.callout,
    required this.pills,
    required this.sourceUrl,
    required this.sourceName,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOUR PALETTE
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, ArticleColor> kArticleColors = {
  'pink': ArticleColor(
    surface: Color(0xFFFDE8EF),
    accent: Color(0xFFE96A8F),
    deep: Color(0xFF9C3558),
  ),
  'blue': ArticleColor(
    surface: Color(0xFFE4EDFA),
    accent: Color(0xFF84B2E9),
    deep: Color(0xFF1B5FA8),
  ),
  'purple': ArticleColor(
    surface: Color(0xFFF3E8FA),
    accent: Color(0xFFA865C0),
    deep: Color(0xFF6B3280),
  ),
  'green': ArticleColor(
    surface: Color(0xFFE2F5ED),
    accent: Color(0xFF3BAF7E),
    deep: Color(0xFF1E6647),
  ),
  'amber': ArticleColor(
    surface: Color(0xFFFEF0E2),
    accent: Color(0xFFD4843A),
    deep: Color(0xFF8A4D10),
  ),
};

ArticleColor colorOf(String key) =>
    kArticleColors[key] ?? kArticleColors['blue']!;

// ─────────────────────────────────────────────────────────────────────────────
// ARTICLE DATA  —  5 articles × 5 categories = 25 total
// ─────────────────────────────────────────────────────────────────────────────

const List<Article> kArticles = [

  // ══════════════════════════════════════════
  //  CYCLE  (5)
  // ══════════════════════════════════════════

  Article(
    id: 0,
    category: 'Cycle',
    tag: 'Cycle basics',
    colorKey: 'pink',
    emoji: '',
    readTime: '5 min read',
    title: 'Understanding your menstrual cycle',
    desc: 'Your cycle is a monthly hormonal story. Here\'s how to actually read it.',
    intro:
        'Most of us were taught that a period is just bleeding once a month. But your cycle is a dynamic, four-phase hormonal event that shapes your energy, mood, skin, and brain performance every single day — not just the days you bleed.',
    pullQuote:
        'Your period is just one week of your cycle. The other three weeks matter just as much.',
    sections: [
      ArticleSection(
        heading: 'The four phases, simply explained',
        body:
            'Phase 1 — Menstrual (days 1–5): your uterine lining sheds. Hormones are at their lowest. Rest is productive, not lazy.\n\nPhase 2 — Follicular (days 6–13): estrogen rises. Your brain sharpens, energy climbs, and you feel like yourself again.\n\nPhase 3 — Ovulation (around day 14): estrogen peaks. You\'re at your most confident, social, and physically capable.\n\nPhase 4 — Luteal (days 15–28): progesterone rises. You slow down, turn inward, and may notice PMS symptoms near the end.',
      ),
      ArticleSection(
        heading: 'Why 28 days is a myth',
        body:
            'A healthy cycle is anywhere from 21 to 35 days. What matters is your own pattern — consistency within your cycle matters far more than matching a textbook number. Significant changes from your norm are worth tracking and discussing with a doctor.',
      ),
      ArticleSection(
        heading: 'What your period is actually telling you',
        body:
            'Flow volume, color, clotting, and pain level are all data. Very light periods can indicate low estrogen. Very heavy ones may suggest fibroids or hormonal imbalance. Brown blood at the start or end is older blood — usually normal. Bright red with large clots consistently warrants a doctor visit.',
      ),
    ],
    callout: ArticleCallout(
      label: 'FemCycle tip',
      colorKey: 'blue',
      text:
          'Log at least 3 full cycles before drawing conclusions. The prediction model improves significantly with each cycle you record.',
    ),
    pills: ['Estrogen', 'Progesterone', 'LH surge', 'Ovulation', 'Menstrual phases'],
    sourceUrl: 'https://my.clevelandclinic.org/health/articles/10132-menstrual-cycle',
    sourceName: 'Cleveland Clinic',
  ),

  Article(
    id: 1,
    category: 'Cycle',
    tag: 'Cycle basics',
    colorKey: 'pink',
    emoji: '',
    readTime: '4 min read',
    title: 'Ovulation signs and your fertile window',
    desc: 'Your body announces ovulation clearly. Here\'s how to read the signals.',
    intro:
        'Ovulation is the central event of your cycle — everything else builds toward it or winds down from it. Whether you\'re tracking for fertility or simply want to understand your own body, knowing when you ovulate changes how you experience your cycle.',
    pullQuote:
        'Your body communicates ovulation clearly, consistently, every cycle. You just need to know what to listen for.',
    sections: [
      ArticleSection(
        heading: 'The fertile window explained',
        body:
            'You\'re fertile for about 6 days per cycle: the 5 days before ovulation and the day of ovulation itself. This window exists because sperm can survive in the reproductive tract for up to 5 days. The egg itself survives only 12–24 hours after release.',
      ),
      ArticleSection(
        heading: 'What your body shows you',
        body:
            'Cervical mucus is your most reliable real-time indicator. Around ovulation, it becomes clear, slippery, and stretchy — like raw egg whites. Roughly one in five women feels mittelschmerz — a one-sided pelvic ache when the egg is released.',
      ),
      ArticleSection(
        heading: 'Basal body temperature',
        body:
            'Your resting temperature rises about 0.2–0.5°C after ovulation due to progesterone. Tracking it every morning before getting up confirms ovulation has occurred. Combined with cervical mucus observation, it becomes a powerful fertility awareness tool.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Prediction accuracy',
      colorKey: 'blue',
      text:
          'FemCycle estimates your fertile window based on your logged history. After 3 consistent cycles, predictions become significantly more accurate.',
    ),
    pills: ['LH surge', 'Fertile window', 'Cervical mucus', 'Basal temperature', 'Mittelschmerz'],
    sourceUrl:
        'https://helloclue.com/articles/cycle-a-z/the-menstrual-cycle-more-than-just-the-period',
    sourceName: 'Clue',
  ),

  Article(
    id: 2,
    category: 'Cycle',
    tag: 'Cycle basics',
    colorKey: 'pink',
    emoji: '',
    readTime: '4 min read',
    title: 'The luteal phase: your body\'s wind-down',
    desc: 'Understanding the second half of your cycle — and why PMS shows up.',
    intro:
        'The luteal phase is the least understood and most complained-about part of the menstrual cycle. Understanding what\'s happening hormonally during these two weeks changes how you relate to your body in its most misunderstood phase.',
    pullQuote:
        'PMS is not a character flaw. It\'s a predictable hormonal event — and that makes it manageable.',
    sections: [
      ArticleSection(
        heading: 'What happens in the luteal phase',
        body:
            'After ovulation, the empty follicle transforms into the corpus luteum, which produces progesterone. This hormone prepares the uterine lining for a potential pregnancy. If no fertilization occurs, the corpus luteum breaks down, progesterone falls, and menstruation begins.',
      ),
      ArticleSection(
        heading: 'Why you feel slower and more tired',
        body:
            'Progesterone has a calming, slightly sedating effect. It raises your basal body temperature, which is why many women feel warmer and fatigue more easily. Your metabolism also increases by about 5–10% in the luteal phase, which explains why you\'re genuinely more hungry.',
      ),
      ArticleSection(
        heading: 'Managing PMS in the luteal phase',
        body:
            'Consistent sleep (7–9 hours), magnesium-rich foods, reduced caffeine and salt, and daily moderate movement are the most evidence-backed strategies. Tracking your luteal symptoms across 3 cycles helps identify your personal pattern and which days tend to be hardest.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Important',
      colorKey: 'pink',
      text:
          'If luteal phase symptoms significantly disrupt your life every cycle, speak to a doctor. PMDD (Premenstrual Dysphoric Disorder) is real and highly treatable.',
    ),
    pills: ['Progesterone', 'Corpus luteum', 'PMS', 'PMDD', 'Basal temperature'],
    sourceUrl: 'https://my.clevelandclinic.org/health/articles/24417-luteal-phase',
    sourceName: 'Cleveland Clinic',
  ),

  Article(
    id: 3,
    category: 'Cycle',
    tag: 'Cycle basics',
    colorKey: 'pink',
    emoji: '',
    readTime: '5 min read',
    title: 'Irregular periods: what\'s normal and what\'s not',
    desc: 'Not every variation in your cycle is a problem. Here\'s how to tell the difference.',
    intro:
        'Nearly every woman experiences some variation in her menstrual cycle at some point. Understanding the difference between natural fluctuation and a signal worth investigating is one of the most important things you can know about your cycle.',
    pullQuote:
        'A single irregular cycle is usually stress. A pattern of irregular cycles is a conversation worth having with your doctor.',
    sections: [
      ArticleSection(
        heading: 'What counts as irregular',
        body:
            'A cycle is considered irregular if it\'s consistently shorter than 21 days, longer than 35 days, or varies by more than 7–9 days from cycle to cycle. Missing periods for 3 or more consecutive months (when not pregnant) is called amenorrhea and always warrants medical evaluation.',
      ),
      ArticleSection(
        heading: 'Common causes of irregular cycles',
        body:
            'Stress is the most common cause — it elevates cortisol, which directly disrupts the hormonal signals that regulate ovulation. Other causes include significant weight changes, intense exercise, thyroid disorders, PCOS, perimenopause, and certain medications including hormonal contraceptives.',
      ),
      ArticleSection(
        heading: 'When to see a doctor',
        body:
            'See a doctor if cycles are consistently outside the 21–35 day range, if you have fewer than 8 periods per year, if you experience very heavy bleeding, or if you have severe pain that disrupts daily activities.',
      ),
    ],
    callout: ArticleCallout(
      label: 'FemCycle tip',
      colorKey: 'blue',
      text:
          'FemCycle tracks your cycle length over time and will alert you if a pattern of irregular cycles emerges — making it easier to bring specific data to a doctor\'s appointment.',
    ),
    pills: ['Amenorrhea', 'Irregular cycle', 'Cortisol', 'PCOS', 'Perimenopause'],
    sourceUrl:
        'https://my.clevelandclinic.org/health/diseases/14633-abnormal-menstruation-periods',
    sourceName: 'Cleveland Clinic',
  ),

  Article(
    id: 4,
    category: 'Cycle',
    tag: 'Cycle basics',
    colorKey: 'pink',
    emoji: '',
    readTime: '3 min read',
    title: 'How stress silently disrupts your period',
    desc: 'Stress is one of the most common — and most overlooked — causes of cycle disruption.',
    intro:
        'You\'ve probably heard that stress can affect your period. But the mechanism is more direct and more powerful than most people realize. Chronic stress doesn\'t just cause you to miss a period occasionally — it can fundamentally alter your hormonal environment month after month.',
    pullQuote:
        'Stress speaks directly to the hormones that regulate your cycle. Your body prioritizes survival over reproduction.',
    sections: [
      ArticleSection(
        heading: 'The cortisol–cycle connection',
        body:
            'When you\'re stressed, your adrenal glands release cortisol. High cortisol signals to the hypothalamus — the brain\'s hormonal control center — that the body is under threat. The hypothalamus then reduces production of GnRH, the hormone that triggers the chain of events leading to ovulation. The result: delayed, shortened, or skipped periods.',
      ),
      ArticleSection(
        heading: 'What kind of stress affects your cycle',
        body:
            'Both physical stress (intense exercise, rapid weight loss, illness, lack of sleep) and emotional stress (work pressure, relationship difficulties, grief, anxiety) can suppress the hypothalamic-pituitary-ovarian axis. Your body doesn\'t distinguish between types of threat — it simply responds to the cortisol signal.',
      ),
      ArticleSection(
        heading: 'How to protect your cycle during stressful times',
        body:
            'Prioritizing sleep, maintaining consistent eating patterns, and moderate (not excessive) exercise all protect the hormonal axis. Mindfulness practices — even 10 minutes daily — have been shown to reduce cortisol. If stress-related cycle disruption lasts more than 3 months, speak to a doctor.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Track your pattern',
      colorKey: 'blue',
      text:
          'Log your stress level daily in FemCycle alongside your cycle data. Over time, you\'ll see exactly how periods of high stress affect your cycle length and symptoms.',
    ),
    pills: ['Cortisol', 'Hypothalamus', 'GnRH', 'HPO axis', 'Amenorrhea'],
    sourceUrl:
        'https://health.clevelandclinic.org/can-stress-cause-you-to-skip-a-period',
    sourceName: 'Cleveland Clinic',
  ),

  // ══════════════════════════════════════════
  //  PCOS  (5)
  // ══════════════════════════════════════════

  Article(
    id: 5,
    category: 'PCOS',
    tag: 'PCOS',
    colorKey: 'purple',
    emoji: '',
    readTime: '6 min read',
    title: 'What is PCOS and how to manage it',
    desc: '6–12% of women have it. Most don\'t know until years later.',
    intro:
        'Polycystic Ovary Syndrome is one of the most common hormonal conditions affecting reproductive-age women — and one of the most delayed in diagnosis. The average woman waits over two years and sees multiple doctors before getting answers.',
    pullQuote:
        'PCOS is not a life sentence. With the right information, it\'s one of the most manageable hormonal conditions there is.',
    sections: [
      ArticleSection(
        heading: 'What\'s actually happening inside',
        body:
            'In PCOS, the ovaries produce excess androgens — male hormones like testosterone. This disrupts ovulation, causing eggs to remain as small fluid-filled follicles rather than being released. Insulin resistance is also present in 70–80% of women with PCOS, worsening the hormonal imbalance.',
      ),
      ArticleSection(
        heading: 'Signs that warrant a doctor conversation',
        body:
            'Fewer than 8 periods per year. Cycles consistently longer than 35 days. Acne along the jawline or back. Excess hair growth on the face, chest, or abdomen. Unexplained weight gain around the abdomen. Thinning scalp hair. Dark, velvety patches of skin in skin folds.',
      ),
      ArticleSection(
        heading: 'What genuinely helps',
        body:
            'A low-glycemic diet significantly improves insulin sensitivity. Just 150 minutes of moderate exercise per week has been shown to restore more regular ovulation in women with PCOS without any medication. Stress management and consistent sleep matter more than most people realize.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Important',
      colorKey: 'purple',
      text:
          'FemCycle detects irregular cycle patterns — not PCOS itself. A formal diagnosis requires a doctor, blood tests, and an ultrasound. Always consult a gynecologist for medical concerns.',
    ),
    pills: ['Androgens', 'Insulin resistance', 'Irregular cycles', 'Ovulation', 'Low-GI diet'],
    sourceUrl: 'https://www.medicalnewstoday.com/articles/323002',
    sourceName: 'Medical News Today',
  ),

  Article(
    id: 6,
    category: 'PCOS',
    tag: 'PCOS',
    colorKey: 'purple',
    emoji: '',
    readTime: '5 min read',
    title: 'Diet and lifestyle changes for PCOS',
    desc: 'No cure — but lifestyle changes are among the most effective interventions known.',
    intro:
        'Managing PCOS through lifestyle isn\'t a consolation prize for not having medication. Research consistently shows that diet and exercise modifications produce outcomes comparable to pharmaceutical interventions for improving cycle regularity and quality of life.',
    pullQuote:
        'Losing just 5–10% of body weight (if overweight) can restore ovulation and regular periods in women with PCOS.',
    sections: [
      ArticleSection(
        heading: 'Why diet matters so much in PCOS',
        body:
            'Insulin resistance is present in 70–80% of women with PCOS, even those at a healthy weight. When cells resist insulin, the pancreas produces more — and excess insulin directly stimulates the ovaries to produce more androgens. A low-glycemic diet reduces the insulin burden, which reduces androgen production, which improves ovulation.',
      ),
      ArticleSection(
        heading: 'What a low-GI diet actually looks like',
        body:
            'It\'s not a special diet — it\'s whole foods that digest slowly. Oats instead of cornflakes. Brown rice instead of white. Lentils, chickpeas, and beans as protein sources. Vegetables at every meal. It doesn\'t require eliminating carbohydrates — it means choosing carbohydrates that don\'t spike blood sugar sharply.',
      ),
      ArticleSection(
        heading: 'Exercise as medicine',
        body:
            '150 minutes of moderate aerobic exercise per week has been shown to significantly improve insulin sensitivity in women with PCOS within 12 weeks. Resistance training has an additive effect. The improvements translate directly to lower androgens and more regular ovulation, even without weight loss.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Work with a professional',
      colorKey: 'amber',
      text:
          'Lifestyle changes are powerful but work best when guided by a gynecologist, endocrinologist, or registered dietitian familiar with PCOS.',
    ),
    pills: ['Insulin resistance', 'Low-GI', 'Androgens', 'Cortisol', 'Exercise as medicine'],
    sourceUrl: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9841505/',
    sourceName: 'NIH / PubMed Central',
  ),

  Article(
    id: 7,
    category: 'PCOS',
    tag: 'PCOS',
    colorKey: 'purple',
    emoji: '',
    readTime: '4 min read',
    title: 'Inflammation, PCOS, and what to do about it',
    desc: 'Most women with PCOS also have chronic low-grade inflammation — and it matters.',
    intro:
        'Research increasingly shows that chronic low-grade inflammation is not just a side effect of PCOS — it may be one of its drivers. Understanding the inflammation–PCOS link opens up new lifestyle strategies that go beyond just managing insulin.',
    pullQuote:
        'Inflammation and PCOS feed each other. Breaking that cycle starts with what you eat, how you move, and how you sleep.',
    sections: [
      ArticleSection(
        heading: 'How inflammation worsens PCOS',
        body:
            'Inflammatory markers are consistently elevated in women with PCOS, regardless of weight. This chronic low-grade inflammation directly stimulates androgen production in the ovaries, worsens insulin resistance, and may contribute to the disrupted ovulation that characterizes the condition.',
      ),
      ArticleSection(
        heading: 'Anti-inflammatory foods for PCOS',
        body:
            'Fatty fish (salmon, sardines, mackerel), leafy greens, berries, olive oil, turmeric, walnuts, and avocado all have strong anti-inflammatory evidence. Processed foods, refined sugars, trans fats, and excessive red meat all promote inflammation and should be reduced where possible.',
      ),
      ArticleSection(
        heading: 'Sleep, stress, and inflammation',
        body:
            'Poor sleep and chronic stress are two of the most potent drivers of systemic inflammation. Even one night of poor sleep raises inflammatory markers measurably. For women with PCOS, prioritizing 7–9 hours of consistent sleep is a meaningful clinical intervention, not just good advice.',
      ),
    ],
    callout: ArticleCallout(
      label: 'A good rule of thumb',
      colorKey: 'green',
      text:
          'Eat a varied diet rich in vitamins, nutrients, and antioxidants. Focus on foods that nourish your body rather than eliminating entire food groups — sustainable change beats restriction every time.',
    ),
    pills: ['Inflammation', 'Antioxidants', 'Omega-3', 'Sleep quality', 'Cortisol'],
    sourceUrl: 'https://www.healthline.com/health/womens-health/inflammatory-pcos',
    sourceName: 'Healthline',
  ),

  Article(
    id: 8,
    category: 'PCOS',
    tag: 'PCOS',
    colorKey: 'purple',
    emoji: '',
    readTime: '5 min read',
    title: 'PCOS and mental health: the hidden connection',
    desc: 'Women with PCOS are significantly more likely to experience anxiety and depression.',
    intro:
        'PCOS is typically discussed in terms of its physical symptoms — irregular periods, acne, hair growth. But research consistently shows that its psychological impact is just as significant and far less addressed. Understanding this connection is essential to whole-person care.',
    pullQuote:
        'The hormonal imbalances of PCOS don\'t just affect your body. They directly affect your brain chemistry and emotional wellbeing.',
    sections: [
      ArticleSection(
        heading: 'The hormonal roots of PCOS-related depression',
        body:
            'Elevated androgens and insulin resistance both affect neurotransmitter function. Studies show that women with PCOS have significantly higher rates of depression and anxiety than the general population. This is not simply a reaction to the physical symptoms; it\'s driven by the same hormonal dysregulation.',
      ),
      ArticleSection(
        heading: 'Body image and PCOS',
        body:
            'Symptoms like weight gain, excess hair, acne, and thinning scalp hair disproportionately affect how women with PCOS experience their bodies. This can lead to disordered eating, social withdrawal, and avoidance of medical care — all of which worsen PCOS outcomes.',
      ),
      ArticleSection(
        heading: 'What helps',
        body:
            'Cognitive Behavioral Therapy (CBT) has the strongest evidence base for PCOS-related depression and anxiety. Regular aerobic exercise reduces both androgen levels and depressive symptoms simultaneously. Connecting with PCOS communities reduces isolation significantly.',
      ),
    ],
    callout: ArticleCallout(
      label: 'You are not alone',
      colorKey: 'blue',
      text:
          'Mental health struggles in PCOS are common, real, and treatable. If you\'re experiencing persistent anxiety or low mood, please speak with a healthcare provider. It\'s part of the condition, not a personal failing.',
    ),
    pills: ['Anxiety', 'Depression', 'Androgens', 'CBT', 'Body image'],
    sourceUrl: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9440853/',
    sourceName: 'NIH / PubMed Central',
  ),

  Article(
    id: 9,
    category: 'PCOS',
    tag: 'PCOS',
    colorKey: 'purple',
    emoji: '',
    readTime: '4 min read',
    title: 'Getting diagnosed with PCOS: what to expect',
    desc: 'PCOS is often missed for years. Here\'s how the diagnosis process actually works.',
    intro:
        'PCOS diagnosis is notoriously inconsistent. Many women visit multiple doctors before receiving a diagnosis, and many are dismissed for years. Understanding exactly how PCOS is diagnosed — and what you can bring to an appointment — can significantly speed up that process.',
    pullQuote:
        'You don\'t need to have cysts on your ovaries to have PCOS. The name is one of medicine\'s great misnomers.',
    sections: [
      ArticleSection(
        heading: 'The Rotterdam criteria',
        body:
            'PCOS is diagnosed when a person has at least two of the following three features: irregular or absent ovulation, elevated androgens (either on blood tests or through symptoms like excess hair or acne), and polycystic ovaries visible on ultrasound. You do not need all three.',
      ),
      ArticleSection(
        heading: 'What tests your doctor will run',
        body:
            'Blood tests will measure LH, FSH, testosterone, DHEAS, prolactin, thyroid function, fasting insulin, and glucose. A pelvic ultrasound will assess ovarian morphology. Your doctor may also check for other conditions that mimic PCOS, including thyroid disorders and adrenal issues.',
      ),
      ArticleSection(
        heading: 'How to prepare for your appointment',
        body:
            'Bring at least 3 months of cycle data — ideally logged in an app like FemCycle. Note your symptoms, their severity, and when they started. Write down your family history, as PCOS has a genetic component. Don\'t be afraid to ask for specific tests if your symptoms match PCOS.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Use your data',
      colorKey: 'purple',
      text:
          'Exporting your FemCycle cycle history gives your doctor a clear, objective picture of your patterns — much more useful than trying to recall cycle dates from memory during an appointment.',
    ),
    pills: ['Rotterdam criteria', 'LH', 'FSH', 'Testosterone', 'Ultrasound'],
    sourceUrl: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11767734/',
    sourceName: 'NIH / PubMed Central',
  ),

  // ══════════════════════════════════════════
  //  NUTRITION  (5)
  // ══════════════════════════════════════════

  Article(
    id: 10,
    category: 'Nutrition',
    tag: 'Nutrition',
    colorKey: 'green',
    emoji: '',
    readTime: '3 min read',
    title: 'Best foods to eat during your period',
    desc: 'Iron, omega-3s, and magnesium are your body\'s most useful tools right now.',
    intro:
        'The food choices you make during menstruation have a direct, measurable effect on cramp severity, energy levels, bloating, and mood. This isn\'t about eating perfectly — it\'s about giving your body a few targeted things it actually needs right now.',
    pullQuote: 'You lose iron, you lose energy. Replenish both with the same foods.',
    sections: [
      ArticleSection(
        heading: 'Start with iron',
        body:
            'Menstruation causes real blood loss — and with it, iron. Low iron means fatigue, brain fog, and breathlessness. Top up with spinach, lentils, pumpkin seeds, tofu, red meat, or fortified cereals. Always pair iron-rich foods with vitamin C (a squeeze of lemon, a handful of strawberries) to increase absorption by up to 300%.',
      ),
      ArticleSection(
        heading: 'Omega-3s reduce cramps directly',
        body:
            'Prostaglandins — hormone-like compounds — cause uterine contractions during your period. Omega-3 fatty acids competitively reduce prostaglandin production, which means fewer and less intense cramps. Salmon, sardines, walnuts, chia seeds, and flaxseed are your best sources.',
      ),
      ArticleSection(
        heading: 'What to cut back on',
        body:
            'Salt causes water retention and worsens bloating. Caffeine tightens blood vessels, which intensifies cramps and disrupts sleep. High-sugar foods cause blood sugar spikes and crashes that amplify mood swings. You don\'t need to eliminate any of these — just dialing them back during days 1–3 makes a real difference.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Research-backed tip',
      colorKey: 'green',
      text:
          'Dark chocolate (70%+ cacao) is legitimately helpful during your period — it\'s rich in iron, magnesium, and provides a mood boost without a sugar crash.',
    ),
    pills: ['Iron', 'Omega-3', 'Magnesium', 'Prostaglandins', 'Vitamin C'],
    sourceUrl: 'https://www.healthline.com/health/womens-health/what-to-eat-during-period',
    sourceName: 'Healthline',
  ),

  Article(
    id: 11,
    category: 'Nutrition',
    tag: 'Nutrition',
    colorKey: 'green',
    emoji: '',
    readTime: '2 min read',
    title: 'Staying hydrated during your cycle',
    desc: 'Drinking more water when bloated feels wrong. It\'s actually exactly right.',
    intro:
        'Hormonal shifts throughout your cycle directly affect how your body manages water. Strategic hydration can reduce bloating, improve energy, ease cramping, and stabilize mood across all four phases of your cycle.',
    pullQuote:
        'When you\'re bloated, your first instinct is to drink less. Your body needs the opposite.',
    sections: [
      ArticleSection(
        heading: 'Why bloating gets worse when dehydrated',
        body:
            'Estrogen and progesterone fluctuations cause your body to retain sodium in the luteal phase. Sodium pulls water into tissues, causing the puffy, heavy feeling of bloating. When you drink more water, you help flush excess sodium through the kidneys — which paradoxically reduces water retention.',
      ),
      ArticleSection(
        heading: 'How much, and what',
        body:
            'Aim for 2–2.5 liters of fluid daily, increasing slightly during menstruation. Ginger tea reduces nausea and has mild anti-inflammatory effects. Peppermint tea reduces bloating and cramping. Chamomile tea acts as a mild muscle relaxant and reduces menstrual pain.',
      ),
      ArticleSection(
        heading: 'Eat your water too',
        body:
            'Cucumbers are 96% water. Watermelon is 92%. Strawberries are 91%. These high-water foods contribute meaningfully to hydration and are naturally rich in potassium, which helps balance sodium and reduce bloating further.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Quick check',
      colorKey: 'green',
      text:
          'Look at your urine before you flush. Pale yellow means well-hydrated. Dark yellow means drink more. This is the most reliable real-time hydration indicator you have.',
    ),
    pills: ['Bloating', 'Electrolytes', 'Herbal tea', 'Water retention', 'Sodium balance'],
    sourceUrl: 'https://www.webmd.com/women/pms/features/diet-and-pms',
    sourceName: 'WebMD',
  ),

  Article(
    id: 12,
    category: 'Nutrition',
    tag: 'Nutrition',
    colorKey: 'green',
    emoji: '',
    readTime: '4 min read',
    title: 'Eating for each phase of your cycle',
    desc: 'Your nutritional needs genuinely shift across all four phases.',
    intro:
        'Eating the same way every week of your cycle is like wearing the same clothes year-round regardless of season. Your hormonal environment changes dramatically, and so do your nutritional needs, cravings, and digestive patterns.',
    pullQuote:
        'Cycle-aware eating isn\'t a diet. It\'s using food as a tool that works with your biology, not against it.',
    sections: [
      ArticleSection(
        heading: 'Menstrual phase: replenish',
        body:
            'Focus on iron (spinach, lentils, red meat), vitamin C to boost iron absorption, and magnesium (dark chocolate, nuts, seeds) to ease cramping. Warm, cooked foods are easier to digest. Reduce salt to minimize bloating. Avoid caffeine, which can worsen cramps and disrupt sleep.',
      ),
      ArticleSection(
        heading: 'Follicular and ovulation phase: build and energize',
        body:
            'Rising estrogen means your body absorbs and uses nutrients efficiently. Fermented foods (yogurt, kefir, kimchi) support estrogen metabolism in the gut. Around ovulation, zinc (pumpkin seeds, shellfish, chickpeas) supports healthy egg quality. Light, fresh foods feel natural and energizing.',
      ),
      ArticleSection(
        heading: 'Luteal phase: stabilize',
        body:
            'Complex carbohydrates (oats, quinoa, sweet potato) help maintain serotonin levels during the phase when they naturally dip. Calcium-rich foods reduce PMS symptoms measurably. B vitamins (especially B6 from bananas, turkey, salmon) support progesterone function and mood stability.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Note',
      colorKey: 'blue',
      text:
          'Cycle-aware eating works best as a gentle framework, not a rigid rulebook. Start by noticing your cravings across your cycle — they\'re often your body\'s way of asking for what it needs.',
    ),
    pills: ['Iron', 'Magnesium', 'Zinc', 'Serotonin', 'B vitamins'],
    sourceUrl: 'https://www.webmd.com/women/pms/what-is-pms',
    sourceName: 'WebMD',
  ),

  Article(
    id: 13,
    category: 'Nutrition',
    tag: 'Nutrition',
    colorKey: 'green',
    emoji: '',
    readTime: '3 min read',
    title: 'Calcium, magnesium, and B vitamins for PMS',
    desc: 'Three nutrients that clinical research consistently links to reduced PMS symptoms.',
    intro:
        'Of all the dietary approaches studied for PMS, three nutrients stand out with consistent clinical evidence: calcium, magnesium, and vitamin B6. Understanding what they do and how to get them from food gives you practical, evidence-based tools for every cycle.',
    pullQuote:
        'Women with higher calcium and B-vitamin intake from food have a significantly lower risk of PMS — not supplements, food.',
    sections: [
      ArticleSection(
        heading: 'Calcium',
        body:
            'Calcium has among the strongest evidence of any nutrient for PMS relief. Studies show that 1,000–1,200mg daily significantly reduces mood symptoms, bloating, cramps, and food cravings in the luteal phase. Get it from dairy, fortified plant milks, canned salmon with bones, broccoli, and kale.',
      ),
      ArticleSection(
        heading: 'Magnesium',
        body:
            'Magnesium supports over 300 enzymatic reactions in the body and plays a key role in muscle relaxation and neurotransmitter function. 400mg daily has been shown to reduce bloating, mood changes, and the anxiety associated with PMS. Best food sources: pumpkin seeds, almonds, dark chocolate, black beans, avocado, and leafy greens.',
      ),
      ArticleSection(
        heading: 'Vitamin B6',
        body:
            'B6 is involved in the production of serotonin and dopamine — the brain\'s primary mood regulators. Research shows women with higher B-vitamin intake from food have significantly lower PMS risk. Find it in salmon, chicken, turkey, bananas, potatoes, and fortified cereals.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Supplement note',
      colorKey: 'amber',
      text:
          'Before starting any supplement, speak to a doctor or pharmacist. Very large doses of B6 supplements can cause nerve damage over time. Food sources are always safer.',
    ),
    pills: ['Calcium', 'Magnesium', 'Vitamin B6', 'Serotonin', 'PMS relief'],
    sourceUrl: 'https://www.webmd.com/women/features/the-pms-free-diet',
    sourceName: 'WebMD',
  ),

  Article(
    id: 14,
    category: 'Nutrition',
    tag: 'Nutrition',
    colorKey: 'green',
    emoji: '',
    readTime: '4 min read',
    title: 'Anti-inflammatory eating for menstrual health',
    desc: 'Inflammation drives cramps, fatigue, and mood changes. Your diet can turn it down.',
    intro:
        'Inflammation is increasingly understood as a key driver of painful periods, severe PMS, and conditions like endometriosis and PCOS. An anti-inflammatory dietary pattern doesn\'t just reduce cramps — it changes the hormonal environment in which your cycle operates.',
    pullQuote:
        'Chronic low-grade inflammation amplifies every menstrual symptom you experience. Food is one of your most direct tools to reduce it.',
    sections: [
      ArticleSection(
        heading: 'How inflammation drives period pain',
        body:
            'During menstruation, the body releases prostaglandins — inflammatory compounds that cause the uterus to contract. Higher levels of prostaglandins correlate directly with more severe cramping. A diet high in omega-6 fats and refined sugars increases prostaglandin production. An anti-inflammatory diet reduces it.',
      ),
      ArticleSection(
        heading: 'The anti-inflammatory foods to prioritize',
        body:
            'Fatty fish (salmon, mackerel, sardines), extra-virgin olive oil, berries, leafy greens, turmeric, ginger, walnuts, and flaxseed all have strong anti-inflammatory evidence. Research shows that curcumin (the active compound in turmeric) shows promising results for reducing menstrual pain when taken consistently.',
      ),
      ArticleSection(
        heading: 'What to reduce',
        body:
            'Ultra-processed foods, refined carbohydrates, trans fats, excessive red meat, and high-sugar beverages all promote systemic inflammation. Making them the exception rather than the rule during your luteal and menstrual phases makes a measurable difference in symptom severity.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Start simple',
      colorKey: 'green',
      text:
          'Swap one processed snack per day for a handful of walnuts or berries during your luteal phase. Small, consistent changes are more effective than dramatic short-term overhauls.',
    ),
    pills: ['Prostaglandins', 'Omega-3', 'Curcumin', 'Antioxidants', 'Luteal phase'],
    sourceUrl:
        'https://www.healthline.com/health/womens-health/what-to-eat-during-period',
    sourceName: 'Healthline',
  ),

  // ══════════════════════════════════════════
  //  MENTAL HEALTH  (5)
  // ══════════════════════════════════════════

  Article(
    id: 15,
    category: 'Mental Health',
    tag: 'Mental health',
    colorKey: 'blue',
    emoji: '',
    readTime: '4 min read',
    title: 'Managing mood swings during PMS',
    desc: 'Irritability before your period isn\'t a personality trait — it\'s physiology.',
    intro:
        'PMS affects up to 80% of menstruating women, yet it\'s still widely dismissed as being "too emotional." The mood changes are driven by measurable hormonal shifts that affect your brain chemistry — and understanding them changes everything.',
    pullQuote:
        'Serotonin drops when estrogen and progesterone fall. You\'re not being dramatic. You\'re experiencing biochemistry.',
    sections: [
      ArticleSection(
        heading: 'The serotonin connection',
        body:
            'In the luteal phase, as progesterone and estrogen decline heading into menstruation, serotonin production dips with them. Serotonin regulates mood, sleep, and emotional resilience. When it\'s lower, everything feels harder — conflict feels bigger, small annoyances feel unbearable, and sadness can arrive out of nowhere.',
      ),
      ArticleSection(
        heading: 'What actually works',
        body:
            'Exercise raises serotonin more reliably than most supplements. Even a 20-minute walk on days 24–28 can measurably reduce irritability. Cutting caffeine after noon improves sleep quality, which further stabilizes mood. Magnesium — found in pumpkin seeds, dark chocolate, and leafy greens — helps regulate the nervous system during the luteal phase.',
      ),
      ArticleSection(
        heading: 'Tracking changes everything',
        body:
            'When you log your mood daily across 2–3 cycles, patterns emerge clearly. You\'ll begin to see that your irritability peaks on the same days each month. That knowledge alone — knowing it\'s temporary and predictable — reduces how much it affects you.',
      ),
    ],
    callout: ArticleCallout(
      label: 'When to get help',
      colorKey: 'pink',
      text:
          'If PMS symptoms significantly disrupt your life for more than 2 cycles, ask a doctor about PMDD — Premenstrual Dysphoric Disorder. It\'s real, common, and very treatable.',
    ),
    pills: ['Serotonin', 'Luteal phase', 'PMDD', 'Magnesium', 'Sleep hygiene'],
    sourceUrl: 'https://www.webmd.com/women/pms/what-is-pms',
    sourceName: 'WebMD',
  ),

  Article(
    id: 16,
    category: 'Mental Health',
    tag: 'Mental health',
    colorKey: 'blue',
    emoji: '',
    readTime: '4 min read',
    title: 'Anxiety and your menstrual cycle',
    desc: 'Cycle-related anxiety is common, real, and more manageable than you think.',
    intro:
        'Many women notice that their anxiety is significantly worse at certain points in their cycle — particularly in the week before their period. This isn\'t coincidence. Hormonal shifts directly modulate the brain\'s fear and stress response systems.',
    pullQuote:
        'Progesterone metabolizes into a compound that acts on GABA receptors — the same receptors targeted by anti-anxiety medications.',
    sections: [
      ArticleSection(
        heading: 'Why the luteal phase triggers anxiety',
        body:
            'Progesterone breaks down into a neurosteroid called allopregnanolone, which normally has a calming effect on the brain. But in the days before menstruation, progesterone drops rapidly — and with it, allopregnanolone. For some women, this withdrawal effect triggers heightened anxiety, panic feelings, and emotional sensitivity.',
      ),
      ArticleSection(
        heading: 'Estrogen\'s protective role',
        body:
            'Estrogen has an anxiolytic (anti-anxiety) effect by boosting serotonin and GABA activity. During the follicular phase when estrogen is high, many women feel notably calmer and more resilient. When estrogen drops before menstruation, that buffer disappears — which is why anxiety often spikes premenstrually.',
      ),
      ArticleSection(
        heading: 'Practical strategies',
        body:
            'Diaphragmatic breathing for 5 minutes reduces cortisol measurably within minutes. Progressive muscle relaxation before bed reduces premenstrual anxiety. Limiting caffeine — a direct anxiety amplifier — during the luteal phase is one of the highest-impact, lowest-effort changes you can make.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Track your anxiety',
      colorKey: 'blue',
      text:
          'Log your anxiety level daily alongside your cycle in FemCycle. After 2–3 cycles, you\'ll see whether it peaks consistently in the same phase — giving you the ability to plan around it.',
    ),
    pills: ['Allopregnanolone', 'GABA', 'Estrogen', 'Progesterone withdrawal', 'Cortisol'],
    sourceUrl: 'https://www.webmd.com/women/pms/what-is-pms',
    sourceName: 'WebMD',
  ),

  Article(
    id: 17,
    category: 'Mental Health',
    tag: 'Mental health',
    colorKey: 'blue',
    emoji: '',
    readTime: '3 min read',
    title: 'How your cycle affects your sleep',
    desc: 'Sleep quality changes measurably across your cycle — and there\'s a lot you can do about it.',
    intro:
        'Most women intuitively notice that their sleep changes throughout the month. Research confirms this: sleep architecture, duration, and quality all shift across the menstrual cycle in predictable, hormonally-driven ways.',
    pullQuote:
        'Poor sleep before your period isn\'t bad sleep hygiene. It\'s a physiological response to progesterone withdrawal.',
    sections: [
      ArticleSection(
        heading: 'How progesterone affects sleep',
        body:
            'Progesterone has a sedating, GABA-like effect that often makes women feel sleepier in the first half of the luteal phase. However, as progesterone drops in the days before menstruation, this sleep-promoting effect disappears — resulting in difficulty falling asleep, more nighttime awakenings, and less REM sleep in the premenstrual days.',
      ),
      ArticleSection(
        heading: 'Temperature and sleep disruption',
        body:
            'Progesterone also raises core body temperature by 0.3–0.5°C. Since sleep requires a drop in core temperature, high progesterone in the luteal phase makes it genuinely harder to fall into deep sleep. A cool bedroom (16–19°C) is more important in the luteal phase than at any other point in the month.',
      ),
      ArticleSection(
        heading: 'Improving luteal phase sleep',
        body:
            'Maintain consistent sleep and wake times across your entire cycle. Avoid alcohol, which disrupts sleep architecture and worsens premenstrual symptoms. Keep your room cool. Magnesium glycinate before bed has good evidence for improving sleep quality in the luteal phase.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Log your sleep',
      colorKey: 'blue',
      text:
          'Adding a sleep quality rating to your FemCycle daily log reveals patterns across your cycle that can guide when to prioritize sleep hygiene efforts most.',
    ),
    pills: ['Progesterone', 'Core temperature', 'REM sleep', 'Melatonin', 'Magnesium glycinate'],
    sourceUrl: 'https://www.webmd.com/women/pms/what-is-pms',
    sourceName: 'WebMD',
  ),

  Article(
    id: 18,
    category: 'Mental Health',
    tag: 'Mental health',
    colorKey: 'blue',
    emoji: '',
    readTime: '5 min read',
    title: 'PMDD: when PMS becomes something more serious',
    desc: 'Premenstrual Dysphoric Disorder is real, diagnosable, and highly treatable.',
    intro:
        'PMDD affects about 2–5% of menstruating women and causes severe mood disruption in the luteal phase that goes far beyond typical PMS. It is a recognized psychiatric condition with a well-established hormonal basis — and most women who have it go years without a proper diagnosis.',
    pullQuote:
        'PMDD is not severe PMS. It\'s a distinct condition where normal hormonal fluctuations trigger an abnormal brain response.',
    sections: [
      ArticleSection(
        heading: 'How PMDD differs from PMS',
        body:
            'PMS involves discomfort; PMDD involves impairment. Women with PMDD experience severe depression, overwhelming anxiety or anger, feelings of hopelessness, and mood swings so intense that they affect work, relationships, and daily functioning — consistently in the luteal phase, resolving within a few days of menstruation starting.',
      ),
      ArticleSection(
        heading: 'The neurological basis of PMDD',
        body:
            'Women with PMDD have a different sensitivity to normal hormonal fluctuations — specifically to the rise and fall of allopregnanolone (a progesterone metabolite). Their brains react atypically to hormonal changes that most women tolerate without severe symptoms. It is not a hormonal abnormality; it is a sensitivity to normal hormones.',
      ),
      ArticleSection(
        heading: 'Effective treatments',
        body:
            'SSRIs (selective serotonin reuptake inhibitors) taken either continuously or only in the luteal phase are first-line treatment and have strong efficacy for PMDD. Hormonal treatments that suppress ovulation are also effective. CBT specifically adapted for PMDD has good evidence. Lifestyle changes provide additional support but are rarely sufficient alone for true PMDD.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Seek help',
      colorKey: 'pink',
      text:
          'If you experience severe mood symptoms consistently before your period that resolve after it starts, please speak to a doctor. PMDD is under-diagnosed and over-dismissed. You deserve proper care.',
    ),
    pills: ['PMDD', 'SSRIs', 'Allopregnanolone', 'Luteal phase', 'CBT'],
    sourceUrl: 'https://www.webmd.com/women/pms/what-is-pms',
    sourceName: 'WebMD',
  ),

  Article(
    id: 19,
    category: 'Mental Health',
    tag: 'Mental health',
    colorKey: 'blue',
    emoji: '',
    readTime: '3 min read',
    title: 'Mindfulness practices for cycle symptoms',
    desc: 'Simple mindfulness habits can meaningfully reduce cycle-related emotional symptoms.',
    intro:
        'Mindfulness — the practice of non-judgmental present-moment awareness — has accumulated strong clinical evidence for reducing PMS-related mood symptoms, stress-related cycle disruption, and the distress associated with chronic menstrual conditions.',
    pullQuote:
        'You can\'t change your hormones with mindfulness. But you can change how your nervous system responds to them.',
    sections: [
      ArticleSection(
        heading: 'What mindfulness actually does hormonally',
        body:
            'Regular mindfulness practice measurably reduces cortisol over time. Since elevated cortisol disrupts the HPO axis and worsens PMS symptoms, reducing cortisol through mindfulness has real physiological consequences — not just psychological ones. 10 minutes of daily practice shows measurable cortisol reduction within 8 weeks.',
      ),
      ArticleSection(
        heading: 'The most effective practices for cycle symptoms',
        body:
            'Diaphragmatic breathing (inhale 4 counts, hold 4, exhale 6) activates the parasympathetic nervous system and reduces cortisol and anxiety within minutes. Body scan meditation helps identify tension patterns tied to your cycle. Journaling about your emotional state — even 5 minutes daily — builds the self-awareness that makes cycle patterns predictable rather than overwhelming.',
      ),
      ArticleSection(
        heading: 'Integrating mindfulness with cycle tracking',
        body:
            'The combination of mindfulness and cycle tracking is more powerful than either alone. When you can see in your FemCycle data that your lowest mood days fall consistently on days 25–27, you can bring intentional self-compassion to those days rather than being blindsided by them. Predictability reduces suffering.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Start today',
      colorKey: 'blue',
      text:
          'Try 5 minutes of diaphragmatic breathing before you check your phone tomorrow morning. Inhale for 4 counts, hold for 4, exhale for 6. Do this for one full cycle and notice what changes.',
    ),
    pills: ['Cortisol', 'HPO axis', 'Parasympathetic', 'Journaling', 'Self-compassion'],
    sourceUrl: 'https://www.webmd.com/women/pms/what-is-pms',
    sourceName: 'WebMD',
  ),

  // ══════════════════════════════════════════
  //  LIFESTYLE  (5)
  // ══════════════════════════════════════════

  Article(
    id: 20,
    category: 'Lifestyle',
    tag: 'Lifestyle',
    colorKey: 'amber',
    emoji: '',
    readTime: '4 min read',
    title: 'Sync your workouts to your cycle',
    desc: 'Your strength, stamina, and recovery all change week to week. Train accordingly.',
    intro:
        'Your hormonal environment changes so dramatically throughout your cycle that treating every workout week the same is working against your physiology. Cycle syncing your training isn\'t a trend — it\'s applying basic endocrinology to how you move.',
    pullQuote:
        'The luteal phase isn\'t a bad time to work out. It\'s just not the time to set personal records.',
    sections: [
      ArticleSection(
        heading: 'Menstrual phase: respect your body',
        body:
            'Iron and energy stores are depleted. Gentle yoga, slow walks, and light stretching are not failures — they\'re the right training stimulus for this phase. Trying to push through heavy training here consistently leads to burnout and injury over time.',
      ),
      ArticleSection(
        heading: 'Follicular phase: your growth window',
        body:
            'Rising estrogen accelerates muscle protein synthesis — your muscles literally build and repair faster during this phase. Strength training, interval work, and learning new physical skills are all ideal here. This is also when pain tolerance is highest and cardiovascular efficiency peaks.',
      ),
      ArticleSection(
        heading: 'Ovulation and luteal: peak then maintain',
        body:
            'Ovulation is your athletic peak — schedule your hardest workouts here. In the luteal phase, progesterone raises core temperature and shifts metabolism toward fat-burning. Moderate cardio — swimming, cycling, Pilates — feels sustainable without overtaxing a body preparing for menstruation.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Where to start',
      colorKey: 'amber',
      text:
          'Start by logging your energy level daily in FemCycle for 2–3 cycles. Your own pattern will show you exactly when to push and when to rest — no generic programme needed.',
    ),
    pills: ['Cycle syncing', 'Estrogen', 'Progesterone', 'Muscle synthesis', 'Recovery'],
    sourceUrl:
        'https://www.healthline.com/health/womens-health/guide-to-cycle-syncing-how-to-start',
    sourceName: 'Healthline',
  ),

  Article(
    id: 21,
    category: 'Lifestyle',
    tag: 'Lifestyle',
    colorKey: 'amber',
    emoji: '',
    readTime: '4 min read',
    title: 'Exercise for period pain and PMS relief',
    desc: 'Movement is one of the most effective — and most avoided — tools for period symptoms.',
    intro:
        'Exercise is often the last thing anyone wants to do during their period. But evidence consistently shows it\'s one of the most effective interventions for reducing cramping, fatigue, and mood symptoms — often more effective than over-the-counter pain medication for mild to moderate symptoms.',
    pullQuote:
        'Exercise during menstruation isn\'t punishment. It\'s one of the fastest, most accessible ways to feel better.',
    sections: [
      ArticleSection(
        heading: 'How exercise relieves cramps',
        body:
            'Physical activity releases endorphins — natural pain-relieving compounds that also elevate mood. It also increases blood flow to the uterus, which can reduce the ischemia (reduced blood flow) that intensifies cramping. Research shows that 30 minutes of moderate aerobic exercise three times per week significantly reduced painful periods over two menstrual cycles.',
      ),
      ArticleSection(
        heading: 'The best types of exercise during your period',
        body:
            'Low-to-moderate intensity aerobic exercise is best during menstruation: walking, light cycling, swimming, or yoga. High-intensity exercise is fine if you feel up to it and don\'t experience heavy flow or severe symptoms — follow your energy. Any movement is better than none.',
      ),
      ArticleSection(
        heading: 'Building an exercise habit across your cycle',
        body:
            'Rather than forcing intensity during your period, use the follicular phase (when estrogen is rising and energy is high) to build your exercise habit. Consistent moderate exercise throughout your whole cycle produces the most sustained reduction in PMS and dysmenorrhea over time.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Clinical evidence',
      colorKey: 'amber',
      text:
          '150 minutes of moderate aerobic exercise per week is the threshold at which research shows meaningful improvements in menstrual symptoms, PCOS outcomes, and mood. That\'s just 30 minutes, five days a week.',
    ),
    pills: ['Endorphins', 'Dysmenorrhea', 'Aerobic exercise', 'Blood flow', 'PMS relief'],
    sourceUrl: 'https://www.healthline.com/health/fitness/female-hormones-exercise',
    sourceName: 'Healthline',
  ),

  Article(
    id: 22,
    category: 'Lifestyle',
    tag: 'Lifestyle',
    colorKey: 'amber',
    emoji: '',
    readTime: '3 min read',
    title: 'Sleep strategies for every phase of your cycle',
    desc: 'Your sleep needs change across your cycle. Here\'s how to optimize every week.',
    intro:
        'Sleep and your menstrual cycle are in constant conversation. Hormonal changes affect sleep quality and duration throughout the month — and poor sleep, in turn, worsens hormonal balance and cycle symptoms.',
    pullQuote:
        'In the luteal phase, your body needs more sleep. Giving it that sleep is not indulgence — it\'s active symptom management.',
    sections: [
      ArticleSection(
        heading: 'Menstrual and follicular: rebuild',
        body:
            'During menstruation, iron loss and low hormones can cause fatigue. Prioritize sleep quality over quantity: a cool room, no alcohol, and consistent timing. As estrogen rises in the follicular phase, sleep quality naturally improves — use this time to rebuild any sleep debt accumulated during the premenstrual week.',
      ),
      ArticleSection(
        heading: 'Ovulation through mid-luteal: use the sedating effect',
        body:
            'Many women sleep best around ovulation when estrogen is high. As progesterone rises in the early luteal phase, it has an initial sedating effect — you may feel ready for sleep earlier. An earlier bedtime during this phase is genuinely beneficial. Use it.',
      ),
      ArticleSection(
        heading: 'Late luteal: the hardest week for sleep',
        body:
            'As progesterone and estrogen drop before menstruation, sleep disruption typically peaks. Strategies: keep your room below 19°C, avoid alcohol entirely this week, take magnesium glycinate before bed, limit caffeine after noon, and dim lights by 9pm.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Sleep hygiene that actually helps',
      colorKey: 'amber',
      text:
          'Cool room, consistent timing, no alcohol, magnesium before bed. These four things consistently improve luteal phase sleep more than anything else. Pick one to start this cycle.',
    ),
    pills: ['Progesterone', 'Estrogen', 'Magnesium', 'Sleep quality', 'Cortisol'],
    sourceUrl:
        'https://www.healthline.com/health/womens-health/guide-to-cycle-syncing-how-to-start',
    sourceName: 'Healthline',
  ),

  Article(
    id: 23,
    category: 'Lifestyle',
    tag: 'Lifestyle',
    colorKey: 'amber',
    emoji: '',
    readTime: '4 min read',
    title: 'Productivity and your menstrual cycle',
    desc: 'Your brain\'s capabilities genuinely shift across your cycle. Working with that is a superpower.',
    intro:
        'Cognitive performance, creativity, verbal fluency, memory, and social intelligence all fluctuate across the menstrual cycle in documented, reproducible ways. Understanding your brain\'s cycle — not just your body\'s — is one of the most underutilized performance tools available to women.',
    pullQuote:
        'You\'re not inconsistent. Your brain is operating on a 28-day rhythm that most productivity advice completely ignores.',
    sections: [
      ArticleSection(
        heading: 'Follicular phase: your creative peak',
        body:
            'Rising estrogen boosts dopamine and serotonin, improving working memory, verbal fluency, and creative thinking. Research has found measurable changes in brain connectivity across the menstrual cycle, with the follicular phase showing enhanced prefrontal cortex activity. This is your best time for brainstorming, writing, and complex problem-solving.',
      ),
      ArticleSection(
        heading: 'Ovulation: communication and leadership',
        body:
            'At ovulation, estrogen peaks and testosterone briefly rises. This combination enhances confidence, assertiveness, persuasiveness, and social acuity. This is your natural peak for presentations, negotiations, difficult conversations, and leadership tasks.',
      ),
      ArticleSection(
        heading: 'Luteal phase: detail-orientation and completion',
        body:
            'Despite lower energy, the luteal phase is associated with stronger attention to detail and a preference for completion over initiation. This makes it an excellent time for editing, administrative tasks, and methodical work that benefits from careful attention. Save the big launches for your follicular phase.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Practical application',
      colorKey: 'amber',
      text:
          'Try planning your calendar 4 weeks ahead with your cycle in mind: schedule presentations and important meetings in your follicular/ovulation phase; block slower, administrative time in your late luteal phase.',
    ),
    pills: ['Estrogen', 'Dopamine', 'Prefrontal cortex', 'Verbal fluency', 'Creativity'],
    sourceUrl:
        'https://www.healthline.com/health/womens-health/guide-to-cycle-syncing-how-to-start',
    sourceName: 'Healthline',
  ),

  Article(
    id: 24,
    category: 'Lifestyle',
    tag: 'Lifestyle',
    colorKey: 'amber',
    emoji: '',
    readTime: '3 min read',
    title: 'Self-care practices for each cycle phase',
    desc: 'Rest, connection, creativity, and reflection — matched to when your body needs them most.',
    intro:
        'Self-care is not the same thing every week. What restores you in the follicular phase may drain you in the luteal phase. Matching your self-care practices to your hormonal environment makes them dramatically more effective.',
    pullQuote:
        'The most powerful self-care isn\'t what you do. It\'s doing the right thing at the right time in your cycle.',
    sections: [
      ArticleSection(
        heading: 'Menstrual phase: rest and reflect',
        body:
            'This is your body\'s natural invitation to slow down and turn inward. Warmth is restorative: hot water bottles, warm baths, nourishing soups. Gentle journaling about the past cycle — what worked, what didn\'t, what you\'re letting go of — uses the naturally reflective quality of this phase productively.',
      ),
      ArticleSection(
        heading: 'Follicular phase: connect and explore',
        body:
            'Rising energy and mood make this an ideal time for social connection, trying new things, and engaging with the world. Start a new project, reach out to someone you\'ve been meaning to contact, try a new exercise class, cook something new. Your openness to novelty is genuinely higher in this phase.',
      ),
      ArticleSection(
        heading: 'Luteal phase: nourish and prepare',
        body:
            'As energy declines toward the end of the luteal phase, self-care shifts toward nourishment and preparation. Reduce social commitments, prioritize rest, spend time in nature, engage in creative or sensory activities that don\'t require social energy. Saying no to things in this phase is self-care, not failure.',
      ),
    ],
    callout: ArticleCallout(
      label: 'Your cycle, your rhythm',
      colorKey: 'amber',
      text:
          'These are frameworks, not rules. Use your FemCycle energy logs to discover your own pattern — your inner seasons may not match the textbook perfectly, and that\'s entirely normal.',
    ),
    pills: ['Rest', 'Creativity', 'Social energy', 'Journaling', 'Seasonal living'],
    sourceUrl:
        'https://www.healthline.com/health/womens-health/guide-to-cycle-syncing-how-to-start',
    sourceName: 'Healthline',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EducationalScreen extends StatefulWidget {
  const EducationalScreen({super.key});

  @override
  State<EducationalScreen> createState() => _EducationalScreenState();
}

class _EducationalScreenState extends State<EducationalScreen> {
  static const List<String> _tabs = [
    'All', 'Cycle', 'PCOS', 'Nutrition', 'Mental Health', 'Lifestyle'
  ];

  static const Map<String, Color> _tabColors = {
    'All':           _Glass.blueDeep,
    'Cycle':         _Glass.pinkDeep,
    'PCOS':          Color(0xFFA865C0),
    'Nutrition':     Color(0xFF3BAF7E),
    'Mental Health': _Glass.blueDeep,
    'Lifestyle':     Color(0xFFD4843A),
  };

  int _selectedTab = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Coach-mark tour targets ──
  final GlobalKey _searchBarKey = GlobalKey();
  final GlobalKey _chipsKey = GlobalKey();
  final GlobalKey _heroKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _maybeShowCoachTour();
  }

  Future<void> _maybeShowCoachTour() async {
    final seen = await TutorialStorageService.hasSeenTour(TutorialStorageService.learn);
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoachTour());
  }

  void _startCoachTour() {
    final steps = [
      CoachMarkStep(
        targetKey: _searchBarKey,
        title: 'Search anything',
        description: 'Look up a topic, symptom, or article title directly.',
      ),
      CoachMarkStep(
        targetKey: _chipsKey,
        title: 'Filter by category',
        description: 'Jump straight to Cycle, PCOS, Nutrition, Mental Health, or Lifestyle articles.',
      ),
      if (kArticles.isNotEmpty)
        CoachMarkStep(
          targetKey: _heroKey,
          title: 'Featured read',
          description: 'Your top article for the current filter is always featured up here.',
        ),
    ];
    showCoachMarkTour(context: context, steps: steps)
        .then((_) => TutorialStorageService.markTourSeen(TutorialStorageService.learn));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Article> get _filtered {
    final tab = _tabs[_selectedTab];
    return kArticles.where((a) {
      final matchTab = tab == 'All' || a.category == tab;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.tag.toLowerCase().contains(q) ||
          a.desc.toLowerCase().contains(q);
      return matchTab && matchSearch;
    }).toList();
  }

  void _openArticle(Article article) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
      );

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: _Glass.pageBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: Column(children: [
                            KeyedSubtree(key: _searchBarKey, child: _searchBar()),
                            const SizedBox(height: 12),
                            KeyedSubtree(key: _chipsKey, child: _chips()),
                            const SizedBox(height: 14),
                          ]),
                        ),
                      ),
                      if (list.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: KeyedSubtree(key: _heroKey, child: _heroCard(list.first)),
                          ),
                        ),
                        if (list.length > 1) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                              child: Text(
                                'MORE READS',
                                style: _Glass.body(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: _Glass.textHint,
                                ).copyWith(letterSpacing: .8),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
                            sliver: _restSliver(list.skip(1).toList()),
                          ),
                        ],
                      ] else
                        SliverFillRemaining(child: _empty()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: _Glass.card(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Text('Learn', style: _Glass.heading(size: 18, weight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: _startCoachTour,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _Glass.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.question_mark_rounded, size: 15, color: _Glass.blueDeep),
              ),
            ),
          ]),
        ),
      );

  Widget _searchBar() => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        child: Row(children: [
          Icon(Icons.search, color: _Glass.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: _Glass.body(size: 13),
              decoration: InputDecoration(
                hintText: 'Search topics, articles...',
                hintStyle: _Glass.body(size: 13, color: _Glass.textHint),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ]),
      );

  Widget _chips() => SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final isActive = _selectedTab == i;
            final col = _tabColors[_tabs[i]] ?? _Glass.blueDeep;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? col : Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: isActive ? col : Colors.white.withOpacity(0.7)),
                ),
                child: Text(_tabs[i],
                    style: _Glass.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: isActive ? Colors.white : _Glass.textMuted,
                    )),
              ),
            );
          },
        ),
      );

  Widget _heroCard(Article a) {
    final c = colorOf(a.colorKey);
    return GestureDetector(
      onTap: () => _openArticle(a),
      child: _Glass.card(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                  color: c.deep, borderRadius: BorderRadius.circular(30)),
              child: Text(a.tag,
                  style: _Glass.body(
                      size: 10, weight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Text("Editor's pick",
                style: _Glass.body(
                  size: 10,
                  weight: FontWeight.w700,
                  color: c.accent,
                ).copyWith(letterSpacing: .6)),
          ]),
          const SizedBox(height: 10),
          Text(a.title,
              style: _Glass.heading(
                size: 21,
                weight: FontWeight.w700,
                color: _Glass.textDark,
              ).copyWith(height: 1.22)),
          const SizedBox(height: 8),
          Text(a.desc,
              style: _Glass.body(
                size: 13,
                color: _Glass.textMuted,
              ).copyWith(height: 1.6)),
          const SizedBox(height: 14),
          Row(children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: c.accent,
              child: const Text('FC',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FemCycle Health',
                  style: _Glass.body(
                      size: 11, weight: FontWeight.w600, color: _Glass.textMuted)),
              Text(a.readTime,
                  style: _Glass.body(size: 11, color: _Glass.textHint)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () => _openArticle(a),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(30)),
                child: Text('Read article',
                    style: _Glass.body(
                        size: 12, weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _restSliver(List<Article> items) {
    final rows = <Widget>[];
    int i = 0;
    while (i < items.length) {
      final a = items[i];
      final isShort =
          a.readTime.startsWith('2') || a.readTime.startsWith('3');
      final nextIsShort = i + 1 < items.length &&
          (items[i + 1].readTime.startsWith('2') ||
              items[i + 1].readTime.startsWith('3'));
      if (isShort && nextIsShort) {
        rows.add(_gridRow(a, items[i + 1]));
        i += 2;
      } else {
        rows.add(_listCard(a));
        i++;
      }
      rows.add(const SizedBox(height: 10));
    }
    return SliverList(delegate: SliverChildListDelegate(rows));
  }

  Widget _gridRow(Article a, Article b) => Row(children: [
        Expanded(child: _gridCard(a)),
        const SizedBox(width: 10),
        Expanded(child: _gridCard(b)),
      ]);

  Widget _gridCard(Article a) {
    final c = colorOf(a.colorKey);
    return GestureDetector(
      onTap: () => _openArticle(a),
      child: _Glass.card(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.tag.toUpperCase(),
                  style: _Glass.body(
                    size: 9,
                    weight: FontWeight.w700,
                    color: c.accent,
                  ).copyWith(letterSpacing: .5)),
              const SizedBox(height: 3),
              Text(a.title,
                  style: _Glass.heading(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _Glass.textDark,
                  ).copyWith(height: 1.3)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 10, color: _Glass.textHint),
                const SizedBox(width: 3),
                Text(a.readTime,
                    style: _Glass.body(size: 10, color: _Glass.textHint)),
              ]),
        ]),
      ),
    );
  }

  Widget _listCard(Article a) {
    final c = colorOf(a.colorKey);
    return GestureDetector(
      onTap: () => _openArticle(a),
      child: _Glass.card(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.tag.toUpperCase(),
                  style: _Glass.body(
                    size: 9,
                    weight: FontWeight.w700,
                    color: c.accent,
                  ).copyWith(letterSpacing: .5)),
              const SizedBox(height: 3),
              Text(a.title,
                  style: _Glass.heading(
                    size: 14,
                    weight: FontWeight.w700,
                    color: _Glass.textDark,
                  ).copyWith(height: 1.3)),
              const SizedBox(height: 4),
              Text(a.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _Glass.body(
                    size: 12,
                    color: _Glass.textMuted,
                  ).copyWith(height: 1.5)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 10, color: _Glass.textHint),
                const SizedBox(width: 3),
                Text(a.readTime,
                    style: _Glass.body(size: 10, color: _Glass.textHint)),
              ]),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: _Glass.textHint),
            const SizedBox(height: 12),
            Text('No articles found',
                style: _Glass.body(size: 15, color: _Glass.textMuted)),
          ],
        ),
      );
}

// ─── Glass design tokens ───────────────────────────────────────────────────────
// Shared frosted-glass / ambient-blob design system reused across every
// screen (Home, Mood, Diary, Learn, Lifestyle, Profile, and the auth flow).

class _Glass {
  static const Color pageBackground = Color(0xFFF3F1FB);

  static const Color blue = Color(0xFF9FC8FF);
  static const Color blueDeep = Color(0xFF5B93E0);
  static const Color pink = Color(0xFFFFA7CE);
  static const Color pinkDeep = Color(0xFFE0679A);
  static const Color purple = Color(0xFFC6ACFF);
  static const Color purpleDeep = Color(0xFF9A78E0);

  static const Color textDark = Color(0xFF2B2638);
  static const Color textMuted = Color(0xFF6E677D);
  static const Color textHint = Color(0xFFA6A0B4);

  static TextStyle heading({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color color = textDark,
  }) =>
      GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color);

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = textDark,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);

  /// Frosted translucent card: blurred backdrop + soft white glass fill.
  static Widget card({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double opacity = 0.55,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: purpleDeep.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: blueDeep,
      foregroundColor: Colors.white,
      disabledBackgroundColor: blueDeep.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    );
  }
}

/// Three soft, blurred color blobs (blue / pink / purple) that gently drift
/// behind the frosted glass content. Purely decorative — no state that
/// affects the rest of the screen.
class _AmbientBackground extends StatefulWidget {
  const _AmbientBackground();

  @override
  State<_AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<_AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: [
            Container(color: _Glass.pageBackground),
            Positioned(
              top: -60 + 24 * math.sin(t),
              left: -70 + 20 * math.cos(t),
              child: _blob(size.width * 0.7, _Glass.blue.withOpacity(0.55)),
            ),
            Positioned(
              top: size.height * 0.35 + 26 * math.cos(t * 0.85),
              right: -90 + 22 * math.sin(t * 0.85),
              child: _blob(size.width * 0.75, _Glass.pink.withOpacity(0.5)),
            ),
            Positioned(
              bottom: -80 + 20 * math.sin(t * 1.15),
              left: size.width * 0.15 + 18 * math.cos(t * 1.15),
              child: _blob(size.width * 0.65, _Glass.purple.withOpacity(0.5)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double diameter, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}