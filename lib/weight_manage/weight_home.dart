import 'package:flutter/material.dart';
import 'package:progressai/weight_manage/tabbars/doctor_screen.dart';
import 'package:progressai/weight_manage/tabbars/fitness_screen.dart';
import 'package:progressai/weight_manage/tabbars/nutritionist_screen.dart';
import 'package:progressai/weight_manage/tabbars/psychology_screen.dart';
import 'package:progressai/weight_manage/tabbars/user_profile_screen.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:progressai/weight_manage/weight_chat.dart';

class WeightHome extends StatefulWidget {
  final InferenceChat chatEngine;
  final int? initialTabIndex; // 新增参数：初始选中的Tab索引

  const WeightHome({
    super.key,
    required this.chatEngine,
    this.initialTabIndex, // 使其可选
  });

  @override
  State<WeightHome> createState() => _WeightHomeState();
}

class _WeightHomeState extends State<WeightHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTitles = ['Basic', 'Doctor', 'Nutritionist', 'Fitness', 'Psychology'];
  final List<IconData> _tabIcons = [
    Icons.person,
    Icons.medical_services,
    Icons.restaurant,
    Icons.fitness_center,
    Icons.psychology,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0, // 使用传入的索引，默认为0
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Management'),
        centerTitle: true,
        backgroundColor: Colors.orange[100],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepOrange,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          tabs: List.generate(_tabTitles.length, (index) {
            return Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_tabIcons[index]),
                  Text(_tabTitles[index]),
                ],
              ),
            );
          }),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ // 使用 const 确保这些屏幕是常量，优化性能
          // Basic Tab - User Profile Screen
          UserProfileScreen(),
          // Doctor Tab - Doctor Screen
          DoctorScreen(),
          // Nutritionist Tab - Nutritionist Screen
          NutritionistScreen(),
          // Fitness Tab - Fitness Screen
          FitnessScreen(),
          // Psychology Tab - Psychology Screen
          PsychologyScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the chat page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WeightChatPage(chatEngine: widget.chatEngine)),
          );
        },
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat),
      ),
    );
  }
}
