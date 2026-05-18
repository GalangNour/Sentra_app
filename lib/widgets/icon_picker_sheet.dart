import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class _IconItem {
  final IconData icon;
  final String label;
  const _IconItem(this.icon, this.label);
}

class _IconGroup {
  final String title;
  final List<_IconItem> items;
  const _IconGroup(this.title, this.items);
}

const _groups = [
  _IconGroup('Makanan & Minuman', [
    _IconItem(Icons.restaurant_rounded, 'restoran'),
    _IconItem(Icons.fastfood_rounded, 'fastfood'),
    _IconItem(Icons.local_cafe_rounded, 'kafe kopi'),
    _IconItem(Icons.coffee_rounded, 'kopi'),
    _IconItem(Icons.lunch_dining_rounded, 'makan siang'),
    _IconItem(Icons.dinner_dining_rounded, 'makan malam'),
    _IconItem(Icons.ramen_dining_rounded, 'mie ramen'),
    _IconItem(Icons.bakery_dining_rounded, 'roti bakery'),
    _IconItem(Icons.cake_rounded, 'kue ulang tahun'),
    _IconItem(Icons.icecream_rounded, 'es krim'),
    _IconItem(Icons.local_pizza_rounded, 'pizza'),
    _IconItem(Icons.egg_alt_rounded, 'telur'),
    _IconItem(Icons.set_meal_rounded, 'set makan'),
    _IconItem(Icons.bento_rounded, 'bento'),
    _IconItem(Icons.local_bar_rounded, 'bar minuman'),
    _IconItem(Icons.wine_bar_rounded, 'wine bar'),
    _IconItem(Icons.liquor_rounded, 'minuman'),
    _IconItem(Icons.local_grocery_store_rounded, 'supermarket belanja'),
    _IconItem(Icons.shopping_basket_rounded, 'keranjang belanja'),
    _IconItem(Icons.food_bank_rounded, 'bank makanan'),
    _IconItem(Icons.soup_kitchen_rounded, 'sup dapur'),
    _IconItem(Icons.outdoor_grill_rounded, 'grill bakar'),
    _IconItem(Icons.kitchen_rounded, 'dapur'),
    _IconItem(Icons.blender_rounded, 'blender'),
  ]),
  _IconGroup('Transportasi', [
    _IconItem(Icons.directions_car_rounded, 'mobil'),
    _IconItem(Icons.two_wheeler_rounded, 'motor'),
    _IconItem(Icons.electric_bike_rounded, 'sepeda listrik'),
    _IconItem(Icons.pedal_bike_rounded, 'sepeda'),
    _IconItem(Icons.directions_bus_rounded, 'bus'),
    _IconItem(Icons.train_rounded, 'kereta'),
    _IconItem(Icons.subway_rounded, 'mrt'),
    _IconItem(Icons.flight_rounded, 'pesawat'),
    _IconItem(Icons.local_taxi_rounded, 'taksi'),
    _IconItem(Icons.electric_car_rounded, 'mobil listrik'),
    _IconItem(Icons.local_gas_station_rounded, 'bensin'),
    _IconItem(Icons.local_shipping_rounded, 'pengiriman'),
    _IconItem(Icons.directions_boat_rounded, 'kapal'),
    _IconItem(Icons.garage_rounded, 'garasi'),
    _IconItem(Icons.car_repair_rounded, 'servis mobil'),
    _IconItem(Icons.traffic_rounded, 'parkir'),
  ]),
  _IconGroup('Belanja', [
    _IconItem(Icons.shopping_bag_rounded, 'belanja tas'),
    _IconItem(Icons.shopping_cart_rounded, 'belanja keranjang'),
    _IconItem(Icons.storefront_rounded, 'toko'),
    _IconItem(Icons.local_mall_rounded, 'mall'),
    _IconItem(Icons.sell_rounded, 'jual beli'),
    _IconItem(Icons.redeem_rounded, 'hadiah voucher'),
    _IconItem(Icons.inventory_2_rounded, 'barang stok'),
    _IconItem(Icons.checkroom_rounded, 'pakaian'),
    _IconItem(Icons.diamond_rounded, 'perhiasan'),
    _IconItem(Icons.watch_rounded, 'jam tangan'),
    _IconItem(Icons.style_rounded, 'gaya fashion'),
    _IconItem(Icons.dry_cleaning_rounded, 'laundry'),
  ]),
  _IconGroup('Hiburan', [
    _IconItem(Icons.sports_esports_rounded, 'game'),
    _IconItem(Icons.videogame_asset_rounded, 'konsol game'),
    _IconItem(Icons.movie_rounded, 'film bioskop'),
    _IconItem(Icons.local_movies_rounded, 'bioskop'),
    _IconItem(Icons.music_note_rounded, 'musik'),
    _IconItem(Icons.headphones_rounded, 'headset audio'),
    _IconItem(Icons.theater_comedy_rounded, 'teater'),
    _IconItem(Icons.celebration_rounded, 'pesta'),
    _IconItem(Icons.casino_rounded, 'kasino'),
    _IconItem(Icons.attractions_rounded, 'wahana hiburan'),
    _IconItem(Icons.festival_rounded, 'festival'),
    _IconItem(Icons.tv_rounded, 'televisi'),
    _IconItem(Icons.live_tv_rounded, 'streaming tv'),
    _IconItem(Icons.camera_alt_rounded, 'kamera foto'),
    _IconItem(Icons.photo_camera_rounded, 'foto'),
    _IconItem(Icons.sports_bar_rounded, 'nonton bareng'),
  ]),
  _IconGroup('Olahraga', [
    _IconItem(Icons.sports_soccer_rounded, 'sepak bola'),
    _IconItem(Icons.sports_basketball_rounded, 'basket'),
    _IconItem(Icons.sports_tennis_rounded, 'tenis'),
    _IconItem(Icons.sports_volleyball_rounded, 'voli'),
    _IconItem(Icons.sports_golf_rounded, 'golf'),
    _IconItem(Icons.fitness_center_rounded, 'gym olahraga'),
    _IconItem(Icons.pool_rounded, 'kolam renang'),
    _IconItem(Icons.sports_martial_arts_rounded, 'bela diri'),
    _IconItem(Icons.directions_run_rounded, 'lari'),
    _IconItem(Icons.hiking_rounded, 'hiking'),
    _IconItem(Icons.kayaking_rounded, 'kayak'),
    _IconItem(Icons.snowboarding_rounded, 'snowboard'),
  ]),
  _IconGroup('Kesehatan', [
    _IconItem(Icons.local_hospital_rounded, 'rumah sakit'),
    _IconItem(Icons.medical_services_rounded, 'layanan medis'),
    _IconItem(Icons.health_and_safety_rounded, 'kesehatan'),
    _IconItem(Icons.medication_rounded, 'obat'),
    _IconItem(Icons.healing_rounded, 'penyembuhan'),
    _IconItem(Icons.spa_rounded, 'spa'),
    _IconItem(Icons.self_improvement_rounded, 'meditasi'),
    _IconItem(Icons.monitor_heart_rounded, 'jantung'),
    _IconItem(Icons.psychology_rounded, 'psikologi'),
    _IconItem(Icons.vaccines_rounded, 'vaksin'),
    _IconItem(Icons.sanitizer_rounded, 'sanitasi'),
    _IconItem(Icons.local_pharmacy_rounded, 'apotek'),
    _IconItem(Icons.face_retouching_natural_rounded, 'perawatan'),
    _IconItem(Icons.content_cut_rounded, 'potong rambut'),
  ]),
  _IconGroup('Rumah & Utilitas', [
    _IconItem(Icons.home_rounded, 'rumah'),
    _IconItem(Icons.house_rounded, 'rumah tinggal'),
    _IconItem(Icons.apartment_rounded, 'apartemen'),
    _IconItem(Icons.electrical_services_rounded, 'listrik'),
    _IconItem(Icons.water_drop_rounded, 'air pdam'),
    _IconItem(Icons.bolt_rounded, 'tagihan listrik'),
    _IconItem(Icons.wifi_rounded, 'wifi internet'),
    _IconItem(Icons.router_rounded, 'router internet'),
    _IconItem(Icons.cleaning_services_rounded, 'cleaning'),
    _IconItem(Icons.handyman_rounded, 'tukang'),
    _IconItem(Icons.construction_rounded, 'renovasi'),
    _IconItem(Icons.plumbing_rounded, 'pipa ledeng'),
    _IconItem(Icons.chair_rounded, 'furnitur'),
    _IconItem(Icons.bed_rounded, 'kasur'),
    _IconItem(Icons.bathtub_rounded, 'kamar mandi'),
    _IconItem(Icons.yard_rounded, 'taman'),
  ]),
  _IconGroup('Pendidikan', [
    _IconItem(Icons.school_rounded, 'sekolah'),
    _IconItem(Icons.book_rounded, 'buku'),
    _IconItem(Icons.library_books_rounded, 'perpustakaan'),
    _IconItem(Icons.menu_book_rounded, 'membaca'),
    _IconItem(Icons.science_rounded, 'sains'),
    _IconItem(Icons.calculate_rounded, 'matematika'),
    _IconItem(Icons.edit_rounded, 'tulis belajar'),
    _IconItem(Icons.article_rounded, 'artikel'),
    _IconItem(Icons.quiz_rounded, 'kuis ujian'),
    _IconItem(Icons.workspace_premium_rounded, 'sertifikat'),
    _IconItem(Icons.emoji_objects_rounded, 'ide belajar'),
    _IconItem(Icons.language_rounded, 'bahasa'),
  ]),
  _IconGroup('Keuangan', [
    _IconItem(Icons.account_balance_rounded, 'bank'),
    _IconItem(Icons.savings_rounded, 'tabungan'),
    _IconItem(Icons.credit_card_rounded, 'kartu kredit'),
    _IconItem(Icons.attach_money_rounded, 'uang'),
    _IconItem(Icons.currency_exchange_rounded, 'tukar uang'),
    _IconItem(Icons.receipt_long_rounded, 'struk'),
    _IconItem(Icons.wallet_rounded, 'dompet'),
    _IconItem(Icons.business_center_rounded, 'bisnis'),
    _IconItem(Icons.trending_up_rounded, 'investasi naik'),
    _IconItem(Icons.trending_down_rounded, 'pengeluaran turun'),
    _IconItem(Icons.paid_rounded, 'dibayar'),
    _IconItem(Icons.monetization_on_rounded, 'uang koin'),
  ]),
  _IconGroup('Teknologi', [
    _IconItem(Icons.smartphone_rounded, 'hp smartphone'),
    _IconItem(Icons.computer_rounded, 'komputer'),
    _IconItem(Icons.laptop_rounded, 'laptop'),
    _IconItem(Icons.tablet_rounded, 'tablet'),
    _IconItem(Icons.headset_rounded, 'headset'),
    _IconItem(Icons.keyboard_rounded, 'keyboard'),
    _IconItem(Icons.mouse_rounded, 'mouse'),
    _IconItem(Icons.print_rounded, 'printer'),
    _IconItem(Icons.home_work_rounded, 'smart home'),
    _IconItem(Icons.cloud_rounded, 'cloud'),
    _IconItem(Icons.storage_rounded, 'storage'),
    _IconItem(Icons.gamepad_rounded, 'gamepad'),
  ]),
  _IconGroup('Perjalanan', [
    _IconItem(Icons.travel_explore_rounded, 'wisata'),
    _IconItem(Icons.luggage_rounded, 'koper'),
    _IconItem(Icons.map_rounded, 'peta'),
    _IconItem(Icons.explore_rounded, 'jelajah'),
    _IconItem(Icons.beach_access_rounded, 'pantai'),
    _IconItem(Icons.landscape_rounded, 'alam'),
    _IconItem(Icons.park_rounded, 'taman'),
    _IconItem(Icons.hotel_rounded, 'hotel'),
    _IconItem(Icons.villa_rounded, 'villa'),
    _IconItem(Icons.hiking_rounded, 'hiking alam'),
    _IconItem(Icons.camera_outdoor_rounded, 'foto wisata'),
    _IconItem(Icons.nightlife_rounded, 'malam'),
  ]),
  _IconGroup('Sosial & Keluarga', [
    _IconItem(Icons.people_rounded, 'orang keluarga'),
    _IconItem(Icons.person_rounded, 'personal'),
    _IconItem(Icons.child_care_rounded, 'anak bayi'),
    _IconItem(Icons.favorite_rounded, 'favorit cinta'),
    _IconItem(Icons.pets_rounded, 'hewan peliharaan'),
    _IconItem(Icons.volunteer_activism_rounded, 'donasi'),
    _IconItem(Icons.church_rounded, 'ibadah gereja'),
    _IconItem(Icons.mosque_rounded, 'masjid'),
    _IconItem(Icons.emoji_people_rounded, 'sosial'),
    _IconItem(Icons.card_giftcard_rounded, 'hadiah'),
    _IconItem(Icons.cake_rounded, 'ulang tahun'),
    _IconItem(Icons.star_rounded, 'bintang'),
  ]),
];

