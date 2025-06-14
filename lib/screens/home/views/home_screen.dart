import 'package:flutter/material.dart';
import 'package:melaq/chcek_connect.dart';
import 'components/best_sellers.dart';
import 'components/offer_carousel_and_categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // إضافة متغير للتحكم في BestSellers
  final GlobalKey<BestSellersState> _bestSellersKey = GlobalKey<BestSellersState>();
  
  @override
  void initState() {
    super.initState();
  }

  // دالة تحديث المغاسل فقط
  Future<void> _refreshLaundries() async {
    await _bestSellersKey.currentState?.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshLaundries, // تحديث المغاسل فقط عند السحب للأسفل
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: OffersCarouselAndCategories()),
              SliverToBoxAdapter(
                child: BestSellers(key: _bestSellersKey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
