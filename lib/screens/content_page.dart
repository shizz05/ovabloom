import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Content data ─────────────────────────────────────────────────────────────

class _Section {
  final String? heading;
  final String body;
  const _Section({this.heading, required this.body});
}

class _Article {
  final String title;
  final String category;
  final String emoji;
  final Color accentColor;
  final List<_Section> sections;

  const _Article({
    required this.title,
    required this.category,
    required this.emoji,
    required this.accentColor,
    required this.sections,
  });
}

const _kPurple = Color(0xFF7C3AED);
const _kRose = Color(0xFFE11D48);
const _kTeal = Color(0xFF0D9488);
const _kIndigo = Color(0xFF4338CA);
const _kAmber = Color(0xFFB45309);
const _kGreen = Color(0xFF15803D);

final Map<String, _Article> _articles = {
  'Myths & Facts': _Article(
    title: 'Myths & Facts',
    category: 'Health',
    emoji: '💡',
    accentColor: _kPurple,
    sections: const [
      _Section(
        body:
            'PCOS is often misunderstood. Let\'s separate fact from fiction so you can approach your health with clarity and confidence.',
      ),
      _Section(
        heading: 'Myth: PCOS means you can\'t get pregnant.',
        body:
            'Fact: It is one of the most common causes of ovulatory infertility, but also one of the most treatable — many women conceive naturally or with medical support.',
      ),
      _Section(
        heading: 'Myth: You must have ovarian cysts to have PCOS.',
        body:
            'Fact: Diagnosis requires two of three features — irregular ovulation, elevated androgens, or polycystic ovarian appearance — so cysts are not required.',
      ),
      _Section(
        heading: 'Myth: Only overweight women have PCOS.',
        body: 'Fact: PCOS affects women of all body types.',
      ),
      _Section(
        heading: 'Myth: Birth control cures PCOS.',
        body:
            'Fact: It manages symptoms but does not remove the underlying hormonal pattern.',
      ),
      _Section(
        heading: 'The Encouraging Truth',
        body:
            'PCOS is more than a period condition — it is a hormonal and metabolic pattern often linked with insulin resistance. The encouraging part is that it is manageable: lifestyle changes, medical guidance, and regular monitoring can significantly improve symptoms and reduce long-term risks, turning confusion into confident care.',
      ),
    ],
  ),
  'Cramp Relief Roadmap': _Article(
    title: 'Cramp Relief Roadmap',
    category: 'Health',
    emoji: '🗺️',
    accentColor: _kRose,
    sections: const [
      _Section(
        body:
            'Daisy used to tough it out — until she tried a layered approach. Evidence supports a stepwise plan for meaningful relief.',
      ),
      _Section(
        heading: 'Immediate Relief',
        body:
            'Heat (hot water bottle or heat patch) applied to the lower abdomen — randomized and systematic reviews show meaningful benefit versus placebo.',
      ),
      _Section(
        heading: 'First-Line Medicines',
        body:
            'NSAIDs (ibuprofen, naproxen, mefenamic acid) reduce prostaglandin-mediated uterine cramping — best started early when cramps begin. If NSAIDs are contraindicated, acetaminophen is an alternative though often less effective.',
      ),
      _Section(
        heading: 'Lifestyle & Non-Drug Options',
        body:
            'Gentle exercise (walking, yoga), abdominal massage, and warm baths can reduce pain and improve mood. TENS devices and some supplements (omega-3s, magnesium) have supporting evidence for some people.',
      ),
      _Section(
        heading: 'Recurrent or Severe Pain',
        body:
            'Hormonal treatments (combined oral contraceptives, progestin IUD) can suppress ovulation or reduce prostaglandin production and are standard next steps for primary dysmenorrhea or when an underlying cause is suspected. See a clinician if pain prevents normal activity — heavy or progressively worse pain may indicate endometriosis or fibroids.',
      ),
    ],
  ),
  'PCOS Beyond Irregular Periods': _Article(
    title: 'PCOS Beyond Irregular Periods',
    category: 'Health',
    emoji: '🔍',
    accentColor: _kIndigo,
    sections: const [
      _Section(
        body:
            'When Kavya was diagnosed with PCOS, she thought it meant she simply had cysts. But Polycystic Ovary Syndrome is actually a hormonal and metabolic condition that affects how the brain and ovaries communicate.',
      ),
      _Section(
        heading: 'How It\'s Diagnosed',
        body:
            'PCOS is diagnosed when at least two of three features are present: irregular ovulation, signs of higher androgens like acne or excess hair growth, or polycystic ovarian appearance on ultrasound — meaning cysts are not required for diagnosis.',
      ),
      _Section(
        heading: 'How Common Is It?',
        body:
            'Affecting about 8–13% of women worldwide, PCOS often involves altered hormone signaling and insulin resistance, which can disrupt ovulation and cycles.',
      ),
      _Section(
        heading: 'What This Means for You',
        body:
            'Hormones are responsive to lifestyle and medical support. With proper care, many women regulate their cycles, improve symptoms, and protect long-term metabolic health — making PCOS manageable rather than limiting.',
      ),
      _Section(
        heading: 'Understanding Changes Everything',
        body:
            'Because PCOS is a pattern of hormonal sensitivity rather than permanent damage, early attention to nutrition, movement, sleep, and medical guidance can significantly improve outcomes, allowing women with PCOS to lead healthy, empowered lives.',
      ),
    ],
  ),
  'Have a Good Sleep': _Article(
    title: 'Have a Good Sleep',
    category: 'Mind & Body',
    emoji: '🌙',
    accentColor: _kIndigo,
    sections: const [
      _Section(
        body:
            'Sameera reorganized her evenings: a dark room, consistent wake time, and tech curfew. Good sleep is the single most powerful daily habit for energy and cycle stability.',
      ),
      _Section(
        heading: 'Key Evidence-Based Rules',
        body:
            'Keep a fixed wake time to support circadian stability. Limit blue-light exposure 60–90 minutes before bed — screens suppress melatonin. Make the bedroom cool, dark, and quiet; use blackout curtains and remove clutter linked to wakefulness.',
      ),
      _Section(
        heading: 'Evening Habits',
        body:
            'Avoid heavy meals, alcohol, and vigorous late-night exercise close to bedtime. Build a wind-down routine: light reading, breathing exercises, or progressive muscle relaxation. CBT-I (Cognitive Behavioral Therapy for Insomnia) is the gold-standard therapy for chronic insomnia.',
      ),
      _Section(
        heading: 'When to Seek Help',
        body:
            'If you snore heavily, wake with gasps, or experience daytime sleepiness, screen for sleep apnea. If sleep problems persist for weeks and affect daytime function, a clinician or sleep specialist can evaluate for insomnia, sleep apnea, restless legs, or circadian disorders and offer CBT-I, prescription short courses, or other targeted treatments.',
      ),
    ],
  ),
  'Health & Nutrition': _Article(
    title: 'Health & Nutrition',
    category: 'Health',
    emoji: '🥗',
    accentColor: _kGreen,
    sections: const [
      _Section(
        body:
            'On a busy market morning, Anu chose iron-rich greens, oily fish, whole grains, and yogurt — a good pattern for menstrual health.',
      ),
      _Section(
        heading: 'Foundational Nutrition',
        body:
            'Focus on: adequate iron (to prevent anaemia from blood loss), enough calories (avoid energy deficit that interrupts cycles), protein and healthy fats (omega-3s reduce inflammation), and abundant fruits and vegetables for micronutrients and fibre.',
      ),
      _Section(
        heading: 'Vitamins & Minerals',
        body:
            'Vitamin D, B12, and folate may also be important depending on diet and region. For periods with heavy bleeding, check ferritin and replace iron if low under medical guidance.',
      ),
      _Section(
        heading: 'Practical Checklist',
        body:
            'Get a baseline CBC and ferritin if fatigued or experiencing heavy bleeding. Include iron sources with vitamin C to increase absorption. Consider omega-3s and a varied plate. Hydration, limiting excess alcohol and caffeine, and a balanced diet support energy and mood. Seek a dietitian for personalized plans or if you have special dietary needs.',
      ),
    ],
  ),
  'PCOS and Fertility': _Article(
    title: 'PCOS and Fertility',
    category: 'Journey',
    emoji: '🌱',
    accentColor: _kTeal,
    sections: const [
      _Section(
        body:
            'PCOS is one of the most common causes of ovulatory infertility, but it is also one of the most treatable.',
      ),
      _Section(
        heading: 'Understanding the Challenge',
        body:
            'The primary issue in PCOS is irregular or absent ovulation — hormonal imbalances, often involving higher androgen levels and insulin resistance, can prevent a mature egg from being released regularly. This can make cycles unpredictable and conception more challenging, but it does not mean pregnancy is impossible.',
      ),
      _Section(
        heading: 'Reasons for Hope',
        body:
            'Many women with PCOS ovulate occasionally on their own, and with proper support, ovulation can often be restored. Evidence-based treatments are highly effective.',
      ),
      _Section(
        heading: 'Treatment Options',
        body:
            'Lifestyle interventions that improve insulin sensitivity — such as balanced nutrition, regular physical activity, and adequate sleep — can increase ovulation rates. When medical support is needed, medications like letrozole (first-line therapy) help stimulate ovulation, and many women conceive successfully with this approach.',
      ),
      _Section(
        heading: 'Your Fertility Is Not Defined by PCOS',
        body:
            'PCOS does not define your fertility. With early guidance and individualized care, most women are able to achieve healthy pregnancies.',
      ),
    ],
  ),
  'PCOS and Mental Health': _Article(
    title: 'PCOS and Mental Health',
    category: 'Mind & Body',
    emoji: '🧠',
    accentColor: _kPurple,
    sections: const [
      _Section(
        body:
            'PCOS affects more than hormones and cycles — it can also influence emotional well-being in meaningful ways.',
      ),
      _Section(
        heading: 'The Emotional Impact',
        body:
            'Research shows that women with PCOS have higher rates of anxiety and depression compared to those without the condition. This is not simply due to stress about symptoms; hormonal imbalances, insulin resistance, and chronic inflammation may influence brain chemistry and mood regulation.',
      ),
      _Section(
        heading: 'Body Image & Self-Esteem',
        body:
            'Physical symptoms such as acne, hair changes, weight fluctuations, and irregular periods can also impact body image and self-esteem, adding emotional strain on top of physical challenges.',
      ),
      _Section(
        heading: 'Mental Health Is Part of PCOS Care',
        body:
            'Lifestyle interventions that improve insulin sensitivity — including regular exercise and consistent sleep — can also improve mood stability. Counseling, cognitive behavioral therapy, and when needed, medications like SSRIs are evidence-based treatments that help manage anxiety and depression.',
      ),
      _Section(
        heading: 'A Whole-Person Approach',
        body:
            'PCOS is not "just physical," and addressing emotional health alongside hormonal health leads to stronger, more balanced long-term well-being.',
      ),
    ],
  ),
  'PCOS is a Signal Not a Sentence': _Article(
    title: 'PCOS is a Signal Not a Sentence',
    category: 'Journey',
    emoji: '✨',
    accentColor: _kAmber,
    sections: const [
      _Section(
        body:
            'When someone hears the words "You have PCOS," it can feel heavy — but PCOS is not a life sentence; it is a signal.',
      ),
      _Section(
        heading: 'What the Signal Means',
        body:
            'It is your body\'s way of showing that hormones and metabolism need support, not shame. Polycystic Ovary Syndrome reflects a pattern of altered ovulation, higher androgen levels, and often insulin resistance — but these systems are dynamic, not fixed.',
      ),
      _Section(
        heading: 'Systems That Can Change',
        body:
            'Research shows that hormones respond to lifestyle changes, medical care, and metabolic support, meaning cycles can regulate, symptoms can improve, and long-term health risks can be reduced. PCOS is not a failure of the body; it is a call for alignment.',
      ),
      _Section(
        heading: 'What\'s Possible',
        body:
            'PCOS often leads women to become deeply informed about their health at an early age. With balanced nutrition, consistent movement, restorative sleep, stress management, and appropriate medical guidance, many women regain ovulation, improve skin and hair symptoms, conceive successfully, and build strong metabolic health for the future.',
      ),
      _Section(
        heading: 'Your Strength Is Unchanged',
        body:
            'A diagnosis of PCOS does not define your strength, femininity, or future — it invites you to understand your body, work with it, and step into long-term, empowered self-care.',
      ),
    ],
  ),
  'All Things Mood Swings': _Article(
    title: 'All Things Mood Swings',
    category: 'Mind & Body',
    emoji: '🌊',
    accentColor: _kRose,
    sections: const [
      _Section(
        body:
            'When Meera\'s mood dipped a little before her period it was "light"; when Priya found herself enraged and tearful every month it was "heavy." Mood changes tied to the cycle exist on a spectrum.',
      ),
      _Section(
        heading: 'Light',
        body:
            'Mild irritability, teariness, small mood dips — typical for many people in the luteal phase. Managed with sleep, exercise, diet, and cycle tracking.',
      ),
      _Section(
        heading: 'Medium',
        body:
            'Mood change that affects relationships or work. May need lifestyle adjustments, cognitive strategies (CBT techniques), or short-term supports such as exercise and magnesium.',
      ),
      _Section(
        heading: 'Heavy — PMDD',
        body:
            'Symptoms consistent with Premenstrual Dysphoric Disorder (PMDD) — severe mood swings, marked functional impairment, suicidality in some cases — requires medical treatment (SSRIs, structured CBT, and/or hormonal options). ACOG and guideline bodies give clear diagnostic criteria for PMDD and recommend combined approaches.',
      ),
      _Section(
        heading: 'When to Seek Help',
        body:
            'If mood swings are severe, recurrent, or cause impairment — track the timing and seek a clinician. PMDD responds well to proven treatments and you do not have to manage it alone.',
      ),
    ],
  ),
  'Living with PCOS': _Article(
    title: 'Living with PCOS',
    category: 'Journey',
    emoji: '🌿',
    accentColor: _kGreen,
    sections: const [
      _Section(
        body:
            'Living with PCOS is not about fighting your body — it is about learning how it responds over time.',
      ),
      _Section(
        heading: 'PCOS Through Life Stages',
        body:
            'PCOS is a long-term hormonal and metabolic condition, but it evolves. In your 20s and 30s, the focus may be cycle regulation, skin changes, or fertility. In your 30s and 40s, attention often shifts toward metabolic health, blood sugar balance, and cardiovascular risk.',
      ),
      _Section(
        heading: 'Why Monitoring Matters',
        body:
            'Because PCOS is associated with insulin resistance and irregular ovulation, regular monitoring, balanced nutrition, movement, and medical guidance play an important role in protecting long-term health. Early awareness allows for early prevention.',
      ),
      _Section(
        heading: 'What Consistent Care Looks Like',
        body:
            'With consistent care, many women see meaningful improvements in symptoms and reduce long-term risks. Strength training improves insulin sensitivity, quality sleep stabilizes hormones, and even modest lifestyle adjustments can support regular ovulation and metabolic balance.',
      ),
      _Section(
        heading: 'PCOS Becomes Manageable',
        body:
            'PCOS does not disappear, but it becomes manageable — and over time, it often becomes a source of deep body awareness and resilience. Living with PCOS is not about limitation; it is about informed, steady care that supports health for decades to come.',
      ),
    ],
  ),
};

