import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/components/Banner/M/banner_m_style_1.dart';
import 'package:melaq/components/dot_indicators.dart';
import 'package:melaq/components/api_extintion/url_api.dart';

import '../../../../constants.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({
    super.key,
  });

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late Timer _timer;
  List<Map<String, dynamic>> _bannerData = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    fetchBannerData();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_selectedIndex < _bannerData.length - 1) {
        _selectedIndex++;
      } else {
        _selectedIndex = 0;
      }

      _pageController.animateToPage(
        _selectedIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchBannerData() async {
    try {
      // Call the API to fetch the banner data
      final response = await http.get(Uri.parse(APIConfig.bannerEndpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _bannerData = data
              .map((item) => {
                    'image': item['image'],
                    'caption': item['caption'] != null ? utf8.decode(item['caption'].codeUnits) : '', // إصلاح هنا
                    'order': item['order'],
                  })
              .toList();
          _bannerData.sort((a, b) => a['order'].compareTo(b['order']));
        });
      } else {
        // Handle error cases
        print('Error fetching banner data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Error fetching banner data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.87,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // عرض الصور مع تأثير انتقال سلس
              PageView.builder(
                controller: _pageController,
                itemCount: _bannerData.isEmpty ? 1 : _bannerData.length,
                onPageChanged: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  // عرض صورة افتراضية إذا لم تكن هناك بيانات من API
                  if (_bannerData.isEmpty) {
                    return BannerMStyle1(
                      text: "",
                      image: "",
                      press: () {},
                    );
                  }
                  
                  final banner = _bannerData[index];
                  return BannerMStyle1(
                    text: banner['caption'] ?? '',
                    image: banner['image'] ?? "https://i.imgur.com/aA8ST9l.jpeg",
                    press: () {
                      // Add your banner click logic here
                    },
                  );
                },
              ),
              
              // مؤشرات النقاط بتصميم محسّن
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _bannerData.isEmpty ? 1 : _bannerData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: index == _selectedIndex ? 24 : 8,
                      decoration: BoxDecoration(
                        color: index == _selectedIndex 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              // أزرار التنقل (اختياري)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر السابق
                    GestureDetector(
                      onTap: () {
                        if (_selectedIndex > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    
                    // زر التالي
                    GestureDetector(
                      onTap: () {
                        if (_selectedIndex < (_bannerData.isEmpty ? 0 : _bannerData.length - 1)) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
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
    );
  }
}