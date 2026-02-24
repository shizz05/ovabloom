import 'package:flutter/material.dart';
import 'package:pcos_app/widgets/app_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pcos_app/homepage.dart';
import 'package:pcos_app/screens/content_page.dart';

class Insight {
  final String image;
  final String title;
  final String category;

  Insight({
    required this.image,
    required this.title,
    required this.category,
  });
}

class InsightPage extends StatefulWidget {
  const InsightPage({super.key});

  @override
  State<InsightPage> createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Health', 'Journey', 'Mind & Body'];

  final List<Insight> _allInsights = [
    Insight(
      image: 'assets/avatars/a.png',
      title: 'Myths & Facts',
      category: 'Health',
    ),
    Insight(
      image: 'assets/avatars/h.png',
      title: 'PCOS is a Signal Not a Sentence',
      category: 'Journey',
    ),
    Insight(
      image: 'assets/avatars/b.png',
      title: 'Cramp Relief Roadmap',
      category: 'Health',
    ),
    Insight(
      image: 'assets/avatars/e.png',
      title: 'Health & Nutrition',
      category: 'Health',
    ),
    Insight(
      image: 'assets/avatars/f.png',
      title: 'PCOS and Fertility',
      category: 'Journey',
    ),
    Insight(
      image: 'assets/avatars/g.png',
      title: 'PCOS and Mental Health',
      category: 'Mind & Body',
    ),
    Insight(
      image: 'assets/avatars/d.png',
      title: 'Have a Good Sleep',
      category: 'Mind & Body',
    ),
    Insight(
      image: 'assets/avatars/c.png',
      title: 'PCOS Beyond Irregular Periods',
      category: 'Health',
    ),
    Insight(
      image: 'assets/avatars/i.png',
      title: 'All Things Mood Swings',
      category: 'Mind & Body',
    ),
    Insight(
      image: 'assets/avatars/j.png',
      title: 'Living with PCOS',
      category: 'Journey',
    ),
  ];

  List<Insight> get _filteredInsights {
    return _allInsights.where((insight) {
      final matchesFilter =
          _selectedFilter == 'All' || insight.category == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          insight.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 1,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildPinterestGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          Text(
            'Insights',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9D5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filteredInsights.length} reads',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search insights...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded,
                      color: Colors.grey[500], size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withOpacity(0.35)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinterestGrid() {
    final insights = _filteredInsights;

    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No insights found',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final leftCol = <Insight>[];
    final rightCol = <Insight>[];
    for (int i = 0; i < insights.length; i++) {
      if (i % 2 == 0) {
        leftCol.add(insights[i]);
      } else {
        rightCol.add(insights[i]);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildColumn(leftCol)),
          const SizedBox(width: 8),
          Expanded(child: _buildColumn(rightCol)),
        ],
      ),
    );
  }

  Widget _buildColumn(List<Insight> col) {
    return Column(
      children: col.map((insight) {
        return _PinCard(
          insight: insight,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentPage(
                title: insight.title,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PinCard extends StatefulWidget {
  final Insight insight;
  final VoidCallback onTap;

  const _PinCard({
    required this.insight,
    required this.onTap,
  });

  @override
  State<_PinCard> createState() => _PinCardState();
}

class _PinCardState extends State<_PinCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.09),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  widget.insight.image,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: const Color(0xFFEDE9FE),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Color(0xFF7C3AED), size: 32),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.insight.title,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.insight.category,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