// Flat list computed once — avoids nested loop on every search
final _allItems = _groups.expand((g) => g.items).toList(growable: false);

// Total count computed once — avoids fold() in every build
final _totalIconCount = _allItems.length;

class IconPickerSheet extends StatefulWidget {
  final IconData? current;

  const IconPickerSheet({super.key, this.current});

  static Future<IconData?> show(BuildContext context, {IconData? current}) {
    return showModalBottomSheet<IconData>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => IconPickerSheet(current: current),
    );
  }

  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<_IconItem> _results = const [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
      });
      return;
    }
    // Wait 200ms after user stops typing before filtering
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final q = trimmed.toLowerCase();
      final results = _allItems.where((item) => item.label.contains(q)).toList(growable: false);
      if (mounted) {
        setState(() {
          _query = trimmed;
          _results = results;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Pilih Ikon',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_totalIconCount ikon',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari ikon... (makan, mobil, gym)',
                  hintStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _debounce?.cancel();
                            _searchCtrl.clear();
                            setState(() {
                              _query = '';
                              _results = const [];
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Divider(color: AppColors.surfaceBorder, height: 1),
            // Icon grid — RepaintBoundary isolates repaints from the header/search bar
            Expanded(
              child: RepaintBoundary(
                child: searching
                    ? _buildSearchGrid(scrollCtrl)
                    : _buildCategoryList(scrollCtrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchGrid(ScrollController ctrl) {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Ikon tidak ditemukan',
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba kata kunci lain',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) => _iconCell(_results[i]),
    );
  }

  Widget _buildCategoryList(ScrollController ctrl) {
    return CustomScrollView(
      controller: ctrl,
      slivers: [
        for (final group in _groups) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                group.title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _iconCell(group.items[i]),
                childCount: group.items.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _iconCell(_IconItem item) {
    final isSelected = widget.current?.codePoint == item.icon.codePoint;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(item.icon);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(26)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              item.label.split(' ').first,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 9,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