// ── ContentPage ───────────────────────────────────────────────────────────────

class ContentPage extends StatelessWidget {
  final String title;

  const ContentPage({
    super.key,
    required this.title,
    // Keep contentImagePath param so existing call-sites don't break,
    // but we no longer use it.
    String? contentImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final article = _articles[title];

    if (article == null) {
      return _NotFoundPage(title: title);
    }

    return _ArticleView(article: article);
  }
}

// ── Article view ──────────────────────────────────────────────────────────────

class _ArticleView extends StatelessWidget {
  final _Article article;
  const _ArticleView({required this.article});

  @override
  Widget build(BuildContext context) {
    final accent = article.accentColor;
    final light = accent.withOpacity(0.08);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero app bar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFF9F7FF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.12),
                      accent.withOpacity(0.04),
                      const Color(0xFFF9F7FF),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Category pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            article.category,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.emoji,
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                article.title,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = article.sections[index];
                  return _SectionCard(
                    section: section,
                    accent: accent,
                    light: light,
                    isFirst: index == 0,
                  );
                },
                childCount: article.sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final _Section section;
  final Color accent;
  final Color light;
  final bool isFirst;

  const _SectionCard({
    required this.section,
    required this.accent,
    required this.light,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    // First section is an intro — render differently
    if (isFirst) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: light,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.18)),
        ),
        child: Text(
          section.body,
          style: GoogleFonts.poppins(
            fontSize: 15,
            height: 1.7,
            color: Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent bar
              Container(width: 4, color: accent),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.heading != null) ...[
                        Text(
                          section.heading!,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        section.body,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.65,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Not found fallback ────────────────────────────────────────────────────────

class _NotFoundPage extends StatelessWidget {
  final String title;
  const _NotFoundPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F7FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📄', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Content coming soon',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
