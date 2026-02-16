import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/show_result.dart';
import 'package:breedly/models/kennel_profile.dart';
import 'package:breedly/utils/app_theme.dart';

/// Generates a shareable show result card image
class ShowResultCardScreen extends StatefulWidget {
  final ShowResult result;
  final Dog dog;

  const ShowResultCardScreen({
    super.key,
    required this.result,
    required this.dog,
  });

  @override
  State<ShowResultCardScreen> createState() => _ShowResultCardScreenState();
}

class _ShowResultCardScreenState extends State<ShowResultCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  File? _showPhoto;
  bool _isGenerating = false;
  String? _kennelName;

  // Card customization toggles
  bool _showBreed = true;
  bool _showKennel = true;
  bool _showJudge = true;
  bool _showDate = true;
  bool _showDetails = true;
  _CardFont _selectedFont = _CardFont.standard;
  double _fontScale = 1.0; // 0.8 to 1.3
  _CardTheme? _selectedTheme; // null = auto-detect
  _CardPattern _selectedPattern = _CardPattern.geometric;

  @override
  void initState() {
    super.initState();
    _loadKennelName();
  }

  void _loadKennelName() {
    try {
      final box = Hive.box<KennelProfile>('kennel_profile');
      if (box.isNotEmpty) {
        _kennelName = box.getAt(0)?.kennelName;
      }
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _showPhoto = File(image.path));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _showPhoto = File(image.path));
    }
  }

  Future<void> _shareCard() async {
    setState(() => _isGenerating = true);

    try {
      // Wait for the widget to render
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunne ikke generere bilde')),
          );
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/show_result_${widget.result.id}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.dog.name} - ${widget.result.showName} 🏆',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved deling: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Auto-detect theme based on result quality
  _CardTheme get _autoTheme {
    final r = widget.result;
    if (r.bisResult != null) return _CardTheme.bis;
    if (r.groupResult != null) return _CardTheme.group;
    if (r.placement == 'BIR') return _CardTheme.bir;
    if (r.placement == 'BIM') return _CardTheme.bim;
    if (r.hasCK) return _CardTheme.ck;
    if (r.quality == 'Excellent') return _CardTheme.excellent;
    return _CardTheme.standard;
  }

  /// Active theme — user override or auto-detected
  _CardTheme get _theme => _selectedTheme ?? _autoTheme;

  Widget _buildOptionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Content toggles
          Text(
            'INNHOLD',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.neutral500,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToggle('Rase', _showBreed, (v) => setState(() => _showBreed = v)),
                const SizedBox(width: 8),
                _buildToggle('Kennel', _showKennel, (v) => setState(() => _showKennel = v)),
                const SizedBox(width: 8),
                _buildToggle('Dommer', _showJudge, (v) => setState(() => _showJudge = v)),
                const SizedBox(width: 8),
                _buildToggle('Dato', _showDate, (v) => setState(() => _showDate = v)),
                const SizedBox(width: 8),
                _buildToggle('Detaljer', _showDetails, (v) => setState(() => _showDetails = v)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 2. Background theme
          Text(
            'BAKGRUNN',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.neutral500,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildThemeChip(null, 'Auto'),
                const SizedBox(width: 8),
                _buildThemeChip(_CardTheme.bis, 'Gull & Sort'),
                const SizedBox(width: 8),
                _buildThemeChip(_CardTheme.group, 'Navy & Gull'),
                const SizedBox(width: 8),
                _buildThemeChip(_CardTheme.bir, 'Teal & Rav'),
                const SizedBox(width: 8),
                _buildThemeChip(_CardTheme.bim, 'Skifer & Sølv'),
                const SizedBox(width: 8),
                _buildThemeChip(_CardTheme.ck, 'Skog & Jade'),
                const SizedBox(width: 8),
                _buildThemeChip(_CardTheme.excellent, 'Indigo'),
                const SizedBox(width: 8),
                _buildThemeChip(_CardTheme.standard, 'Klassisk'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 3. Pattern
          Text(
            'MØNSTER',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.neutral500,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _CardPattern.values.map((pattern) {
                final isSelected = _selectedPattern == pattern;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPattern = pattern),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _theme.accentColor.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _theme.accentColor.withValues(alpha: 0.4)
                              : AppColors.neutral300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pattern.icon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pattern.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? _theme.accentColor : AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // 4. Font type
          Text(
            'SKRIFTTYPE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.neutral500,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _CardFont.values.map((font) {
                final isSelected = _selectedFont == font;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFont = font),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _theme.accentColor.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _theme.accentColor.withValues(alpha: 0.4)
                              : AppColors.neutral300,
                        ),
                      ),
                      child: Text(
                        font.displayName,
                        style: font.textStyle(14).copyWith(
                          color: isSelected ? _theme.accentColor : AppColors.neutral600,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // 5. Font size
          Row(
            children: [
              Text(
                'STØRRELSE',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.neutral500,
                  letterSpacing: 1.0,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_fontScale * 100).round()}%',
                style: AppTypography.labelSmall.copyWith(
                  color: _theme.accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _theme.accentColor,
              inactiveTrackColor: _theme.accentColor.withValues(alpha: 0.15),
              thumbColor: _theme.accentColor,
              overlayColor: _theme.accentColor.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _fontScale,
              min: 0.8,
              max: 1.3,
              divisions: 10,
              onChanged: (v) => setState(() => _fontScale = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    final theme = _theme;
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: theme.accentColor.withValues(alpha: 0.12),
      checkmarkColor: theme.accentColor,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: value ? FontWeight.w600 : FontWeight.w400,
        color: value ? theme.accentColor : AppColors.neutral500,
      ),
      side: BorderSide(
        color: value ? theme.accentColor.withValues(alpha: 0.3) : AppColors.neutral300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildThemeChip(_CardTheme? theme, String label) {
    final isSelected = _selectedTheme == theme;
    final accentColor = theme?.accentColor ?? _autoTheme.accentColor;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.neutral300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme?.gradientColors ?? _autoTheme.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.5)
                      : AppColors.neutral300,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? accentColor : AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EDEA),
      appBar: AppBar(
        title: Text(
          'Resultatkort',
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.neutral900,
        actions: [
          if (_showPhoto != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Fjern bilde',
              onPressed: () => setState(() => _showPhoto = null),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Legg til bilde',
            onSelected: (value) {
              if (value == 'gallery') _pickPhoto();
              if (value == 'camera') _takePhoto();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'gallery', child: ListTile(leading: Icon(Icons.photo_library), title: Text('Velg fra galleri'))),
              const PopupMenuItem(value: 'camera', child: ListTile(leading: Icon(Icons.camera_alt), title: Text('Ta bilde'))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
          // Options toggles
          _buildOptionsBar(),
          // Share button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _shareCard,
                  icon: _isGenerating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share_rounded),
                  label: Text(_isGenerating ? 'Genererer...' : 'Del resultatkort'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _theme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    final theme = _theme;
    final dateFormat = DateFormat('dd. MMMM yyyy', 'nb_NO');
    final r = widget.result;
    final dog = widget.dog;
    final baseFontStyle = _selectedFont.textStyle;
    TextStyle fontStyle(double size) => baseFontStyle(size * _fontScale);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.gradientColors.first.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Accent top bar ───
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.accentColor.withValues(alpha: 0.6),
                  theme.accentColor,
                  theme.accentColor.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),

          // ─── Header section ───
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
            ),
            child: Stack(
              children: [
                // Decorative pattern overlay
                ..._buildHeaderPattern(theme),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Small label — show name
                      Text(
                        r.showName.toUpperCase(),
                        style: fontStyle(10).copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.accentColor.withValues(alpha: 0.9),
                          letterSpacing: 1.8,
                        ),
                      ),
                      if (_showDate) ...[
                        const SizedBox(height: 6),
                        Text(
                          dateFormat.format(r.date),
                          style: fontStyle(11).copyWith(
                            color: theme.textColor.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      if (_showJudge && r.judge != null && r.judge!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Rasedommer: ${r.judge!}',
                          style: fontStyle(11).copyWith(
                            color: theme.textColor.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (_showJudge && r.groupResult != null && r.groupJudge != null && r.groupJudge!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Gruppedommer: ${r.groupJudge!}',
                          style: fontStyle(11).copyWith(
                            color: theme.textColor.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (_showJudge && r.bisResult != null && r.bisJudge != null && r.bisJudge!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'BIS-dommer: ${r.bisJudge!}',
                          style: fontStyle(11).copyWith(
                            color: theme.textColor.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Dog name
                      Text(
                        dog.name,
                        style: fontStyle(26).copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.textColor,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      if (_showBreed || (_showKennel && _kennelName != null && _kennelName!.isNotEmpty)) ...[
                      const SizedBox(height: 6),
                      // Breed + kennel
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: theme.accentColor.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_showBreed)
                                  Text(
                                    dog.breed,
                                    style: fontStyle(14).copyWith(
                                      color: theme.textColor.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (_showKennel && _kennelName != null && _kennelName!.isNotEmpty)
                                  Text(
                                    _kennelName!,
                                    style: fontStyle(12).copyWith(
                                      color: theme.textColor.withValues(alpha: 0.55),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ],
                      const SizedBox(height: 20),
                      // Result badges
                      _buildResultBadges(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Photo section ───
          if (_showPhoto != null)
            Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.file(
                      _showPhoto!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Top gradient fade from header
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.gradientColors.last.withValues(alpha: 0.6),
                          theme.gradientColors.last.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom gradient fade to details
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          theme.cardBg.withValues(alpha: 0.95),
                          theme.cardBg.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // ─── Details section ───
          Container(
            width: double.infinity,
            color: theme.cardBg,
            padding: EdgeInsets.fromLTRB(28, _showPhoto != null ? 8 : 24, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showDetails) ...[
                const SizedBox(height: 20),

                // Decorative divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.accentColor.withValues(alpha: 0.0),
                              theme.accentColor.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.star_rounded, size: 14, color: theme.accentColor.withValues(alpha: 0.4)),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.accentColor.withValues(alpha: 0.25),
                              theme.accentColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Detail chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (r.showType != null)
                      _buildDetailChip(r.showType!, theme, icon: Icons.category_rounded),
                    _buildDetailChip(r.showClass, theme, icon: Icons.class_rounded),
                    _buildDetailChip(r.quality, theme, icon: Icons.grade_rounded, highlight: r.quality == 'Excellent'),
                    if (r.classPlacement != null)
                      _buildDetailChip('Kl. ${r.classPlacement}', theme, icon: Icons.format_list_numbered_rounded),
                    if (r.hasCK)
                      _buildDetailChip('CK', theme, icon: Icons.verified_rounded, highlight: true),
                    if (r.bestOfSexPlacement != null)
                      _buildDetailChip(
                        '${dog.gender == 'Male' ? 'BHK' : 'BTK'}: ${r.bestOfSexPlacement}',
                        theme,
                        icon: Icons.workspace_premium_rounded,
                      ),
                    if (r.certificates != null)
                      ...r.certificates!.map((c) => _buildDetailChip(c, theme, icon: Icons.card_membership_rounded, highlight: true)),
                  ],
                ),
                ],
              ],
            ),
          ),

          // ─── Footer ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: theme.footerBg,
              border: Border(
                top: BorderSide(color: theme.accentColor.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BREEDLY',
                  style: fontStyle(11).copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.footerTextColor,
                    letterSpacing: 2.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.footerTextColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('yyyy').format(r.date),
                    style: fontStyle(10).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.footerTextColor,
                      letterSpacing: 0.5,
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

  /// Builds decorative header overlay based on selected pattern
  List<Widget> _buildHeaderPattern(_CardTheme theme) {
    final accent = theme.accentColor;
    switch (_selectedPattern) {
      case _CardPattern.none:
        return [];

      case _CardPattern.geometric:
        return [
          // Large diamond shape top-right
          Positioned(
            right: -20,
            top: -20,
            child: Transform.rotate(
              angle: 0.785, // 45 degrees
              child: Opacity(
                opacity: 0.06,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          // Smaller diamond bottom-left
          Positioned(
            left: -15,
            bottom: -15,
            child: Transform.rotate(
              angle: 0.785,
              child: Opacity(
                opacity: 0.04,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Thin line accent
          Positioned(
            right: 60,
            top: 20,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 1.5,
                height: 100,
                color: accent,
              ),
            ),
          ),
        ];

      case _CardPattern.circles:
        return [
          Positioned(
            right: -40,
            top: -40,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.04,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.5),
                ),
              ),
            ),
          ),
          Positioned(
            left: -25,
            bottom: -25,
            child: Opacity(
              opacity: 0.035,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ),
        ];

      case _CardPattern.lines:
        return [
          // Diagonal lines pattern
          for (int i = 0; i < 6; i++)
            Positioned(
              right: -30 + (i * 25.0),
              top: -60,
              child: Transform.rotate(
                angle: -0.52, // ~30 degrees
                child: Opacity(
                  opacity: 0.035,
                  child: Container(
                    width: 1.5,
                    height: 280,
                    color: i.isEven ? accent : Colors.white,
                  ),
                ),
              ),
            ),
        ];

      case _CardPattern.dots:
        return [
          // Grid of dots
          for (int row = 0; row < 4; row++)
            for (int col = 0; col < 6; col++)
              Positioned(
                right: 15.0 + col * 22.0,
                top: 15.0 + row * 22.0,
                child: Opacity(
                  opacity: 0.05 - (row * 0.008),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (row + col).isEven ? accent : Colors.white,
                    ),
                  ),
                ),
              ),
        ];

      case _CardPattern.waves:
        return [
          // Curved wave shapes using rounded containers
          Positioned(
            right: -50,
            top: -30,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                  border: Border.all(color: accent, width: 1.5),
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Opacity(
              opacity: 0.035,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(60),
                    bottomLeft: Radius.circular(60),
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ),
        ];

      case _CardPattern.elegant:
        return [
          // Corner ornamental lines
          Positioned(
            right: 16,
            top: 16,
            child: Opacity(
              opacity: 0.08,
              child: SizedBox(
                width: 50,
                height: 50,
                child: CustomPaint(
                  painter: _CornerPainter(color: accent, flipH: true),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Opacity(
              opacity: 0.06,
              child: SizedBox(
                width: 50,
                height: 50,
                child: CustomPaint(
                  painter: _CornerPainter(color: Colors.white, flipH: false),
                ),
              ),
            ),
          ),
          // Center thin horizontal line
          Positioned(
            left: 60,
            right: 60,
            top: 12,
            child: Opacity(
              opacity: 0.06,
              child: Container(height: 0.8, color: accent),
            ),
          ),
        ];
    }
  }

  Widget _buildResultBadges(_CardTheme theme) {
    final r = widget.result;
    final badges = <Widget>[];

    // BIR/BIM first
    if (r.placement != null) {
      badges.add(_buildBadge(r.placement!, theme, large: r.groupResult == null && r.bisResult == null));
    }
    // Then group result (BIG)
    if (r.groupResult != null) {
      badges.add(_buildBadge(r.groupResult!, theme, large: r.bisResult == null && r.placement == null));
    }
    // Then BIS
    if (r.bisResult != null) {
      badges.add(_buildBadge(r.bisResult!, theme, large: r.groupResult == null && r.placement == null));
    }

    if (badges.isEmpty && r.hasCK) {
      badges.add(_buildBadge('CK', theme, large: true));
    }

    if (badges.isEmpty) {
      badges.add(_buildBadge(r.quality, theme, large: true));
    }

    return Row(
      children: [
        for (int i = 0; i < badges.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '·',
                style: TextStyle(
                  fontSize: 22,
                  color: theme.badgeTextColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          badges[i],
        ],
      ],
    );
  }

  Widget _buildBadge(String text, _CardTheme theme, {bool large = false}) {
    final size = (large ? 28.0 : 18.0) * _fontScale;
    return Text(
      text,
      style: _selectedFont.textStyle(size).copyWith(
        fontWeight: FontWeight.w800,
        color: theme.badgeTextColor,
        letterSpacing: large ? 2.0 : 1.0,
      ),
    );
  }

  Widget _buildDetailChip(String label, _CardTheme theme, {IconData? icon, bool highlight = false}) {
    final color = highlight ? theme.accentColor : theme.chipColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: highlight ? 0.35 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: _selectedFont.textStyle(12 * _fontScale).copyWith(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Card theme variants — premium, refined palettes
// ══════════════════════════════════════════════════

class _CardTheme {
  final List<Color> gradientColors;
  final Color textColor;
  final Color accentColor;
  final Color badgeTextColor;
  final Color cardBg;
  final Color detailTextColor;
  final Color detailSubtextColor;
  final Color chipColor;
  final Color footerBg;
  final Color footerTextColor;

  const _CardTheme({
    required this.gradientColors,
    required this.textColor,
    required this.accentColor,
    required this.badgeTextColor,
    required this.cardBg,
    required this.detailTextColor,
    required this.detailSubtextColor,
    required this.chipColor,
    required this.footerBg,
    required this.footerTextColor,
  });

  /// Preview color for the theme picker chip
  Color get previewColor => gradientColors.first;

  // BIS — Black & Gold luxury
  static const bis = _CardTheme(
    gradientColors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E)],
    textColor: Color(0xFFF5E6C8),
    accentColor: Color(0xFFD4A853),
    badgeTextColor: Color(0xFFF5E6C8),
    cardBg: Color(0xFFFFFDF8),
    detailTextColor: Color(0xFF1A1A2E),
    detailSubtextColor: Color(0xFF6B6B7B),
    chipColor: Color(0xFF4A4A5A),
    footerBg: Color(0xFFF8F5EF),
    footerTextColor: Color(0xFFA09888),
  );

  // Group — Dark navy & warm gold
  static const group = _CardTheme(
    gradientColors: [Color(0xFF0C1B33), Color(0xFF142850)],
    textColor: Color(0xFFE8D5B7),
    accentColor: Color(0xFFC9A84C),
    badgeTextColor: Color(0xFFE8D5B7),
    cardBg: Color(0xFFFFFDF8),
    detailTextColor: Color(0xFF142850),
    detailSubtextColor: Color(0xFF5A6A8A),
    chipColor: Color(0xFF3A4A6A),
    footerBg: Color(0xFFF7F4EE),
    footerTextColor: Color(0xFF9A9080),
  );

  // BIR — Deep teal & amber
  static const bir = _CardTheme(
    gradientColors: [Color(0xFF0A1628), Color(0xFF1B3A4B)],
    textColor: Color(0xFFF5F5F5),
    accentColor: Color(0xFFE8A838),
    badgeTextColor: Color(0xFFFFF8E8),
    cardBg: Color(0xFFFFFEFC),
    detailTextColor: Color(0xFF1B2838),
    detailSubtextColor: Color(0xFF5A7088),
    chipColor: Color(0xFF3A5068),
    footerBg: Color(0xFFF5F3F0),
    footerTextColor: Color(0xFF8A9098),
  );

  // BIM — Slate & silver
  static const bim = _CardTheme(
    gradientColors: [Color(0xFF1C2833), Color(0xFF2C3E50)],
    textColor: Color(0xFFECF0F1),
    accentColor: Color(0xFFC0C8D0),
    badgeTextColor: Color(0xFFF0F4F8),
    cardBg: Color(0xFFFCFCFD),
    detailTextColor: Color(0xFF2C3E50),
    detailSubtextColor: Color(0xFF7F8C8D),
    chipColor: Color(0xFF5A6A7A),
    footerBg: Color(0xFFF4F5F6),
    footerTextColor: Color(0xFF95A5A6),
  );

  // CK — Forest green & gold
  static const ck = _CardTheme(
    gradientColors: [Color(0xFF0B2618), Color(0xFF1B4332)],
    textColor: Color(0xFFE8F5E8),
    accentColor: Color(0xFF7BC47F),
    badgeTextColor: Color(0xFFE8F8E8),
    cardBg: Color(0xFFFCFEFC),
    detailTextColor: Color(0xFF1B4332),
    detailSubtextColor: Color(0xFF5A8A6A),
    chipColor: Color(0xFF3A6A4A),
    footerBg: Color(0xFFF2F7F2),
    footerTextColor: Color(0xFF7A9A7A),
  );

  // Excellent — Rich indigo & warm white
  static const excellent = _CardTheme(
    gradientColors: [Color(0xFF0D1440), Color(0xFF1A237E)],
    textColor: Color(0xFFE8EAF6),
    accentColor: Color(0xFF7C8CDB),
    badgeTextColor: Color(0xFFE8EAF8),
    cardBg: Color(0xFFFCFCFE),
    detailTextColor: Color(0xFF1A237E),
    detailSubtextColor: Color(0xFF5C6BC0),
    chipColor: Color(0xFF3A4A8A),
    footerBg: Color(0xFFF2F3F8),
    footerTextColor: Color(0xFF8A8FB0),
  );

  // Standard — Warm charcoal & sage
  static const standard = _CardTheme(
    gradientColors: [Color(0xFF2A2D32), Color(0xFF3D4450)],
    textColor: Color(0xFFE8E8E8),
    accentColor: Color(0xFF8A9A7A),
    badgeTextColor: Color(0xFFF0F0E8),
    cardBg: Color(0xFFFCFCFB),
    detailTextColor: Color(0xFF3D4450),
    detailSubtextColor: Color(0xFF7A8090),
    chipColor: Color(0xFF5A6070),
    footerBg: Color(0xFFF4F4F2),
    footerTextColor: Color(0xFF9A9A90),
  );
}

// ══════════════════════════════════════════════════
// Font options for card customization
// ══════════════════════════════════════════════════

// ══════════════════════════════════════════════════
// Background pattern options for card header
// ══════════════════════════════════════════════════

enum _CardPattern {
  none('Ingen', '⊘'),
  geometric('Geometrisk', '◇'),
  circles('Sirkler', '○'),
  lines('Linjer', '▤'),
  dots('Prikker', '⁘'),
  waves('Bølger', '∿'),
  elegant('Elegant', '❧');

  final String displayName;
  final String icon;
  const _CardPattern(this.displayName, this.icon);
}

enum _CardFont {
  standard('Standard'),
  serif('Serif'),
  elegant('Elegant'),
  modern('Modern'),
  classic('Klassisk'),
  handwritten('Håndskrift');

  final String displayName;
  const _CardFont(this.displayName);

  TextStyle Function(double fontSize) get textStyle {
    switch (this) {
      case _CardFont.standard:
        return (size) => TextStyle(fontSize: size);
      case _CardFont.serif:
        return (size) => GoogleFonts.playfairDisplay(fontSize: size);
      case _CardFont.elegant:
        return (size) => GoogleFonts.cormorantGaramond(fontSize: size);
      case _CardFont.modern:
        return (size) => GoogleFonts.montserrat(fontSize: size);
      case _CardFont.classic:
        return (size) => GoogleFonts.lora(fontSize: size);
      case _CardFont.handwritten:
        return (size) => GoogleFonts.dancingScript(fontSize: size);
    }
  }
}

/// Custom corner ornament painter for the elegant pattern
class _CornerPainter extends CustomPainter {
  final Color color;
  final bool flipH;

  _CornerPainter({required this.color, required this.flipH});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (flipH) {
      // Top-right corner ornament
      canvas.drawLine(Offset(size.width, 0), Offset(size.width - 20, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, 20), paint);
      // Inner accent
      canvas.drawLine(Offset(size.width - 5, 5), Offset(size.width - 15, 5), paint);
      canvas.drawLine(Offset(size.width - 5, 5), Offset(size.width - 5, 15), paint);
    } else {
      // Bottom-left corner ornament
      canvas.drawLine(Offset(0, size.height), Offset(20, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(0, size.height - 20), paint);
      // Inner accent
      canvas.drawLine(Offset(5, size.height - 5), Offset(15, size.height - 5), paint);
      canvas.drawLine(Offset(5, size.height - 5), Offset(5, size.height - 15), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      color != oldDelegate.color || flipH != oldDelegate.flipH;
}
