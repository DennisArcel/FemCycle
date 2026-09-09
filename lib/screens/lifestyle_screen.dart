import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/coach_mark_overlay.dart';
import '../services/tutorial_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class LifestyleItem {
  final String name;
  final String shortDesc;
  final String imageUrl;   // Unsplash CDN URL (card thumbnail)
  final Color  accentColor;
  final String duration;
  final String why;
  final String tip;
  final List<String> steps;
  // Optional per-step local asset images. If provided, the detail screen
  // shows stepImages[currentStep] instead of the single imageUrl.
  final List<String>? stepImages;

  const LifestyleItem({
    required this.name,
    required this.shortDesc,
    required this.imageUrl,
    required this.accentColor,
    required this.duration,
    required this.why,
    required this.tip,
    required this.steps,
    this.stepImages,
  });
}

class PhaseData {
  final String name;
  final Color  color;
  final Color  surface;
  final String emoji;
  final String subtitle;
  final List<LifestyleItem> exercise;
  final List<LifestyleItem> sleep;
  final List<LifestyleItem> nutrition;
  final List<LifestyleItem> productivity;

  const PhaseData({
    required this.name,
    required this.color,
    required this.surface,
    required this.emoji,
    required this.subtitle,
    required this.exercise,
    required this.sleep,
    required this.nutrition,
    required this.productivity,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// UNSPLASH IMAGE URLS
// Format: https://images.unsplash.com/photo-{ID}?w=600&q=80&fit=crop
// All images are free to use (Unsplash License)
//
// NOTE: a handful of the original IDs in this file were malformed/fake and
// 404'd, which made those cards fall back to the broken-image placeholder.
// Those have been swapped for reliable picsum.photos placeholders below —
// swap them out for exact-match photos whenever convenient, they're just
// marked so it's easy to find them again.
// ─────────────────────────────────────────────────────────────────────────────

// ignore_for_file: lines_longer_than_80_chars
const _u = 'https://images.unsplash.com/photo-';
const _p = 'https://picsum.photos/seed/'; // reliable placeholder fallback

// Exercise images
const _yoga         = '${_u}1506126613408-eca07ce68773?w=600&q=80&fit=crop'; // woman child's pose
const _walking      = '${_u}1476480862126-209bfaa8edc8?w=600&q=80&fit=crop'; // woman walking outdoor
const _breathwork   = '${_u}1517363898874-737b62a7db91?w=600&q=80&fit=crop'; // woman meditating/breathing
const _stretching   = '${_u}1518611012118-696072aa579a?w=600&q=80&fit=crop'; // woman stretching floor
const _bath         = '${_u}1596182702367-05a5e080a7ac?w=600&q=80&fit=crop'; // bathtub
const _jogging      = '${_u}1571019613454-1cb2f99b2d8b?w=600&q=80&fit=crop'; // woman jogging park
const _strength     = '${_p}home-strength/600/400'; // home bodyweight strength (was: woman dumbbell — swapped, content is now equipment-free)
const _hiit         = '${_u}1549060279-7e168fcee0c2?w=600&q=80&fit=crop'; // woman jumping HIIT (thumbnail overridden by stepImages)
const _cycling      = '${_u}1543942493-94d3f7018c4b?w=600&q=80&fit=crop'; // person cycling road
const _swimming     = '${_u}1519315901367-f34ff9154487?w=600&q=80&fit=crop'; // swimmer in pool
const _heavylift    = '${_p}bodyweight-power/600/400'; // bodyweight power circuit (was: barbell deadlift — swapped, content is now equipment-free)
const _poweryoga    = '${_u}1524594152303-9fd13543fe6e?w=600&q=80&fit=crop'; // warrior yoga pose (thumbnail overridden by stepImages)
const _pilates      = '${_u}1518611880905-c2e31d8b9c41?w=600&q=80&fit=crop'; // pilates bridge mat (thumbnail overridden by stepImages)
const _restoreyoga  = '${_u}1447452001571-1ab2c9b2a2c0?w=600&q=80&fit=crop'; // restorative yoga floor (thumbnail overridden by stepImages)

// Sleep images
const _sleep8h      = '${_u}1541781774459-bb2af2f05b55?w=600&q=80&fit=crop'; // woman sleeping peacefully
const _chamomile    = '${_u}1504382103100-db7e92322d39?w=600&q=80&fit=crop'; // herbal tea glass mug
const _noScreen     = '${_u}1558735416-bd72f544a761?w=600&q=80&fit=crop'; // phone on bed at night
const _coolRoom     = '${_u}1631049307264-da0ec9d70304?w=600&q=80&fit=crop'; // cool minimal bedroom
const _journalBed   = '${_u}1455390582262-044cdead277a?w=600&q=80&fit=crop'; // journal writing bed
const _morningLight = '${_u}1506905925346-21bda4d32df4?w=600&q=80&fit=crop'; // woman morning sunlight

// Nutrition images
const _ironFoods    = '${_u}1512621776951-a57141f2eefd?w=600&q=80&fit=crop'; // spinach lentils bowl
const _omega3       = '${_p}local-fish-omega3/600/400'; // local fish omega-3 (was: salmon avocado plate — swapped, content now leads with galunggong/sardinas)
const _darkChoc     = '${_u}1604514813549-92e26bbae4f2?w=600&q=80&fit=crop'; // dark chocolate bars
const _magnesiumFoods = '${_p}monggo-malunggay/600/400'; // monggo & malunggay dishes (own image so it no longer shares the Dark Chocolate photo)
const _hydration    = '${_u}1523362628745-0c100150b504?w=600&q=80&fit=crop'; // water glass lemon
const _gingerTea    = '${_u}1531264071041-3a69924b182d?w=600&q=80&fit=crop'; // lemon ginger tea
const _phaseEating  = '${_u}1490645935967-10de6ba17061?w=600&q=80&fit=crop'; // colorful healthy bowls
const _calcium      = '${_u}1596151163116-98a5033814c2?w=600&q=80&fit=crop'; // glass of milk
const _protein      = '${_u}1559332167-dd24746aa6f5?w=600&q=80&fit=crop'; // eggs and toast plate
const _antInflam    = '${_u}1505576399279-565b52d4ac71?w=600&q=80&fit=crop'; // turmeric berries bowl
const _complex      = '${_u}1497888329096-51c27beff665?w=600&q=80&fit=crop'; // oatmeal bowls with fruit

// Productivity images
const _lightTask    = '${_u}1506784983877-45594efa4cbe?w=600&q=80&fit=crop'; // woman desk laptop calm
const _organize     = '${_u}1484480974693-6ca0a78fb36b?w=600&q=80&fit=crop'; // organized planner desk
const _deepWork     = '${_u}1758612214917-81d7956c09de?w=600&q=80&fit=crop'; // woman typing at desk
const _journal      = '${_u}1455390582262-044cdead277a?w=600&q=80&fit=crop'; // journal writing pen
const _selfCare     = '${_u}1507003211169-0a1dd7228f2d?w=600&q=80&fit=crop'; // woman window relax
const _sayNo        = '${_u}1506905925346-21bda4d32df4?w=600&q=80&fit=crop'; // woman peaceful nature
const _network      = '${_u}1573496267526-08a69e46a409?w=600&q=80&fit=crop'; // two women talking, work
const _present      = '${_u}1758518727888-ffa196002e59?w=600&q=80&fit=crop'; // confident businesswoman
const _complete     = '${_u}1484480974693-6ca0a78fb36b?w=600&q=80&fit=crop'; // checklist complete
const _serotoninFood = '${_u}1601316585772-ba1e6dae9cfc?w=600&q=80&fit=crop'; // salmon plate with greens
const _highStakes    = '${_u}1758518727888-ffa196002e59?w=600&q=80&fit=crop'; // confident businesswoman// ─────────────────────────────────────────────────────────────────────────────
// PHASE DATA
// ─────────────────────────────────────────────────────────────────────────────

const List<PhaseData> kPhases = [

  // ══════════════════════════════════
  //  MENSTRUAL  (Days 1–5)
  // ══════════════════════════════════
  PhaseData(
    name: 'Menstrual', emoji: '🩸',
    color: Color(0xFFE96A8F), surface: Color(0xFFFDE8EF),
    subtitle: 'Days 1–5 · Rest, restore, replenish',
    exercise: [
      LifestyleItem(
        name: 'Gentle Yoga',
        shortDesc: 'Eases cramps & calms the nervous system',
        imageUrl: _yoga,
        accentColor: Color(0xFFE96A8F),
        duration: '20–30 min',
        why: 'Yoga activates the parasympathetic nervous system, reducing cortisol that amplifies pain. Hip-opening poses increase blood flow to the pelvis, directly reducing cramp intensity.',
        tip: 'Use a heating pad on your lower abdomen before starting — pre-relaxing the muscles makes every pose more effective.',
        steps: [
          'Find a quiet, warm space and roll out your mat',
          'Child\'s Pose — Hips to heels, arms extended, hold 2 minutes',
          'Supine Twist — Drop knee across body each side, hold 90 seconds',
          'Seated Butterfly — Soles together, gently fold forward, 2 minutes',
          'Legs Up the Wall — Rest for 5 minutes',
          'Savasana — Lie flat, palms up, rest for 3 minutes',
        ],
        stepImages: [
          'assets/images/lifestyle/yoga/yoga_step1.png',
          'assets/images/lifestyle/yoga/yoga_step1.png',
          'assets/images/lifestyle/yoga/yoga_step2.png',
          'assets/images/lifestyle/yoga/yoga_step3.png',
          'assets/images/lifestyle/yoga/yoga_step4.png',
          'assets/images/lifestyle/yoga/yoga_step5.png',
        ],
      ),
      LifestyleItem(
        name: 'Light Walking',
        shortDesc: 'Natural endorphin boost, no strain',
        imageUrl: _walking,
        accentColor: Color(0xFF84B2E9),
        duration: '20–30 min',
        why: 'Walking releases endorphins that act as natural pain relief, increases circulation to ease bloating, and boosts serotonin to stabilize the mood dip that comes with falling hormones.',
        tip: 'Morning walks in natural light are especially powerful — sunlight regulates melatonin and improves your sleep that night.',
        steps: [
          'Put on comfortable shoes — supportive but not tight',
          'Start at a very casual pace for the first 5 minutes, no goals',
          'Settle into a pace where you can hold a conversation easily',
          'Focus on your surroundings: sounds, smells, the feel of air on your skin',
          'Maintain this gentle pace for 15–20 minutes',
          'Slow to a stroll for the final 5 minutes, then do gentle calf stretches',
        ],
      ),
      LifestyleItem(
        name: 'Breathwork',
        shortDesc: 'Reduces pain perception directly',
        imageUrl: _breathwork,
        accentColor: Color(0xFFBC6B9C),
        duration: '10–15 min',
        why: 'Diaphragmatic breathing activates the vagus nerve and parasympathetic nervous system, which directly reduce pain sensitivity. Cramps often soften within minutes of consistent practice.',
        tip: 'Start at the very first sign of a cramp — breathwork works significantly faster when initiated early rather than during peak pain.',
        steps: [
          'Sit or lie down comfortably — one hand on belly, one on chest',
          'Close your eyes, relax your jaw, let your shoulders completely drop',
          'Inhale slowly through your nose for 4 counts — feel your belly rise',
          'Hold the breath gently for 7 counts — this stimulates the vagus nerve',
          'Exhale completely through your mouth for 8 counts with a soft sigh',
          'Repeat 5 full cycles and notice the shift in your body',
        ],
      ),
      LifestyleItem(
        name: 'Gentle Stretching',
        shortDesc: 'Releases lower back & hip tension',
        imageUrl: _stretching,
        accentColor: Color(0xFFE96A8F),
        duration: '15–20 min',
        why: 'The lower back and hips hold significant tension during menstruation due to uterine contractions radiating through the pelvis. Targeted stretching releases this tension and improves blood flow.',
        tip: 'Hold each stretch for a full 60 seconds — the first 30 seconds your muscles resist, the second 30 seconds they actually release.',
        steps: [
          'Lie on your back and draw both knees gently to your chest — hold 1 min',
          'Lower both knees to one side for a spinal twist — 60 seconds each side',
          'Come to seated: soles of feet together for butterfly stretch — 2 minutes',
          'Stand for gentle hip circles — 8 rotations each direction, slow and controlled',
          'Finish with a standing forward fold — hinge at hips, hang for 60 seconds',
          'Roll up very slowly, one vertebra at a time',
        ],
        stepImages: [
          'assets/images/lifestyle/stretching/stretch_step1.png',
          'assets/images/lifestyle/stretching/stretch_step2.png',
          'assets/images/lifestyle/stretching/stretch_step3.png',
          'assets/images/lifestyle/stretching/stretch_step4.png',
          'assets/images/lifestyle/stretching/stretch_step5.png',
          'assets/images/lifestyle/stretching/stretch_step5.png',
        ],
      ),
      LifestyleItem(
        name: 'Warm Bath Soak',
        shortDesc: 'Heat therapy for muscle relief',
        imageUrl: _bath,
        accentColor: Color(0xFFBC6B9C),
        duration: '20–30 min',
        why: 'Heat relaxes the smooth muscle of the uterus, reducing cramping intensity. Epsom salts provide transdermal magnesium for additional muscle relaxation — the same mechanism as oral magnesium.',
        tip: 'Magnesium from Epsom salts is absorbed through the skin. Add 2 cups per bath for a meaningful dose — it genuinely works.',
        steps: [
          'Fill your bath with warm water at 38–40°C (warm, not scalding)',
          'Add 2 cups of Epsom salts and stir until fully dissolved',
          'Optionally add 5–6 drops of lavender or clary sage essential oil',
          'Submerge your lower abdomen in the water and focus on slow, deep breathing',
          'Soak for 20–30 minutes — add warm water as needed',
          'Pat dry gently and apply a warm heating pad to continue the benefit',
        ],
      ),
    ],
    sleep: [
      LifestyleItem(
        name: '8–9 Hours Sleep',
        shortDesc: 'Your body is doing real work tonight',
        imageUrl: _sleep8h,
        accentColor: Color(0xFFE96A8F),
        duration: 'Nightly',
        why: 'Menstruation requires significant physiological work — shedding the uterine lining demands energy and immune resources. Iron loss also contributes to genuine fatigue. Your sleep requirement is measurably higher on days 1–3.',
        tip: 'Side-sleeping with a pillow between your knees significantly reduces pressure on the uterus and eases overnight cramping without any medication.',
        steps: [
          'Set your target bedtime 30–60 minutes earlier than usual this week',
          'Cool your room to 17–19°C and close curtains for darkness',
          'Drink chamomile tea 30 minutes before bed — it has a genuine calming effect',
          'Lie on your side with a pillow between your knees to reduce pelvic pressure',
          'Apply a low-heat heating pad to your lower abdomen if cramping',
          'If you wake from cramps, do 4-7-8 breathing until they ease',
        ],
      ),
      LifestyleItem(
        name: 'No Screens Before Bed',
        shortDesc: 'Protect your melatonin this week',
        imageUrl: _noScreen,
        accentColor: Color(0xFFBC6B9C),
        duration: '60–90 min before bed',
        why: 'Blue light from screens suppresses melatonin production, delaying sleep onset by up to 90 minutes. During menstruation when your body most needs rest, protecting melatonin is especially important.',
        tip: 'Buy a cheap alarm clock so your phone can sleep in another room entirely. Having it physically removed is more effective than any app-based limit.',
        steps: [
          'Set an alarm for 90 minutes before your target bedtime',
          'When it sounds, put your phone in another room — not silent, another room',
          'Dim all lights: switch to warm lamps instead of overhead lighting',
          'Choose your replacement activity: reading, journaling, or gentle stretching',
          'Make chamomile tea and drink it slowly while doing your chosen activity',
          'Get into bed without your phone — notice how quickly sleep comes',
        ],
      ),
      LifestyleItem(
        name: 'Chamomile Tea Ritual',
        shortDesc: 'Calms cramps and promotes sleep',
        imageUrl: _chamomile,
        accentColor: Color(0xFFE96A8F),
        duration: '30 min before bed',
        why: 'Chamomile contains apigenin, which binds to the same receptors as anti-anxiety medications — promoting relaxation. It also has antispasmodic properties that directly relax smooth muscle, including the uterus.',
        tip: 'Chamomile combined with magnesium (a small handful of pumpkin seeds or almonds alongside the tea) is more effective than either alone for menstrual sleep.',
        steps: [
          'Boil water and let cool to 80°C — just below boiling to preserve the active compounds',
          'Steep chamomile tea bag or 2 tsp of dried flowers for 5 full minutes',
          'Add a small amount of honey — honey has mild anti-inflammatory properties',
          'Hold the warm mug in your hands and breathe the steam for a moment',
          'Drink slowly over 10–15 minutes while doing something calming',
          'Begin your wind-down routine immediately after — your body recognizes the cue',
        ],
      ),
    ],
    nutrition: [
      LifestyleItem(
        name: 'Iron + Vitamin C Pairing',
        shortDesc: 'Replenish what menstruation takes',
        imageUrl: _ironFoods,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Every meal',
        why: 'Menstrual blood loss depletes iron, causing fatigue, brain fog, and breathlessness. Vitamin C increases non-heme iron absorption by up to 300% — making the pairing essential, especially for plant-based sources.',
        tip: 'Cast iron cookware leaches a small amount of dietary iron into food — a completely passive way to increase your intake with zero dietary changes.',
        steps: [
          'Identify your iron source: spinach, lentils, tofu, red meat, pumpkin seeds, or fortified cereals',
          'Identify your vitamin C source: lemon, orange, strawberries, or bell pepper',
          'Pair them at the same meal — always. Iron without C = poor absorption.',
          'Avoid tea or coffee for 1 hour after your iron-rich meal — tannins block absorption by 65%',
          'Morning option: spinach scrambled eggs with orange juice',
          'Lunch option: lentil soup with a squeeze of lemon and bell pepper on top',
        ],
      ),
      LifestyleItem(
        name: 'Omega-3 Rich Meals',
        shortDesc: 'Reduces cramps directly — using fish already in the palengke',
        imageUrl: _omega3,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Daily',
        why: 'Omega-3 fatty acids directly compete with arachidonic acid in producing prostaglandins. More omega-3 means fewer inflammatory prostaglandins — the compounds that cause uterine contractions and cramping.',
        tip: 'Start eating omega-3 rich foods 3–4 days before your expected period — by the time menstruation begins, the anti-inflammatory effect is already building.',
        steps: [
          'Choose your omega-3 source: galunggong, tulingan, bangus, or a can of sardinas — all budget-friendly',
          'Aim for a fried or tinola-style fish meal at least twice during your period week',
          'Add a spoon of ground flaxseed to oatmeal or lugaw if you have it — optional, not required',
          'Keep roasted mani (peanuts) as your snack throughout the week — the accessible local source',
          'If vegetarian, malunggay and monggo are good plant-based fallbacks',
          'Notice whether cramp intensity differs after 2–3 cycles of consistent intake',
        ],
      ),
      LifestyleItem(
        name: 'Dark Chocolate',
        shortDesc: 'Iron, magnesium & mood in one bite',
        imageUrl: _darkChoc,
        accentColor: Color(0xFFE96A8F),
        duration: '30g daily',
        why: 'Dark chocolate (70%+ cacao) provides iron, magnesium, and zinc — three minerals depleted by menstruation. It also triggers endorphin and serotonin release, providing a genuine mood boost without the inflammatory effects of sugary alternatives.',
        tip: 'The magnesium in dark chocolate works best when you are already well-hydrated. Drink a glass of water before your chocolate ritual.',
        steps: [
          'Choose a quality dark chocolate bar — 70% cacao minimum, 85% is ideal',
          'Portion out approximately 30g — roughly 3 squares of a standard bar',
          'Eat it mindfully: let it melt slowly on your tongue rather than chewing quickly',
          'Pair with a small handful of almonds for additional magnesium and healthy fat',
          'Have it as an afternoon snack when cravings are typically strongest',
          'Avoid combining with caffeine — it can intensify cramping in some women',
        ],
      ),
      LifestyleItem(
        name: 'Ginger & Turmeric Tea',
        shortDesc: 'Natural anti-inflammatory pain relief',
        imageUrl: _gingerTea,
        accentColor: Color(0xFF3BAF7E),
        duration: '2–3 cups daily',
        why: 'Ginger inhibits prostaglandin synthesis — the same mechanism as ibuprofen. Curcumin in turmeric is a potent anti-inflammatory. Together they provide meaningful pain relief without pharmaceutical side effects.',
        tip: 'Always add a pinch of black pepper — it increases curcumin absorption by 2000%. Without it, most of the turmeric passes through completely unused.',
        steps: [
          'Slice 2cm of fresh ginger and 1cm of fresh turmeric root — fresh is far more potent than powder',
          'Add to 400ml of nearly boiling water',
          'Simmer on low heat for 10 full minutes to properly extract the active compounds',
          'Strain into a mug and add a pinch of black pepper — this step is essential',
          'Add honey and a squeeze of lemon to taste',
          'Drink 2–3 cups throughout the day during your heaviest days',
        ],
      ),
    ],
    productivity: [
      LifestyleItem(
        name: 'Light Task Focus',
        shortDesc: 'Work with your phase, not against it',
        imageUrl: _lightTask,
        accentColor: Color(0xFFE96A8F),
        duration: 'Full day',
        why: 'Cognitive load capacity is genuinely reduced during menstruation due to lower estrogen and dopamine. Matching your work to this reduced capacity produces better outcomes and lower stress than forcing peak performance.',
        tip: '"I am investing in my follicular phase" — prep work done during menstruation lets you hit the ground running when energy returns. Reframe rest as deliberate strategy.',
        steps: [
          'At the start of your day, write down only 3 low-demand tasks — no more',
          'Good options: emails, organizing files, reviewing notes, updating calendars',
          'Complete task 1 entirely before opening task 2',
          'Take a 10-minute break after each task — your energy recovers slowly today',
          'When your 3 tasks are done, the day is successful — stop without guilt',
          'Spend the last 20 minutes planning what you want to do in your follicular phase',
        ],
      ),
      LifestyleItem(
        name: 'Reflective Journaling',
        shortDesc: 'The menstrual phase is made for this',
        imageUrl: _journal,
        accentColor: Color(0xFFBC6B9C),
        duration: '15–20 min',
        why: 'The inward, reflective quality of the menstrual phase actually enhances the ability to review and assess honestly. Many women report significant clarity during this phase — thoughts that are clearer than usual. Capturing them in writing is highly productive.',
        tip: 'A monthly reflective journal over 6 cycles becomes an extraordinary personal record — you will see patterns in your thoughts, moods, and life circumstances that are impossible to see in real time.',
        steps: [
          'Find a quiet 15–20 minute window — morning or evening both work well',
          'Start with: "What went well this past cycle? What was hard?"',
          'Continue: "What do I want to do differently next cycle?"',
          'Write about one relationship, one work situation, and one personal goal',
          'End with: "What do I want to feel more of? What can I let go of?"',
          'Read back what you wrote — insights often surprise you when you see them',
        ],
      ),
      LifestyleItem(
        name: 'Say No Gracefully',
        shortDesc: 'Protect your energy on purpose',
        imageUrl: _sayNo,
        accentColor: Color(0xFFE96A8F),
        duration: 'Days 1–3',
        why: 'Social and professional over-commitment during menstruation depletes the limited energy your body has available, prolonging recovery and worsening symptoms. Protecting your energy with appropriate boundaries is not selfishness — it is intelligent resource management.',
        tip: 'Plan your "no" days in advance — it is much easier to decline an invitation a week ahead than to cancel the day of because you feel terrible.',
        steps: [
          'Review your calendar and identify any non-urgent commitments this week',
          'For each one, ask: "Would skipping this cost me less than attending will?"',
          'Prepare your graceful decline: "I won\'t be able to, but I\'d love to next week"',
          'Remove or reschedule optional social events during days 1–3',
          'Set your messaging status to "focused" during your lowest energy hours',
          'Give yourself explicit permission to leave social events early if needed',
        ],
      ),
    ],
  ),

  // ══════════════════════════════════
  //  FOLLICULAR  (Days 6–13)
  // ══════════════════════════════════
  PhaseData(
    name: 'Follicular', emoji: '🌱',
    color: Color(0xFF84B2E9), surface: Color(0xFFE4EDFA),
    subtitle: 'Days 6–13 · Build, create, connect',
    exercise: [
      LifestyleItem(
        name: 'Jogging',
        shortDesc: 'Energy is rising — use it',
        imageUrl: _jogging,
        accentColor: Color(0xFF84B2E9),
        duration: '30–40 min',
        why: 'Rising estrogen increases cardiovascular efficiency and pain tolerance. Your muscles also repair and build faster, making jogging more productive and more enjoyable than at any other phase.',
        tip: 'Track your pace during this phase — follicular phase running times are often your personal fastest. Use them as benchmarks for the whole cycle.',
        steps: [
          'Warm up with 5 minutes of brisk walking and arm swings',
          'Begin at an easy jog — pace where you can speak short sentences',
          'Hold this for 5 minutes and let your cardiovascular system settle',
          'After 10 minutes, push 10–15% harder — your body can handle it this week',
          'Maintain your comfortable-challenging pace for 20 minutes',
          'Cool down with 5 minutes of walking, then stretch hamstrings and calves',
        ],
      ),
      LifestyleItem(
        name: 'Home Strength Training',
        shortDesc: 'Muscles synthesize faster now — no gym needed',
        imageUrl: _strength,
        accentColor: Color(0xFF84B2E9),
        duration: '45–60 min',
        why: 'Estrogen enhances muscle protein synthesis — your muscles literally grow and repair faster in the follicular phase than at any other point in your cycle. This is scientifically the most productive time to build strength.',
        tip: 'Keep a simple log of your reps and loads and mark which sessions are in your follicular phase. Over 3–4 cycles, you will see your strongest sessions consistently clustering here.',
        steps: [
          'Dynamic warm-up: 5 minutes of leg swings, arm circles, and hip rotations',
          'Bodyweight squats or lunges — 3–4 sets × 12–15 reps',
          'Hold a filled 6L water jug or a small rice sack in each hand for added load',
          'Push-ups (knee or full) and doorframe or resistance-band rows — 3 sets each',
          'Finish with 10 minutes of core work: planks, sit-ups, or leg raises',
          'Write down your reps and loads — aim to beat them next follicular phase',
        ],
      ),
      LifestyleItem(
        name: 'HIIT',
        shortDesc: 'Maximum adaptation, minimum time',
        imageUrl: _hiit,
        accentColor: Color(0xFF84B2E9),
        duration: '25–35 min',
        why: 'HIIT produces its greatest training adaptations when recovery capacity is high — which it genuinely is during the follicular phase. Estrogen also buffers the cortisol spike from intense exercise, making HIIT less stressful now than in the luteal phase.',
        tip: 'Soreness after HIIT is significantly lower in the follicular phase than the same session in the luteal phase. Your body is telling you something important.',
        steps: [
          'Dynamic warm-up: 5 minutes of jumping jacks, high knees, and arm circles',
          'Jump Squats: 20 sec all-out, 10 sec rest, 8 rounds',
          'Rest fully for 2 minutes — walk around and drink water',
          'Burpees: 20 sec max effort, 10 sec rest, 8 rounds',
          'Rest 2 more minutes',
          'Cool down: 5 minutes of walking then hip flexors and hamstring stretch',
        ],
        stepImages: [
          'assets/images/lifestyle/hiit/highknee_step1.png',
          'assets/images/lifestyle/hiit/jumpsquat_step3.png',
          'assets/images/lifestyle/hiit/jumpsquat_step5.png',
          'assets/images/lifestyle/hiit/burpee_step5.png',
          'assets/images/lifestyle/hiit/burpee_step1.png',
          'assets/images/lifestyle/hiit/highknee_step5.png',
        ],
      ),
      LifestyleItem(
        name: 'Cycling',
        shortDesc: 'Cardio feels significantly easier',
        imageUrl: _cycling,
        accentColor: Color(0xFF84B2E9),
        duration: '40–50 min',
        why: 'Estrogen improves cardiac output and oxygen utilization, making sustained cardio like cycling feel notably easier. Many women experience faster times and less perceived effort on the same routes during this phase.',
        tip: 'If you use a fitness tracker, your resting heart rate will be at its lowest during the follicular phase — a useful indicator of where you are in your cycle.',
        steps: [
          'Warm up with 5 minutes of easy pedaling to get blood flowing',
          'Begin your interval session: 2 minutes hard effort, 2 minutes easy — repeat 6–8 times',
          'Keep hard efforts at about 80% max — challenging but sustainable',
          'Between intervals, maintain a gentle recovery pace rather than stopping',
          'Cool down with 5 minutes of easy cycling',
          'Stretch your quads, hamstrings, and calves after — your recovery is efficient today',
        ],
      ),
      LifestyleItem(
        name: 'Swimming',
        shortDesc: 'Full body endurance training',
        imageUrl: _swimming,
        accentColor: Color(0xFF84B2E9),
        duration: '40–50 min',
        why: 'Your pain tolerance is high and cardiovascular efficiency is improved during the follicular phase. Swimming allows genuinely challenging intensity with the benefit of water resistance and reduced joint load.',
        tip: 'The follicular phase is the best time to learn new swimming techniques or increase training volume. Your neuromuscular coordination is at its sharpest.',
        steps: [
          'Warm up with 200m easy freestyle — focus on breathing rhythm',
          'Main set: 4×100m at your comfortable-challenging pace with 30 sec rest between each',
          'Add a drill set: 4×50m focusing on technique — catch, pull, and rotation',
          'Push the pace in your final 2×100m — you have the energy today',
          'Cool down with 100m very easy backstroke',
          'Time your 100m splits — compare with your luteal phase times next cycle',
        ],
      ),
    ],
    sleep: [
      LifestyleItem(
        name: 'Consistent Sleep Times',
        shortDesc: 'Train your circadian rhythm now',
        imageUrl: _sleep8h,
        accentColor: Color(0xFF84B2E9),
        duration: 'Every night',
        why: 'The follicular phase is when natural sleep quality begins to improve after menstruation. Establishing consistent bedtimes now trains your circadian rhythm for better sleep across the entire cycle.',
        tip: 'Your body actually anticipates your regular wake time and begins raising cortisol 30–60 minutes before. Consistent timing makes mornings noticeably easier within just 2 weeks.',
        steps: [
          'Choose a bedtime and wake time you can maintain every day, including weekends',
          'Set a bedtime alarm — as important as a wake alarm — 60 min before your target',
          'Begin winding down immediately when it sounds',
          'Step outside within 30 minutes of waking for natural light exposure',
          'Stay within 30 minutes of your target times on weekends — protect the rhythm',
          'After one week of consistency, note how your mornings feel compared to before',
        ],
      ),
      LifestyleItem(
        name: 'Morning Light Exposure',
        shortDesc: 'Sets your circadian clock for the day',
        imageUrl: _morningLight,
        accentColor: Color(0xFF84B2E9),
        duration: '10–20 min on waking',
        why: 'Morning natural light enters your eyes and directly suppresses melatonin while setting your circadian clock. This improves sleep onset at night and makes mornings more energizing. Even cloudy outdoor light is 10x brighter than indoor lighting.',
        tip: 'Consistent morning light exposure combined with consistent wake times is more effective than any sleep supplement for improving sleep quality. It is free and takes 10 minutes.',
        steps: [
          'Within 30 minutes of waking, step outside or sit near a bright window',
          'Do not wear sunglasses for the first 10 minutes — let the light reach your eyes',
          'Make your morning coffee or tea and drink it outside if possible',
          'Walk, stretch, or simply stand — movement is a bonus, not required',
          'Do this even on cloudy days — cloud-filtered light is still far brighter than indoors',
          'After 2 weeks of consistency, note that falling asleep at night becomes easier',
        ],
      ),
    ],
    nutrition: [
      LifestyleItem(
        name: 'Protein at Every Meal',
        shortDesc: 'Feed the muscle-building signal',
        imageUrl: _protein,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Every meal',
        why: 'Rising estrogen activates muscle protein synthesis — but only when adequate dietary protein is available. Without enough protein, the hormonal signal to build muscle cannot be fully utilized. This is one of the most common training errors.',
        tip: 'Distributing protein across 4–5 meals produces 25% more muscle protein synthesis than the same daily total consumed mostly at dinner. Timing matters as much as total intake.',
        steps: [
          'Calculate your target: weight in kg × 1.8 = your daily protein grams',
          'Breakfast: 3 eggs with smoked salmon or Greek yogurt with seeds (25–30g)',
          'Post-workout: 25–30g of protein within 30 minutes of finishing training',
          'Lunch: chicken, tuna, tofu, or lentils as your main (25–30g)',
          'Dinner: a complete protein source — not just incidental amounts from grains',
          'Aim for 4–5 meals with 25–30g each — your body uses it better distributed',
        ],
      ),
      LifestyleItem(
        name: 'Local Fermented Foods',
        shortDesc: 'Supports healthy estrogen metabolism — from the sari-sari store',
        imageUrl: _phaseEating,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Daily',
        why: 'Estrogen is metabolized by the gut microbiome. A diverse, healthy microbiome ensures estrogen is cleared efficiently — preventing both low estrogen and estrogen dominance. Fermented foods feed beneficial gut bacteria directly.',
        tip: 'You don\'t need imported kimchi or kombucha for this — atchara, plain yogurt, and Yakult are sold at any sari-sari store and give the same live-culture benefit.',
        steps: [
          'Choose your fermented food: atchara (pickled papaya), plain yogurt, or a bottle of Yakult',
          'Add atchara as a side to fried or grilled dishes at lunch or dinner',
          'Stir plain yogurt into rice porridge or eat it with banana for breakfast',
          'Use patis or bagoong in small amounts for an easy umami and fermented boost',
          'Pair fermented foods with onion or garlic-heavy ulam to feed the beneficial bacteria',
          'Rotate between atchara, yogurt, and Yakult through the week for variety',
        ],
      ),
      LifestyleItem(
        name: 'Complex Carbohydrates',
        shortDesc: 'Sustained energy for peak training',
imageUrl: _serotoninFood,        accentColor: Color(0xFF3BAF7E),
        duration: 'Around workouts',
        why: 'Complex carbohydrates provide sustained glucose for higher-intensity exercise that is optimal in the follicular phase, without the blood sugar spikes of refined carbohydrates. They also support serotonin production.',
        tip: 'Oats are one of the most researched foods for sustained energy. Overnight oats prepared the night before make the perfect pre-workout breakfast requiring zero morning effort.',
        steps: [
          '1–2 hours before training: eat complex carbs + protein — oatmeal with banana, or sweet potato with eggs',
          'Avoid refined carbs pre-workout: white bread and sugary foods cause energy crashes mid-session',
          'Post-workout: include brown rice, quinoa, or sweet potato in your recovery meal',
          'Throughout the day: whole grain bread, legumes, or oats as your carbohydrate base',
          'Pair all carbohydrates with protein and fat to slow absorption and maintain stable energy',
          'Notice how your energy during training differs when you fuel properly vs not',
        ],
      ),
    ],
    productivity: [
      LifestyleItem(
        name: 'Deep Work Sessions',
        shortDesc: 'Your cognitive peak — protect it',
imageUrl: _highStakes,        accentColor: Color(0xFF84B2E9),
        duration: '2–4 hours daily',
        why: 'Working memory, processing speed, verbal fluency, and problem-solving ability are all measurably enhanced by estrogen in the follicular phase. Research confirms women perform better on cognitive tests during this phase.',
        tip: 'Schedule all meetings in the afternoon of follicular phase days. Keep mornings completely clear for focused work. This single change transforms weekly output.',
        steps: [
          'Block 2–4 hours in your calendar as a non-negotiable appointment — no meetings',
          'In the first 5 minutes, write exactly what you will have produced by the end',
          'Close email, Slack, and all irrelevant tabs before starting',
          'Put your phone in another room or on Do Not Disturb',
          'Work for 90 minutes, then take a genuine 20-minute break — walk or move',
          'Before finishing, write 3 bullet points about where you left off',
        ],
      ),
      LifestyleItem(
        name: 'Launch New Projects',
        shortDesc: 'Your best window for beginnings',
        imageUrl: _organize,
        accentColor: Color(0xFF84B2E9),
        duration: 'Full week',
        why: 'Rising dopamine and estrogen in the follicular phase creates a neurological state of openness, optimism, and motivation that is genuinely better for starting new things than other phases. Novelty-seeking behavior peaks now.',
        tip: 'The follicular phase is the best time to overcome procrastination on things you have been avoiding. The lower anxiety and higher motivation mean the psychological cost of starting is genuinely lower.',
        steps: [
          'Review the project plan you made during your menstrual phase',
          'Take the single most important first step — today, not tomorrow',
          'Send the email, make the call, open the document, or have the conversation',
          'Tell one person about the project — social commitment increases follow-through significantly',
          'Create a visible system to track your progress during this phase',
          'Build on the momentum each day while your energy is high this week',
        ],
      ),
      LifestyleItem(
        name: 'Networking & Connection',
        shortDesc: 'Social energy is naturally high',
        imageUrl: _network,
        accentColor: Color(0xFF84B2E9),
        duration: 'Full week',
        why: 'Estrogen increases production of oxytocin (the connection hormone) and serotonin, making social interactions both easier and more rewarding in the follicular phase. This is your natural social peak — lean into it professionally and personally.',
        tip: 'First impressions made in the follicular phase tend to be more positive — your natural warmth and openness are at their peak. Try to make important new professional introductions during this window.',
        steps: [
          'Identify 1–2 networking opportunities this week: events, coffee chats, or check-ins',
          'Reach out to one person you have been meaning to connect with — do it today',
          'Accept social invitations you might otherwise decline — you will enjoy them more now',
          'In professional conversations, let your natural curiosity and warmth lead',
          'Follow up with new connections within 24 hours while the energy is still high',
          'Host or organize a team lunch or group activity — your facilitation is strongest now',
        ],
      ),
    ],
  ),

  // ══════════════════════════════════
  //  OVULATION  (Days 12–17)
  // ══════════════════════════════════
  PhaseData(
    name: 'Ovulation', emoji: '🌟',
    color: Color(0xFF6BB89E), surface: Color(0xFFE2F5ED),
    subtitle: 'Days 12–17 · Peak — perform & lead',
    exercise: [
      LifestyleItem(
        name: 'Bodyweight Power Circuit',
        shortDesc: 'Your absolute peak strength window — no barbell needed',
        imageUrl: _heavylift,
        accentColor: Color(0xFF6BB89E),
        duration: '60–75 min',
        why: 'Estrogen is at its absolute peak around ovulation, maximizing muscle strength, power output, and pain tolerance simultaneously. This is the single best time in your cycle to push your hardest effort yet.',
        tip: 'Keep a simple log of your reps and loads — your best numbers will almost always cluster in the ovulation and late follicular phases. This pattern repeats every single cycle.',
        steps: [
          'Warm up thoroughly: 10 minutes of dynamic movement',
          'Jump squats or pistol-squat progressions — 4–5 sets of max clean reps',
          'Push-ups (add a backpack with books for extra load) — 4 sets to near-failure',
          'If feeling strong, add more reps or a heavier household object than last time',
          'Finish with resistance-band rows and standing lunges — 3 sets each',
          'Cool down fully — stretch every major muscle group you worked',
        ],
      ),
      LifestyleItem(
        name: 'Power Yoga',
        shortDesc: 'Strength, flow, and peak confidence',
        imageUrl: _poweryoga,
        accentColor: Color(0xFF6BB89E),
        duration: '60–75 min',
        why: 'Power yoga engages strength, coordination, balance, and flexibility simultaneously. Peak estrogen makes all these capacities available at once — making ovulation your best phase for challenging yoga.',
        tip: 'Flexibility measurably increases around ovulation due to estrogen\'s effect on joint laxity. You can go deeper than usual — but stay mindful. Laxity also means higher injury risk if you force.',
        steps: [
          'Set an intention before class begins: strength, presence, or openness',
          'Flow through 5 rounds of sun salutations — synchronize movement with breath',
          'Hold Warrior II for 8 full breaths each side — longer than your usual practice',
          'Attempt challenge poses: arm balances, headstand, or deep backbends',
          'Notice that these feel more accessible than usual — this is real and hormonal',
          'Rest completely in Savasana for at least 10 minutes — let the practice integrate',
        ],
        stepImages: [
          'assets/images/lifestyle/yoga/poweryoga_step1.png',
          'assets/images/lifestyle/yoga/poweryoga_step2.png',
          'assets/images/lifestyle/yoga/poweryoga_step3.png',
          'assets/images/lifestyle/yoga/poweryoga_step4.png',
          'assets/images/lifestyle/yoga/poweryoga_step4.png',
          'assets/images/lifestyle/yoga/poweryoga_step5.png',
        ],
      ),
      LifestyleItem(
        name: 'HIIT at Full Intensity',
        shortDesc: 'Maximum effort — your body can take it',
        imageUrl: _hiit,
        accentColor: Color(0xFF6BB89E),
        duration: '30–40 min',
        why: 'Peak estrogen at ovulation raises your pain threshold, increases adrenaline sensitivity, and maximizes your anaerobic capacity. Ovulation-phase HIIT produces the strongest training adaptations of any phase.',
        tip: 'Ovulation-phase HIIT produces peak EPOC — you continue burning calories at an elevated rate for 24–36 hours after the session. The investment compounds significantly.',
        steps: [
          'Dynamic warm-up: 5 minutes until you feel genuinely hot and activated',
          'Jump Squats: 20 sec all-out, 10 sec rest, 8 rounds (4 minutes)',
          'Rest 2 full minutes — walk around and drink water',
          'Burpees: 20 sec max effort, 10 sec rest, 8 rounds',
          'Rest 2 more minutes',
          'Mountain Climbers: 8 rounds, maximum speed on every rep',
        ],
        stepImages: [
          'assets/images/lifestyle/hiit/jumpsquat_step1.png',
          'assets/images/lifestyle/hiit/jumpsquat_step3.png',
          'assets/images/lifestyle/hiit/jumpsquat_step5.png',
          'assets/images/lifestyle/hiit/burpee_step5.png',
          'assets/images/lifestyle/hiit/burpee_step1.png',
          'assets/images/lifestyle/hiit/mountainclimber_step4.png',
        ],
      ),
    ],
    sleep: [
      LifestyleItem(
        name: 'Protect Your Sleep Rhythm',
        shortDesc: 'Don\'t let peak energy steal your sleep',
        imageUrl: _sleep8h,
        accentColor: Color(0xFF6BB89E),
        duration: 'Nightly',
        why: 'High energy and elevated mood during ovulation can lead to later bedtimes — which undermines recovery from peak training and can disrupt the hormonal transition into the luteal phase that follows.',
        tip: 'Sleep debt accumulated during late ovulation-phase nights often appears as worsened PMS 7–10 days later. Protecting sleep now is direct prevention of future symptoms.',
        steps: [
          'Keep your usual bedtime even if you do not feel tired — the feeling is hormonal',
          'Start your wind-down routine at the same time as always',
          'Set a hard social media cutoff at 9pm — your social drive makes it hard but necessary',
          'Do 15 minutes of stretching targeting the muscles worked in today\'s training',
          'Take magnesium glycinate 300mg before bed to support recovery and sleep onset',
          'Trust the routine — your body responds to established cues even when your mind is active',
        ],
      ),
      LifestyleItem(
        name: 'Evening Stretch for Recovery',
        shortDesc: 'Accelerates recovery from peak training',
        imageUrl: _stretching,
        accentColor: Color(0xFF6BB89E),
        duration: '15 min',
        why: 'The high-intensity exercise of ovulation creates greater muscle fiber stress than lighter phases. A consistent evening stretching routine accelerates recovery by increasing blood flow to stressed muscles and reducing delayed onset muscle soreness.',
        tip: 'Foam rolling before stretching during heavy training weeks increases the effectiveness of stretching by up to 35%. Spend 5 minutes on the foam roller before your evening stretch.',
        steps: [
          'Begin with seated hamstring stretch: 60 seconds each leg',
          'Hip flexor kneeling stretch: 60 seconds each side',
          'Pigeon pose or figure-four stretch for glutes: 90 seconds each side',
          'Cross-body shoulder stretch and chest opener: 45 seconds each',
          'Thoracic rotation: lying, knees bent, rotate to each side — 60 seconds each',
          'Finish lying on your back, knees to chest — 2 minutes, breathe slowly',
        ],
        stepImages: [
          'assets/images/lifestyle/stretching/poststretch_step1.png',
          'assets/images/lifestyle/stretching/poststretch_step2.png',
          'assets/images/lifestyle/stretching/poststretch_step3.png',
          'assets/images/lifestyle/stretching/poststretch_step4.png',
          'assets/images/lifestyle/stretching/poststretch_step5.png',
          'assets/images/lifestyle/stretching/poststretch_step5.png',
        ],
      ),
    ],
    nutrition: [
      LifestyleItem(
        name: 'Peak Protein Intake',
        shortDesc: 'Feed the highest-output phase',
        imageUrl: _protein,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Every meal',
        why: 'The muscle stress from peak ovulation training requires abundant protein for repair and adaptation. Protein synthesis is maximally efficient when training intensity is highest. Missing protein intake during your peak phase is the most common error that limits progress.',
        tip: 'Spreading protein across meals (not just at dinner) produces 25% more muscle protein synthesis. Eating a carbohydrate alongside tryptophan-rich protein also amplifies the mood benefit.',
        steps: [
          'Target: weight in kg × 2 = your daily protein gram target this week',
          'Pre-workout: complex carbs + protein 1–2 hours before (sweet potato + eggs)',
          'Within 30 minutes of finishing training: 25–30g protein — don\'t skip this',
          'Lunch: salmon, chicken, or legumes with plenty of vegetables',
          'Dinner: a complete protein source with anti-inflammatory vegetables',
          'Check your total before bed — aim for 4–5 protein-containing meals today',
        ],
      ),
      LifestyleItem(
        name: 'Anti-inflammatory Foods',
        shortDesc: 'Speed recovery between peak sessions — turmeric, ginger, and fish already in your kitchen',
        imageUrl: _antInflam,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Every meal',
        why: 'Peak training during ovulation creates significant exercise-induced inflammation. While some inflammation is necessary for adaptation, dietary anti-inflammatories help modulate this response without the side effects of NSAIDs.',
        tip: 'Curcumin (active compound in turmeric) has anti-inflammatory potency comparable to some NSAIDs. Always take with black pepper and fat — without them, most of it passes through unused.',
        steps: [
          'Add 1 tsp turmeric + pinch black pepper to your morning smoothie or eggs',
          'Make ginger (luya) tea: fresh ginger steeped 10 minutes, with honey and black pepper',
          'Include galunggong, tulingan, or canned sardines at least twice this week',
          'Add ripe mangga or saging to breakfast — a strong, affordable antioxidant source',
          'Cook with coconut oil or a light vegetable oil instead of pricier imported oils',
          'Snack on roasted mani — the accessible local source of healthy fats',
        ],
      ),
      LifestyleItem(
        name: 'Electrolyte Hydration',
        shortDesc: 'Replace what peak exercise takes',
        imageUrl: _hydration,
        accentColor: Color(0xFF3BAF7E),
        duration: 'During & after training',
        why: 'Peak training during ovulation creates higher sweat rates. Replacing only water without electrolytes creates hyponatremia (low sodium) — which worsens performance and recovery in ways that plain water cannot fix.',
        tip: 'Pink Himalayan sea salt contains a wider range of trace minerals than standard table salt. Using it in homemade electrolyte drinks provides broader mineral replacement.',
        steps: [
          'For sessions under 60 minutes: water alone is sufficient',
          'For sessions over 60 minutes: use an electrolyte drink during the session',
          'Homemade option: 500ml water + pinch sea salt + squeeze lemon + 1 tsp honey',
          'Post-workout: electrolyte drink plus a protein-rich meal within 30 minutes',
          'Coconut water is a natural electrolyte drink — 1 cup provides potassium and sodium',
          'Check your urine color: pale yellow = well hydrated, dark yellow = drink more',
        ],
      ),
    ],
    productivity: [
      LifestyleItem(
        name: 'Lead & Present',
        shortDesc: 'Your most powerful communication phase',
        imageUrl: _present,
        accentColor: Color(0xFF6BB89E),
        duration: 'This week',
        why: 'The brief testosterone rise at ovulation, combined with peak estrogen, creates a unique combination of confidence, assertiveness, and warmth. Verbal fluency, persuasiveness, and confidence are measurably at their peak.',
        tip: 'Research shows women in leadership roles are rated most positively by peers when presenting during their follicular and ovulation phases. This is measurable and reproducible.',
        steps: [
          'Schedule important presentations, pitches, or key meetings this week',
          'Volunteer to lead the meeting or take charge of the project — your leadership is peak',
          'Make the decision that has been pending — your judgment and confidence are genuine',
          'Have the difficult conversation — assertiveness + peak empathy make this optimal',
          'Give feedback clearly and constructively — your communication is most effective now',
          'Negotiate or advocate for yourself — this is the best week in your cycle to ask',
        ],
      ),
      LifestyleItem(
        name: 'High-Stakes Execution',
        shortDesc: 'Perform under pressure this week',
        imageUrl: _deepWork,
        accentColor: Color(0xFF6BB89E),
        duration: 'As scheduled',
        why: 'Stress performance — executing well under pressure — is enhanced by the testosterone-estrogen combination of ovulation. The anxiety that degrades performance under pressure is lowest now. Save your highest-stakes execution for this window.',
        tip: 'The difference between anxiety and excitement is the story you tell about physiological arousal. During ovulation, reframing "I\'m nervous" as "I\'m activated and ready" is particularly effective.',
        steps: [
          'Identify your highest-stakes upcoming task or event',
          'Schedule or request a date in your projected ovulation phase if flexibility exists',
          'Prepare thoroughly in advance — this window is for execution, not preparation',
          'On the day: use the activation you feel as performance fuel, not anxiety to suppress',
          'Make eye contact, speak clearly — your presence is genuinely more compelling now',
          'Debrief honestly after — note what worked so you can replicate it next cycle',
        ],
      ),
    ],
  ),

  // ══════════════════════════════════
  //  LUTEAL  (Days 15–28)
  // ══════════════════════════════════
  PhaseData(
    name: 'Luteal', emoji: '🌿',
    color: Color(0xFFBC6B9C), surface: Color(0xFFF5EAF7),
    subtitle: 'Days 15–28 · Maintain, complete, nourish',
    exercise: [
      LifestyleItem(
        name: 'Yin Yoga',
        shortDesc: 'Calms PMS from the inside out',
        imageUrl: _restoreyoga,
        accentColor: Color(0xFFBC6B9C),
        duration: '30–45 min',
        why: 'Progesterone-dominant luteal phase raises cortisol sensitivity and amplifies stress responses. Yin yoga activates the parasympathetic nervous system and measurably reduces cortisol, directly counteracting the hormonal stress of this phase.',
        tip: 'Yin yoga\'s long-held, passive poses match the natural "letting go" quality of the end-of-cycle phase. Lean into this rather than fighting the slower energy.',
        steps: [
          'Set up in a warm, quiet space with soft lighting — take 5 slow breaths before moving',
          'Supine twist: hold 3 full minutes each side, let gravity do all the work',
          'Yin pigeon: from all fours, right shin toward front of mat — hold 3 min each side',
          'Seated forward fold: legs extended, fold forward completely — hold 5 minutes',
          'This 5-minute hold is deeply calming for the nervous system — stay with it',
          'Finish with 10-minute Yoga Nidra using a guided audio — do not skip this',
        ],
        stepImages: [
          'assets/images/lifestyle/yoga/yinyoga_step1.png',
          'assets/images/lifestyle/yoga/yinyoga_step2.png',
          'assets/images/lifestyle/yoga/yinyoga_step3.png',
          'assets/images/lifestyle/yoga/yinyoga_step4.png',
          'assets/images/lifestyle/yoga/yinyoga_step4.png',
          'assets/images/lifestyle/yoga/yinyoga_step5.png',
        ],
      ),
      LifestyleItem(
        name: 'Daily Walking',
        shortDesc: 'The perfect luteal phase exercise',
        imageUrl: _walking,
        accentColor: Color(0xFFBC6B9C),
        duration: '20–40 min daily',
        why: 'Walking raises serotonin and endorphins (reducing PMS), improves blood flow (reducing bloating), and keeps cortisol appropriately low — without the cortisol spike that intense exercise produces and the luteal phase amplifies.',
        tip: 'Walking in nature specifically provides additional cortisol reduction. A tree-lined street is measurably more effective than an urban pavement for the same duration.',
        steps: [
          'Put on comfortable shoes and step outside — no pace goal, no distance target',
          'Let your body set the pace: slower than your follicular phase pace is correct',
          'Notice your surroundings: sounds, textures, smells, temperature',
          'This sensory awareness reduces cortisol and improves mood within 10 minutes',
          'Take one slow deep breath every 3–4 steps — rhythmic breathing keeps you parasympathetic',
          'After 20–40 minutes, return and notice the mood shift — the endorphins are real',
        ],
      ),
      LifestyleItem(
        name: 'Pilates',
        shortDesc: 'Core strength without draining recovery',
        imageUrl: _pilates,
        accentColor: Color(0xFFBC6B9C),
        duration: '30–40 min',
        why: 'Pilates builds core and pelvic floor strength through controlled, low-impact movements. Stronger pelvic floor muscles over time correlate with reduced menstrual pain in the following cycle — making luteal phase Pilates a direct investment in your next menstruation.',
        tip: 'Classical mat Pilates is free, accessible, and perfectly suited to the luteal phase. The precision required keeps you mentally present without demanding high output.',
        steps: [
          'Begin with 5 minutes of lateral rib breathing: breathe sideways into ribs, not belly',
          'Pelvic tilts: 10 slow reps — inhale to arch, exhale to press into mat',
          'Clam shells: 10 each side — keep feet together, lift top knee, squeeze at top',
          'Glute bridges: 10 reps — hold 2 seconds at top, lower slowly feeling each vertebra',
          'Leg slides: 10 each side — slide heel along mat, keep core gently engaged',
          'Finish with 5 minutes of Pilates breathing and spine stretch forward',
        ],
        stepImages: [
          'assets/images/lifestyle/pilates/pilates_step1.png',
          'assets/images/lifestyle/pilates/pilates_step2.png',
          'assets/images/lifestyle/pilates/pilates_step3.png',
          'assets/images/lifestyle/pilates/pilates_step4.png',
          'assets/images/lifestyle/pilates/pilates_step5.png',
          'assets/images/lifestyle/pilates/pilates_step6.png',
        ],
      ),
      LifestyleItem(
        name: 'Easy Cycling',
        shortDesc: 'Low-impact, meditative movement',
        imageUrl: _cycling,
        accentColor: Color(0xFFBC6B9C),
        duration: '30–45 min',
        why: 'Easy cycling provides cardiovascular benefit without the cortisol spike of high-intensity work. The rhythmic pedaling is meditative and reduces anxiety — a key benefit during the late luteal phase when emotional regulation is naturally lower.',
        tip: 'Outdoor cycling in natural light combines cortisol reduction from nature exposure with the serotonin boost of gentle exercise — especially useful for PMS mood management.',
        steps: [
          'Choose a comfortable route with flat or gently rolling terrain',
          'Set off at a pace where you could easily hold a full conversation',
          'Breathe rhythmically with your pedaling — this synchronization reduces cortisol',
          'Enjoy the scenery: this is recovery movement, not performance',
          'Aim for 30–45 minutes at this consistently easy pace',
          'After: stretch your hip flexors — cycling shortens these and worsens lower back pain',
        ],
      ),
    ],
    sleep: [
      LifestyleItem(
        name: 'Cool Room + Magnesium',
        shortDesc: 'Progesterone raises your temperature',
        imageUrl: _coolRoom,
        accentColor: Color(0xFFBC6B9C),
        duration: 'Every night',
        why: 'Progesterone raises basal body temperature by 0.3–0.5°C in the luteal phase. Your sleep environment needs to be cooler than usual to compensate for this internal temperature rise so your core temperature can drop enough for deep sleep.',
        tip: 'Magnesium glycinate is the most evidence-based non-pharmaceutical sleep aid for PMS. The glycinate form crosses the blood-brain barrier and has direct GABA-promoting effects. Effects build over consecutive nights.',
        steps: [
          'Set your room temperature 1–2°C lower than your usual: aim for 15–17°C',
          'Switch to lighter bedding: a cotton sheet instead of your usual duvet if needed',
          'Take 300–400mg magnesium glycinate with water 30 minutes before bed',
          'Avoid alcohol entirely this week — even one drink suppresses REM sleep significantly',
          'Write your worry journal before bed: anxious thoughts onto paper, then close it',
          'Get into bed with no phone — your body will respond to the established cue',
        ],
      ),
      LifestyleItem(
        name: 'Worry Journal',
        shortDesc: 'Clear anxious thoughts before sleep',
        imageUrl: _journalBed,
        accentColor: Color(0xFFBC6B9C),
        duration: '10–15 min',
        why: 'Anxiety and rumination are at their peak in the late luteal phase due to progesterone withdrawal. Writing worries before bed externalizes them from working memory, reducing the mental activity that delays sleep onset.',
        tip: 'Writing "this is out of my control — I accept this" on paper is more effective at stopping rumination than telling yourself the same thing mentally. The externalization is what matters.',
        steps: [
          'Sit at a desk or table (not in bed) with a dedicated notebook and pen',
          'Title the page: "Current concerns — letting them go for tonight"',
          'Write every worry and anxious thought currently on your mind — be specific',
          'For each item, write either: "Action I can take: ___" or "This is out of my control — I accept this"',
          'Close the notebook firmly — these items are now safely stored outside your head',
          'If a worry resurfaces in bed, remind yourself: "It\'s in the notebook"',
        ],
      ),
      LifestyleItem(
        name: 'Valerian Tea Before Bed',
        shortDesc: 'Natural sleep support for PMS week',
        imageUrl: _chamomile,
        accentColor: Color(0xFFBC6B9C),
        duration: '30 min before bed',
        why: 'Valerian root acts on GABA receptors similarly to benzodiazepines but without dependence potential. Research shows valerian reduces time to fall asleep and improves sleep quality specifically in women with PMS. Effects build over 3–5 consecutive nights.',
        tip: 'Valerian has an earthy, unusual flavor. Most women prefer it blended with chamomile — most commercial "sleep blend" teas contain both. The combination is more effective than either alone.',
        steps: [
          'Steep valerian root or a valerian-chamomile blend tea for 10 full minutes',
          'Add honey and lemon if desired — honey has mild anxiolytic properties',
          'Drink slowly 30–45 minutes before your target bedtime',
          'Combine with your other wind-down activities: journaling, stretching, or reading',
          'Maintain this routine every night during the late luteal phase for cumulative benefit',
          'By night 3–4 of consistent use, the sleep improvement becomes more pronounced',
        ],
      ),
    ],
    nutrition: [
      LifestyleItem(
        name: 'Magnesium-Rich Foods',
        shortDesc: 'The most important PMS mineral — monggo, malunggay, and tablea already in the kitchen',
        imageUrl: _magnesiumFoods,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Every meal',
        why: 'Magnesium is depleted by progesterone in the luteal phase. Low magnesium directly contributes to PMS symptoms including anxiety, irritability, insomnia, bloating, and cramps. Consistently increasing intake significantly reduces PMS severity.',
        tip: 'You don\'t need pricey seeds or supplements for this — monggo, malunggay, and kangkong are cheap, everyday ingredients that deliver the same magnesium.',
        steps: [
          'Morning: banana in oatmeal or lugaw — a meaningful portion of your daily requirement before 9am',
          'Lunch: monggo with malunggay leaves — a classic, cheap magnesium-rich ulam',
          'Add sautéed kangkong as your vegetable side — more potent than raw spinach',
          'Afternoon snack: a small piece of tablea or 70%+ dark chocolate (mood boost too)',
          'Dinner: monggo or black beans as your protein again if needed',
          'If cramps or PMS are severe, ask a doctor before adding any supplement',
        ],
      ),
      LifestyleItem(
        name: 'Serotonin-Supporting Foods',
        shortDesc: 'Fight the PMS mood dip naturally — chicken, tilapia, and kamote instead',
        imageUrl: _complex,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Every meal',
        why: 'Serotonin drops as estrogen falls in the late luteal phase — this is the direct cause of PMS mood symptoms. Tryptophan from food, combined with complex carbohydrates, can replenish serotonin production naturally.',
        tip: 'Your carbohydrate cravings in PMS week are literally your brain requesting the serotonin precursor transport system. Satisfy them with complex carbs, not refined sugar.',
        steps: [
          'Breakfast: eggs or plain yogurt on rice or wholegrain toast (complex carb)',
          'The carbohydrate is required: it transports tryptophan across the blood-brain barrier',
          'Lunch: chicken or tilapia with rice and a green vegetable side',
          'Afternoon: plain yogurt with a banana — tryptophan + carb combination',
          'Dinner: bangus or tofu with kamote (sweet potato) and leafy greens',
          'Avoid high-sugar foods that spike and crash blood sugar and worsen PMS mood swings',
        ],
      ),
      LifestyleItem(
        name: 'Calcium Daily',
        shortDesc: 'Proven PMS reducer — start today',
        imageUrl: _calcium,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Daily',
        why: 'Calcium has some of the strongest evidence of any single nutrient for PMS relief. Multiple clinical trials show that 1,000–1,200mg daily significantly reduces PMS mood symptoms, bloating, cramps, and cravings — with effects comparable to some pharmaceutical interventions.',
        tip: 'Vitamin D is required for calcium absorption. Aim for 10–20 minutes of skin exposed to sunlight daily to support vitamin D levels, which then enables the calcium you eat to be properly absorbed.',
        steps: [
          'Breakfast: 1 cup milk or fortified oat milk in oatmeal or coffee (300mg calcium)',
          'Lunch: 30g cheese in salad or on wholegrain (200mg)',
          'Afternoon: Greek yogurt with fruit (200mg)',
          'Dinner: broccoli or bok choy as your vegetable side (60mg each) + another glass of milk or plant milk',
          'Total target: approximately 1,000–1,100mg from food daily',
          'Avoid taking calcium at the same time as iron-rich foods — they compete for absorption',
        ],
      ),
      LifestyleItem(
        name: 'Reduce Sodium',
        shortDesc: 'Directly reduces bloating',
        imageUrl: _hydration,
        accentColor: Color(0xFF3BAF7E),
        duration: 'Days 20–28',
        why: 'Progesterone causes the body to retain sodium, which pulls water into tissues — creating the bloated, heavy feeling of the late luteal phase. Reducing dietary sodium during this window directly reduces water retention and provides meaningful physical relief.',
        tip: 'If you are craving salt specifically, it may indicate low electrolytes. Try adding potassium-rich foods (banana, avocado, spinach) rather than more sodium.',
        steps: [
          'Remove the salt shaker from your table for the rest of this week',
          'Check labels on any packaged food: aim for under 400mg sodium per serving',
          'Eliminate takeaway food during days 20–25 — restaurant food is very high in sodium',
          'Season food with lemon, garlic, herbs, chili, and vinegar instead of salt',
          'Drink extra water: it helps flush retained sodium through your kidneys',
          'Eat potassium-rich foods daily: banana, avocado, spinach — they directly counteract sodium retention',
        ],
      ),
    ],
    productivity: [
      LifestyleItem(
        name: 'Complete & Close',
        shortDesc: 'Finishing is your superpower now',
        imageUrl: _complete,
        accentColor: Color(0xFFBC6B9C),
        duration: 'Full week',
        why: 'The luteal phase brain has naturally stronger attention to detail and a preference for completion over initiation. These qualities make finishing ongoing projects significantly more efficient and satisfying than starting new ones.',
        tip: 'The satisfaction of completing things during the luteal phase is neurologically real — it activates the dopamine system that progesterone withdrawal is suppressing. Each completion is literally therapeutic.',
        steps: [
          'List everything that is 50–90% complete: projects, tasks, purchases, conversations',
          'Start with whatever is closest to completion — momentum builds from easy wins',
          'Complete each item entirely before moving to the next — half-done tasks drain mental energy',
          'Use your natural detail-orientation: proofread, review, and quality-check everything',
          'Before the next task, pause 30 seconds and acknowledge what you just finished',
          'That deliberate moment of recognition counteracts the dopamine dip of the luteal phase',
        ],
      ),
      LifestyleItem(
        name: 'Detail Review & Editing',
        shortDesc: 'Your eye for error is at its sharpest',
        imageUrl: _organize,
        accentColor: Color(0xFFBC6B9C),
        duration: '2–3 hour blocks',
        why: 'Research shows attention to detail and error-detection ability are measurably better during the luteal phase compared to the follicular phase. The same document reviewed in both phases will yield different errors caught. Schedule review tasks here deliberately.',
        tip: 'Financial audits, legal document reviews, and quality assurance checks all benefit from being scheduled in the luteal phase. The natural skepticism and detail-focus of this phase is a professional asset — if you know to use it.',
        steps: [
          'Block a 2-hour detail-review session in your calendar for this week',
          'Read documents slowly — read important ones aloud if possible',
          'Check numbers and data manually — do not trust memory on critical figures',
          'Look specifically for what is missing or unclear, not just what is wrong',
          'Make a list of everything that needs addressing before you finalize anything',
          'Do not rush to finish — your thoroughness is the value here, not your speed',
        ],
      ),
      LifestyleItem(
        name: 'Self-Care as Productivity',
        shortDesc: 'Rest now is performance later',
        imageUrl: _selfCare,
        accentColor: Color(0xFFBC6B9C),
        duration: 'Throughout the week',
        why: 'Treating self-care as productive investment during the luteal phase — rather than a guilty break from productivity — changes your relationship with rest. Research consistently shows adequate rest improves performance in subsequent high-energy phases.',
        tip: 'The women who are most sustainably productive across their careers are the ones who have learned to manage their energy across their cycle — not the ones who push hardest in every phase.',
        steps: [
          'Add self-care appointments to your calendar: yoga, bath, nature walk, or massage',
          'When the time comes, treat it as a fixed appointment — do not cancel for non-urgent work',
          'Be fully present during self-care — do not mentally work through your bath',
          'Tell yourself explicitly: "This is a professional decision, not a personal indulgence"',
          'After your luteal week with good self-care, notice how your follicular phase begins',
          'Track this across 3 cycles — the productivity data will make your case clearly',
        ],
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  int _selectedPhase = 0;
  int _selectedCategory = 0;

  // ── Coach-mark tour targets ──
  final GlobalKey _phaseSelectorKey = GlobalKey();
  final GlobalKey _categoryTabsKey = GlobalKey();
  final GlobalKey _itemListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _maybeShowCoachTour();
  }

  Future<void> _maybeShowCoachTour() async {
    final seen = await TutorialStorageService.hasSeenTour(TutorialStorageService.lifestyle);
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoachTour());
  }

  void _startCoachTour() {
    showCoachMarkTour(
      context: context,
      steps: [
        CoachMarkStep(
          targetKey: _phaseSelectorKey,
          title: 'Pick a cycle phase',
          description: 'Content here changes based on which phase you\'re viewing — start with the one you\'re in today.',
        ),
        CoachMarkStep(
          targetKey: _categoryTabsKey,
          title: 'Browse by category',
          description: 'Switch between Exercise, Sleep, Nutrition, and Mindset tips for the selected phase.',
        ),
        CoachMarkStep(
          targetKey: _itemListKey,
          title: 'Tap for details',
          description: 'Tap any card below to open the full tutorial or guide for that item.',
        ),
      ],
    ).then((_) => TutorialStorageService.markTourSeen(TutorialStorageService.lifestyle));
  }

  static const List<String> _categoryNames = [
    'Exercise', 'Sleep', 'Nutrition', 'Mindset',
  ];
  static const List<IconData> _categoryIcons = [
    Icons.fitness_center_rounded,
    Icons.bedtime_rounded,
    Icons.restaurant_rounded,
    Icons.bolt_rounded,
  ];

  PhaseData get _phase => kPhases[_selectedPhase];

  List<LifestyleItem> get _currentItems {
    switch (_selectedCategory) {
      case 0: return _phase.exercise;
      case 1: return _phase.sleep;
      case 2: return _phase.nutrition;
      case 3: return _phase.productivity;
      default: return _phase.exercise;
    }
  }

  void _openDetail(LifestyleItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailScreen(item: item, phaseColor: _phase.color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Glass.pageBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 5),
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                KeyedSubtree(key: _phaseSelectorKey, child: _buildPhaseSelector()),
                KeyedSubtree(key: _categoryTabsKey, child: _buildCategoryTabs()),
                Expanded(child: KeyedSubtree(key: _itemListKey, child: _buildItemList())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
    child: _Glass.card(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Text('Lifestyle & Productivity',
              style: _Glass.heading(size: 16, weight: FontWeight.w600)),
        ),
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

  // ── Phase selector ────────────────────────────────────────────────────────

  Widget _buildPhaseSelector() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    child: _Glass.card(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kPhases.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final p = kPhases[i];
                final isOn = _selectedPhase == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPhase = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn ? p.color : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: isOn ? p.color : Colors.white.withOpacity(0.7)),
                    ),
                    child: Row(children: [
                      Text(p.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(p.name,
                          style: _Glass.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: isOn ? Colors.white : _Glass.textMuted,
                          )),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(_phase.subtitle,
              style: _Glass.body(
                  size: 11, weight: FontWeight.w600, color: _phase.color)),
        ],
      ),
    ),
  );

  // ── Category tabs ─────────────────────────────────────────────────────────

  Widget _buildCategoryTabs() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    child: _Glass.card(
      radius: 18,
      padding: EdgeInsets.zero,
      child: Row(children: List.generate(_categoryNames.length, (i) {
        final isOn = _selectedCategory == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isOn ? _phase.color : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Icon(_categoryIcons[i],
                      size: 18,
                      color: isOn ? _phase.color : _Glass.textHint),
                  const SizedBox(height: 3),
                  Text(_categoryNames[i],
                      style: _Glass.body(
                        size: 10,
                        weight: isOn ? FontWeight.w600 : FontWeight.normal,
                        color: isOn ? _phase.color : _Glass.textMuted,
                      )),
                ],
              ),
            ),
          ),
        );
      })),
    ),
  );

  // ── Item list ─────────────────────────────────────────────────────────────

  Widget _buildItemList() {
    final items = _currentItems;
    if (items.isEmpty) {
      return Center(
        child: Text('More content coming soon',
            style: _Glass.body(size: 14, color: _Glass.textHint)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildItemCard(items[i]),
    );
  }

  // Fallback shown if BOTH a local step image and the network image fail —
  // a soft colored panel with an icon + the item name, never a raw broken-image icon.
  Widget _thumbFallback(LifestyleItem item) => Container(
        color: item.accentColor.withOpacity(0.12),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 36, color: item.accentColor.withOpacity(0.4)),
            const SizedBox(height: 6),
            Text(item.name, style: _Glass.body(size: 13, color: item.accentColor)),
          ],
        ),
      );

  // Thumbnail source for a card: prefer the item's own local step photo
  // (guaranteed to exist in the bundle) and only fall back to the network
  // image when no local asset is available for this item.
  Widget _thumbnailImage(LifestyleItem item) {
    if (item.stepImages != null && item.stepImages!.isNotEmpty) {
      return Image.asset(
        item.stepImages!.first,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbFallback(item),
      );
    }
    return Image.network(
      item.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: item.accentColor.withOpacity(0.1),
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: item.accentColor,
          ),
        );
      },
      errorBuilder: (_, __, ___) => _thumbFallback(item),
    );
  }

  Widget _buildItemCard(LifestyleItem item) {
    final c = _phase.color;
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: _Glass.card(
          radius: 18,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo ──────────────────────────────────────────────────
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _thumbnailImage(item),
                    // Gradient overlay so text is readable
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Duration pill
                    Positioned(
                      top: 10, right: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(item.duration,
                                  style: _Glass.body(
                                      size: 10,
                                      weight: FontWeight.w500,
                                      color: Colors.white)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    // Name over gradient
                    Positioned(
                      bottom: 10, left: 12,
                      child: Text(item.name,
                          style: _Glass.heading(
                              size: 15, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // ── Card body ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.shortDesc,
                        style: _Glass.body(size: 12, color: _Glass.textMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${item.steps.length} steps',
                              style: _Glass.body(
                                  size: 10, weight: FontWeight.w600, color: c)),
                        ),
                        const Spacer(),
                        Text('View tutorial',
                            style: _Glass.body(
                                size: 11, weight: FontWeight.w600, color: c)),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: c),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL SCREEN — Full tutorial with image per step
// ─────────────────────────────────────────────────────────────────────────────

class _DetailScreen extends StatefulWidget {
  final LifestyleItem item;
  final Color phaseColor;

  const _DetailScreen({required this.item, required this.phaseColor});

  @override
  State<_DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<_DetailScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.phaseColor;
    final item = widget.item;
    final total = item.steps.length;

    return Scaffold(
      backgroundColor: _Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: _Glass.card(
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle),
                          child: Icon(Icons.chevron_left,
                              color: _Glass.textDark, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item.name,
                            style: _Glass.heading(size: 16, weight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: c.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(item.duration,
                            style: _Glass.body(
                                size: 11, weight: FontWeight.w500, color: c)),
                      ),
                    ]),
                  ),
                ),

                // ── Progress bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      color: c.withOpacity(0.15),
                      child: FractionallySizedBox(
                        widthFactor: (_currentStep + 1) / total,
                        alignment: Alignment.centerLeft,
                        child: Container(color: c),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Hero image ────────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: _Glass.card(
                              radius: 20,
                              padding: EdgeInsets.zero,
                              child: SizedBox(
                                height: 220,
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Use per-step local asset if available, else network image
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: item.stepImages != null
                                          ? Image.asset(
                                              item.stepImages![_currentStep],
                                              key: ValueKey('step_$_currentStep'),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 220,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: c.withOpacity(0.12),
                                                alignment: Alignment.center,
                                                child: Icon(Icons.image_outlined,
                                                    size: 48, color: c.withOpacity(0.3)),
                                              ),
                                            )
                                          : Image.network(
                                              item.imageUrl,
                                              key: const ValueKey('network'),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 220,
                                              loadingBuilder: (_, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  color: c.withOpacity(0.1),
                                                  alignment: Alignment.center,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2, color: c,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, __, ___) => Container(
                                                color: c.withOpacity(0.12),
                                                alignment: Alignment.center,
                                                child: Icon(Icons.image_outlined,
                                                    size: 48, color: c.withOpacity(0.3)),
                                              ),
                                            ),
                                    ),
                                    // Dark gradient at bottom
                                    Positioned(
                                      bottom: 0, left: 0, right: 0,
                                      child: Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.6),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Step indicator over image
                                    Positioned(
                                      bottom: 12, left: 14,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Step ${_currentStep + 1} of $total',
                                              style: _Glass.body(
                                                  size: 11,
                                                  weight: FontWeight.w500,
                                                  color: Colors.white.withOpacity(0.8))),
                                          const SizedBox(height: 3),
                                          Text(item.steps[_currentStep],
                                              style: _Glass.heading(
                                                  size: 15,
                                                  weight: FontWeight.w700,
                                                  color: Colors.white),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Dots navigation ───────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: _Glass.card(
                              radius: 18,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(children: [
                                // Prev button
                                GestureDetector(
                                  onTap: _currentStep > 0
                                      ? () => setState(() => _currentStep--)
                                      : null,
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: _currentStep > 0
                                          ? Colors.white.withOpacity(0.6)
                                          : Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.chevron_left,
                                        size: 20,
                                        color: _currentStep > 0
                                            ? _Glass.textDark
                                            : _Glass.textHint),
                                  ),
                                ),

                                // Dots
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(total, (i) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: i == _currentStep ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: i == _currentStep
                                            ? c
                                            : _Glass.textHint.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    )),
                                  ),
                                ),

                                // Next / Restart button
                                GestureDetector(
                                  onTap: () => setState(() {
                                    if (_currentStep < total - 1) {
                                      _currentStep++;
                                    } else {
                                      _currentStep = 0;
                                    }
                                  }),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                        color: c, shape: BoxShape.circle),
                                    child: Icon(
                                      _currentStep < total - 1
                                          ? Icons.chevron_right
                                          : Icons.refresh_rounded,
                                      size: 20, color: Colors.white,
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Step cards (all steps listed) ──────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              children: List.generate(total, (i) {
                                final isActive = i == _currentStep;
                                final isDone = i < _currentStep;
                                return GestureDetector(
                                  onTap: () => setState(() => _currentStep = i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: _Glass.card(
                                      radius: 14,
                                      padding: const EdgeInsets.all(13),
                                      opacity: isActive ? 0.7 : 0.5,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Step number circle
                                          Container(
                                            width: 26, height: 26,
                                            decoration: BoxDecoration(
                                              color: isDone
                                                  ? const Color(0xFF3BAF7E)
                                                  : isActive
                                                      ? c
                                                      : Colors.white.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: isDone
                                                ? const Icon(Icons.check_rounded,
                                                size: 14, color: Colors.white)
                                                : Text('${i + 1}',
                                                style: _Glass.body(
                                                  size: 11,
                                                  weight: FontWeight.w700,
                                                  color: isActive
                                                      ? Colors.white
                                                      : _Glass.textMuted,
                                                )),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(item.steps[i],
                                                style: _Glass.body(
                                                  size: 13,
                                                  color: isDone
                                                      ? _Glass.textHint
                                                      : _Glass.textDark,
                                                ).copyWith(
                                                  height: 1.55,
                                                  decoration: isDone
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  decorationColor: _Glass.textHint,
                                                )),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Why it helps ─────────────────────────────────────
                          _infoCard(
                            icon: Icons.science_outlined,
                            color: c,
                            label: 'Why it helps',
                            body: item.why,
                          ),

                          const SizedBox(height: 8),

                          // ── Pro tip ──────────────────────────────────────────
                          _infoCard(
                            icon: Icons.lightbulb_outline_rounded,
                            color: c,
                            label: 'Pro tip',
                            body: item.tip,
                            isHighlight: true,
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String label,
    required String body,
    bool isHighlight = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _Glass.card(
          radius: 16,
          padding: const EdgeInsets.all(14),
          opacity: isHighlight ? 0.65 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label.toUpperCase(),
                    style: _Glass.body(
                        size: 10, weight: FontWeight.w700, color: color)
                        .copyWith(letterSpacing: .5)),
              ]),
              const SizedBox(height: 8),
              Text(body,
                  style: _Glass.body(size: 13, color: _Glass.textMuted)
                      .copyWith(height: 1.65)),
            ],
          ),
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