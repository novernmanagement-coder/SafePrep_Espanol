import 'package:flutter/material.dart';
import 'constants.dart';
import 'app_state.dart';
import 'mixpanel_service.dart';
import 'iap_service.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'rapid_fire_page.dart';
import 'onboard/onboard_paywall.dart';

// UPDATED — brought in line with SafePrep Manager's current nav bar,
// which fixed a real access gap: previously Dashboard and Rapid Fire
// had NO lock check here at all, so a never-purchased or expired user
// reaching this footer from anywhere in the app (not just the splash
// routing) could tap straight into paid content. Both buttons now
// check AppState directly and redirect to OnboardPaywall when locked,
// same as Manager.
//
// Also drops the old trial-timer countdown slot (_TrialTimerNavButton
// / TrialTimerService) — that belonged to the old 30-minute-trial
// model this app no longer uses (see splash_page.dart's own note on
// this same removal). It's replaced with a plain "Desbloquear" button
// that only shows for never-purchased users, mirroring Manager's
// Unlock slot.
//
// DIVERGES from Manager on one point, a deliberate scope call: no
// Renew slot (_RenewNavButton / RenewPage) — the $2.99 renewal IAP
// hasn't been ported to Español yet. Add it back once that feature
// lands here; until then, an expiring/expired time-limited purchaser
// simply falls into the locked state above and re-purchases through
// OnboardPaywall like a first-time buyer.
//
// Layout also switched from fixed-width SizedBox buttons in a
// spaceEvenly Row to Expanded slots in a flex Row (matching Manager) —
// the fixed 110px width was sized for English labels and risked
// clipping/overflow on the longer Spanish label ("Ráfaga Rápida").
class SafePrepNavBar extends StatefulWidget {
  /// Kept for call-site compatibility with DashboardPage (matches
  /// Manager, which also keeps this parameter without using it in
  /// build() — a vestige of the removed trial-timer display, harmless
  /// to leave in place).
  final bool isDashboardPage;

  const SafePrepNavBar({super.key, this.isDashboardPage = false});

  @override
  State<SafePrepNavBar> createState() => _SafePrepNavBarState();
}

class _SafePrepNavBarState extends State<SafePrepNavBar> {
  bool _purchaseInFlight = false;

  void _goHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  // Gated on real purchase state — either never purchased, or a
  // sevenDay purchase whose calendar expiry has passed
  // (AppState.isExpired, purchaseDate + duration vs. now). Locked
  // users route to OnboardPaywall — the sole active in-app paywall.
  void _goDashboard(BuildContext context) {
    final state = AppState();
    final bool locked = !state.hasUnlockedApp || state.isExpired;
    if (locked) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardPaywall()),
        (route) => false,
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  // Same gate as _goDashboard().
  void _goRapidFire(BuildContext context) {
    final state = AppState();
    final bool locked = !state.hasUnlockedApp || state.isExpired;
    if (locked) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardPaywall()),
        (route) => false,
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RapidFirePage()),
    );
  }

  // Unlock button only — the single first-purchase product
  // (kProductSevenDay, a non-consumable).
  Future<void> _buyNow(BuildContext context) async {
    if (_purchaseInFlight) return;
    setState(() => _purchaseInFlight = true);

    MixpanelService.instance.track(
      'paywall_viewed',
      properties: {'source': 'nav_bar', 'app_name': 'ES'},
    );

    final result = await IAPService.instance.buySevenDay();

    if (!mounted) return;
    setState(() => _purchaseInFlight = false);

    if (result == IAPResult.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Desbloqueaste SafePrep! 🎉')));
      return;
    }

    if (result == IAPResult.canceled) {
      return;
    }

    final message = result.userMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final bool isUnlocked = state.hasUnlockedApp;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        spacing: 6,
        children: [
          Expanded(
            child: _NavButton(
              icon: Icons.home_outlined,
              label: 'Inicio',
              onTap: () => _goHome(context),
            ),
          ),
          Expanded(
            child: _NavButton(
              icon: Icons.dashboard_outlined,
              label: 'Panel',
              onTap: () => _goDashboard(context),
            ),
          ),
          Expanded(
            child: _NavButton(
              icon: Icons.bolt_outlined,
              label: 'Ráfaga Rápida',
              onTap: () => _goRapidFire(context),
            ),
          ),
          if (!isUnlocked)
            Expanded(
              child: _UnlockNavButton(
                loading: _purchaseInFlight,
                onTap: () => _buyNow(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnlockNavButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _UnlockNavButton({required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: SizedBox(
        height: AppSizes.footerButtonHeight,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: AppSizes.buttonBorderThickness,
            ),
            borderRadius: BorderRadius.circular(
              AppSizes.footerButtonCornerRadius,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFD4AF37),
                      ),
                    )
                  : const Icon(Icons.star, size: 18, color: Color(0xFFD4AF37)),
              Text(
                'Desbloquear',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFonts.label,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: AppSizes.footerButtonHeight,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondaryButton,
            border: Border.all(
              color: AppColors.footerButtonBorder,
              width: AppSizes.buttonBorderThickness,
            ),
            borderRadius: BorderRadius.circular(
              AppSizes.footerButtonCornerRadius,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              Icon(icon, size: 18, color: AppColors.secondaryButtonForeground),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppFonts.label,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryButtonForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
