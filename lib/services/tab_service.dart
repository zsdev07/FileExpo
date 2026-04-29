import 'dart:io';
import 'package:flutter/material.dart';

class TabInfo {
  Directory directory;
  String name;
  List<FileSystemEntity> history = [];

  TabInfo({required this.directory, required this.name});
}

class TabService extends ChangeNotifier {
  final List<TabInfo> _tabs = [
    TabInfo(directory: Directory('/storage/emulated/0'), name: 'Internal Storage')
  ];
  int _activeTabIndex = 0;
  int _secondaryTabIndex = 0; // For dual-pane

  List<TabInfo> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  int get secondaryTabIndex => _secondaryTabIndex;

  void addTab(Directory directory, String name) {
    _tabs.add(TabInfo(directory: directory, name: name));
    _activeTabIndex = _tabs.length - 1;
    notifyListeners();
  }

  void removeTab(int index) {
    if (_tabs.length > 1) {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) _activeTabIndex = _tabs.length - 1;
      if (_secondaryTabIndex >= _tabs.length) _secondaryTabIndex = 0;
      notifyListeners();
    }
  }

  void setActiveTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  void setSecondaryTab(int index) {
    _secondaryTabIndex = index;
    notifyListeners();
  }

  void updateTabPath(int index, Directory newDir) {
    _tabs[index].directory = newDir;
    notifyListeners();
  }
}
