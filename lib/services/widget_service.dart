// ignore_for_file: avoid_print

import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _groupId = 'group.whisptask.widget';
  
  static Future<void> initializeWidget() async {
    await HomeWidget.setAppGroupId(_groupId);
  }
  
  static Future<void> updateTaskWidget(List<String> taskTitles) async {
    try {
      // Update widget with current tasks
      await HomeWidget.saveWidgetData<String>('task_count', taskTitles.length.toString());
      await HomeWidget.saveWidgetData<String>('next_task', 
        taskTitles.isNotEmpty ? taskTitles.first : 'No tasks');
      
      // Update the widget
      await HomeWidget.updateWidget(
        name: 'WhispTaskWidget',
        androidName: 'WhispTaskWidget',
        iOSName: 'WhispTaskWidget',
      );
    } catch (e) {
      print('Widget update failed: $e');
    }
  }
}
