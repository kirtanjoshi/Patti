import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../core/theme/patii_theme.dart';
import '../../core/widgets/patii_widgets.dart';
import 'widgets/audio_studio_section.dart';

/// Design System Component Gallery Screen (`/dev/gallery`)
/// Showcases every theme token, shared component, and interactive state.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _coins = 12500;
  String? _selectedHandCardId = '10S';
  int _turnSeconds = 12;
  bool _isTurnActive = true;
  Offset? _chipTossStart;
  Offset? _chipTossEnd;
  bool _isTossing = false;

  final List<engine.Card> _demo13Hand = [
    const engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'AS'),
    const engine.Card(suit: engine.Suit.S, rank: 13, deck: 0, id: 'KS'),
    const engine.Card(suit: engine.Suit.S, rank: 12, deck: 0, id: 'QS'),
    const engine.Card(suit: engine.Suit.S, rank: 11, deck: 0, id: 'JS'),
    const engine.Card(suit: engine.Suit.S, rank: 10, deck: 0, id: '10S'),
    const engine.Card(suit: engine.Suit.H, rank: 1, deck: 0, id: 'AH'),
    const engine.Card(suit: engine.Suit.H, rank: 10, deck: 0, id: '10H'),
    const engine.Card(suit: engine.Suit.H, rank: 7, deck: 0, id: '7H'),
    const engine.Card(suit: engine.Suit.D, rank: 13, deck: 0, id: 'KD'),
    const engine.Card(suit: engine.Suit.D, rank: 9, deck: 0, id: '9D'),
    const engine.Card(suit: engine.Suit.C, rank: 8, deck: 0, id: '8C'),
    const engine.Card(suit: engine.Suit.C, rank: 4, deck: 0, id: '4C'),
    const engine.Card(suit: engine.Suit.C, rank: 2, deck: 0, id: '2C'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatiiColors.navy,
      appBar: AppBar(
        title: Text(
          'Component Gallery',
          style: PatiiTypography.titleLarge,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CoinCounter(
              coins: _coins,
              showPlusButton: true,
              onPlusTap: () => setState(() => _coins += 500),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(PatiiSpacing.s16),
            children: [
              _buildSectionTitle('1. Typography Tokens'),
              _buildTypographySection(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle('2. Color Tokens & Swatches'),
              _buildColorSwatches(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle('3. Buttons (Gold CTA, Ghost, Danger)'),
              _buildButtonsSection(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle('4. Playing Cards (States & Styles)'),
              _buildPlayingCardsSection(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle(
                  '5. Overlapping Card Hand (Callbreak 13-Card Fan)'),
              Text(
                'Full hand guaranteed to fit width; tap to select, drag up to play',
                style: PatiiTypography.bodySmall,
              ),
              const SizedBox(height: PatiiSpacing.s8),
              CardHand(
                cards: _demo13Hand,
                selectedCardId: _selectedHandCardId,
                wildOrMaalCardId: 'AS',
                playableCardIds: {'AS', 'KS', 'QS', 'JS', '10S'},
                onCardTap: (card) {
                  setState(() => _selectedHandCardId = card.id);
                  ToastBanner.show(context, 'Selected ${card.id}');
                },
                onCardPlay: (card) {
                  ToastBanner.show(
                    context,
                    'Played ${card.id}!',
                    icon: Icons.play_arrow,
                  );
                },
              ),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle(
                  '6. Player Seats (Circular 52px, Timer Ring, Badges)'),
              _buildPlayerSeatsSection(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle('7. Casino Chips & Stacks'),
              _buildChipsSection(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle(
                  '8. Table Felt (Wood Rail, Gold Line, Watermark)'),
              _buildTableFeltPreview(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle('9. Glass Panels & Sheets'),
              _buildGlassSection(),
              const SizedBox(height: PatiiSpacing.s24),
              _buildSectionTitle('10. Audio & Sound Design Studio'),
              const AudioStudioSection(),
              const SizedBox(height: PatiiSpacing.s32),
            ],
          ),

          // Chip toss overlay
          if (_isTossing && _chipTossStart != null && _chipTossEnd != null)
            ChipToss(
              startOffset: _chipTossStart!,
              endOffset: _chipTossEnd!,
              amount: 500,
              onComplete: () {
                setState(() => _isTossing = false);
                ToastBanner.show(context, 'Pot collected 500 chips!');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PatiiSpacing.s8),
      child: Text(
        title,
        style: PatiiTypography.titleMedium,
      ),
    );
  }

  Widget _buildTypographySection() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sora Display Heading: POT 4,800 COINS',
              style: PatiiTypography.potDisplay),
          const SizedBox(height: 4),
          Text('Title Large (Sora): Callbreak Nepali Table',
              style: PatiiTypography.titleLarge),
          const SizedBox(height: 4),
          Text('Body Large (Mukta): Real-time multiplayer card action',
              style: PatiiTypography.bodyLarge),
          const SizedBox(height: 4),
          Text('Nepali Mukta: पत्ती — कल ब्रेक, म्यारिज र तीन पत्ती खेल्नुहोस्',
              style: PatiiTypography.mukta(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildColorSwatches() {
    final swatches = [
      ('Felt Green', PatiiColors.feltGreen),
      ('Felt Dark', PatiiColors.feltGreenDark),
      ('Wood Rail', PatiiColors.woodRailEnd),
      ('Gold', PatiiColors.gold),
      ('Gold Light', PatiiColors.goldLight),
      ('Crimson', PatiiColors.crimson),
      ('Navy', PatiiColors.navy),
      ('Navy Surface', PatiiColors.navySurface),
    ];

    return Wrap(
      spacing: PatiiSpacing.s8,
      runSpacing: PatiiSpacing.s8,
      children: swatches.map((s) {
        return Container(
          width: 80,
          padding: const EdgeInsets.all(PatiiSpacing.s8),
          decoration: BoxDecoration(
            color: s.$2,
            borderRadius: PatiiSpacing.rounded8,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Container(height: 24),
              Text(
                s.$1,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButtonsSection() {
    return Wrap(
      spacing: PatiiSpacing.s12,
      runSpacing: PatiiSpacing.s12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GoldButton(
          label: 'Claim Bonus',
          icon: Icons.stars,
          onPressed: () {
            setState(() => _coins += 1000);
            ToastBanner.show(context, 'Claimed 1,000 Coins!',
                icon: Icons.stars);
          },
        ),
        GhostButton(
          label: 'Side Show',
          icon: Icons.visibility,
          onPressed: () {
            ToastBanner.show(context, 'Side Show Requested');
          },
        ),
        DangerButton(
          label: 'Pack / Fold',
          icon: Icons.close,
          onPressed: () {
            ToastBanner.show(context, 'Folded Hand', icon: Icons.flag);
          },
        ),
        const GoldButton(
          label: 'Disabled',
          isEnabled: false,
          onPressed: null,
        ),
      ],
    );
  }

  Widget _buildPlayingCardsSection() {
    return Wrap(
      spacing: PatiiSpacing.s12,
      runSpacing: PatiiSpacing.s12,
      children: const [
        // Standard Ace
        PlayingCard(
          card: engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'AS'),
        ),
        // Court Card King
        PlayingCard(
          card: engine.Card(suit: engine.Suit.H, rank: 13, deck: 0, id: 'KH'),
        ),
        // Selected with 16px lift & gold glow
        PlayingCard(
          card: engine.Card(suit: engine.Suit.D, rank: 12, deck: 0, id: 'QD'),
          isSelected: true,
        ),
        // Non-playable (40% darkened)
        PlayingCard(
          card: engine.Card(suit: engine.Suit.C, rank: 10, deck: 0, id: '10C'),
          isPlayable: false,
        ),
        // Wild / Maal Badge
        PlayingCard(
          card: engine.Card(suit: engine.Suit.H, rank: 11, deck: 0, id: 'JH'),
          badgeText: 'MAAL',
        ),
        // Card Back with Dhaka pattern
        PlayingCard(
          card: engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'BACK'),
          isFaceDown: true,
        ),
        // Physical Stacked Stock Deck (3D layered thickness)
        StackedDeck(
          topCard: engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'STOCK'),
          isFaceDown: true,
          cardCount: 32,
          width: 52,
          height: 74,
          label: 'STOCK',
        ),
        // Physical Discard Stack (with realistic spread)
        StackedDeck(
          topCard: engine.Card(suit: engine.Suit.H, rank: 13, deck: 0, id: 'KH_DISCARD'),
          isFaceDown: false,
          cardCount: 8,
          width: 52,
          height: 74,
          label: 'DISCARD',
          spreadDiscard: true,
        ),
      ],
    );
  }

  Widget _buildPlayerSeatsSection() {
    return GlassPanel(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PlayerSeat(
                displayName: 'You (Host)',
                isCurrentTurn: _isTurnActive,
                isDealer: true,
                infoPillText: 'Bid 3 · Won 2',
                remainingSeconds: _turnSeconds,
              ),
              PlayerSeat(
                displayName: 'Bot Bikash',
                isBot: true,
                isCurrentTurn: !_isTurnActive,
                infoPillText: 'Bid 4 · Won 1',
                remainingSeconds: 15,
              ),
              const PlayerSeat(
                displayName: 'Aayush',
                isFolded: true,
                infoPillText: 'PACKED',
              ),
            ],
          ),
          const SizedBox(height: PatiiSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GhostButton(
                label: _isTurnActive ? 'Pass Turn' : 'Take Turn',
                onPressed: () => setState(() => _isTurnActive = !_isTurnActive),
              ),
              const SizedBox(width: PatiiSpacing.s12),
              GhostButton(
                label: 'Trigger Urgent Timer (3s)',
                onPressed: () => setState(() => _turnSeconds = 3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipsSection() {
    return Builder(
      builder: (btnContext) {
        return GlassPanel(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const CasinoChip(denomination: ChipDenomination.c10),
              const CasinoChip(denomination: ChipDenomination.c50),
              const CasinoChip(denomination: ChipDenomination.c100),
              const CasinoChip(denomination: ChipDenomination.c500),
              const CasinoChip(denomination: ChipDenomination.c1000),
              const ChipStack(totalAmount: 1850),
              GoldButton(
                label: 'Toss 500',
                icon: Icons.toll,
                onPressed: () {
                  final box = btnContext.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final pos = box.localToGlobal(Offset.zero);
                    setState(() {
                      _chipTossStart = pos + const Offset(40, 20);
                      _chipTossEnd = Offset(pos.dx + 120, pos.dy - 100);
                      _isTossing = true;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableFeltPreview() {
    return SizedBox(
      height: 180,
      child: TableFelt(
        shape: TableFeltShape.roundedRect,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CASINO GREEN TABLE FELT',
                style: PatiiTypography.display(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.goldLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Radial gradient + 14px Wood Rail + Gold Inner Line',
                style: PatiiTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSection() {
    return GlassPanel(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GoldButton(
            label: 'Show Toast Banner',
            onPressed: () {
              ToastBanner.show(
                context,
                'Bot 2 wins the trick!',
                icon: Icons.emoji_events,
              );
            },
          ),
          GhostButton(
            label: 'Open Bottom Sheet',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => GlassSheet(
                  title: 'Select Callbreak Bid',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(8, (i) {
                      final bid = i + 1;
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: PatiiColors.gold),
                        ),
                        child: Center(
                          child: Text(
                            '$bid',
                            style: PatiiTypography.display(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: PatiiColors.goldLight,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
