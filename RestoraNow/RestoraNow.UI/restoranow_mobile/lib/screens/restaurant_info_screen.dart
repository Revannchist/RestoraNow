import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/restaurant_provider.dart';
import '../providers/restaurant_review_provider.dart';
import '../providers/base/auth_provider.dart';
import '../widgets/restaurant_info_widgets.dart';

class RestaurantInfoScreen extends StatefulWidget {
  const RestaurantInfoScreen({super.key});

  @override
  State<RestaurantInfoScreen> createState() => _RestaurantInfoScreenState();
}

class _RestaurantInfoScreenState extends State<RestaurantInfoScreen> {
  bool _initialized = false;

  // "Your review" local state
  final _commentCtrl = TextEditingController();
  int _myRating = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAll();
      if (!mounted) return;
      setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final restaurantProv = context.read<RestaurantProvider>();
    await restaurantProv.fetchRestaurant();

    final r = restaurantProv.restaurant;
    if (r != null) {
      await context.read<RestaurantReviewProvider>().fetchForRestaurant(
        r.id,
        pageSize: 100,
      );

      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        final my = context.read<RestaurantReviewProvider>().myReviewFor(userId);
        if (my != null) {
          _myRating = my.rating;
          _commentCtrl.text = my.comment ?? '';
        }
      }
    }
  }

  Future<void> _refresh() async {
    await _loadAll();
    if (mounted) setState(() {});
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final restaurantProv = context.watch<RestaurantProvider>();
    final reviewProv = context.watch<RestaurantReviewProvider>();
    final auth = context.watch<AuthProvider>();

    final restaurant = restaurantProv.restaurant;
    final isLoading = restaurantProv.isLoading && !_initialized;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: const Text('Restaurant'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurantProv.error != null && restaurant == null
          ? ErrorView(message: restaurantProv.error!, onRetry: _refresh)
          : restaurant == null
          ? ErrorView(message: 'No restaurant found.', onRetry: _refresh)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  RestaurantHeader(
                    name: restaurant.name,
                    isActive: restaurant.isActive,
                  ),
                  const SizedBox(height: 12),

                  RatingSummaryTile(
                    avg: reviewProv.averageRating,
                    count: reviewProv.totalCount,
                  ),

                  const SizedBox(height: 8),

                  RestaurantInfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: orDash(restaurant.address),
                  ),
                  RestaurantInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: orDash(restaurant.phoneNumber),
                  ),
                  RestaurantInfoTile(
                    icon: Icons.alternate_email,
                    label: 'Email',
                    value: orDash(restaurant.email),
                  ),

                  if ((restaurant.description ?? '').trim().isNotEmpty)
                    SectionCard(
                      title: 'About',
                      child: Text(
                        restaurant.description!.trim(),
                        style: const TextStyle(height: 1.35),
                      ),
                    ),

                  RestaurantInfoTile(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: formatDateTime(restaurant.createdAt),
                  ),

                  const SizedBox(height: 12),

                  YourReviewCard(
                    submitting: reviewProv.submitting,
                    rating: _myRating,
                    commentController: _commentCtrl,
                    hasExisting:
                        auth.userId != null &&
                        reviewProv.myReviewFor(auth.userId!) != null,
                    onSetRating: (v) => setState(() => _myRating = v),
                    onSave: () async {
                      if (!auth.isAuthenticated) {
                        _snack('Please log in to leave a review.');
                        return;
                      }
                      if (_myRating < 1 || _myRating > 5) {
                        _snack('Please select a rating (1–5).');
                        return;
                      }

                      final userId = auth.userId!;
                      final existing = reviewProv.myReviewFor(userId);

                      final ok = existing == null
                          ? await reviewProv.createReview(
                              userId: userId,
                              restaurantId: restaurant.id,
                              rating: _myRating,
                              comment: _commentCtrl.text.trim().isEmpty
                                  ? null
                                  : _commentCtrl.text.trim(),
                            )
                          : await reviewProv.updateReview(
                              id: existing.id,
                              userId: userId,
                              restaurantId: restaurant.id,
                              rating: _myRating,
                              comment: _commentCtrl.text.trim().isEmpty
                                  ? null
                                  : _commentCtrl.text.trim(),
                            );

                      if (ok) {
                        _snack(
                          existing == null
                              ? 'Thanks for your review!'
                              : 'Your review was updated.',
                        );
                      } else if (reviewProv.error != null) {
                        _snack(reviewProv.error!);
                      }
                    },
                    onClear: () {
                      setState(() {
                        _myRating = 0;
                        _commentCtrl.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  if (reviewProv.reviews.isNotEmpty)
                    SectionCard(
                      title: 'Recent reviews',
                      child: Column(
                        children: reviewProv.reviews
                            .take(10)
                            .map(
                              (r) => ReviewRow(
                                userName: r.userName ?? 'Anonymous',
                                rating: r.rating,
                                comment: r.comment,
                                createdAt: r.createdAt,
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  if (restaurantProv.isLoading || reviewProv.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            ),
    );
  }
}
