import 'package:flutter/material.dart';
import '../services/settings_store.dart';
import '../services/tab_session_store.dart';
import 'home_screen.dart';

class _TabData {
  final int id;
  String? path; // null = "use the default start location"

  _TabData({required this.id, this.path});

  String get label =>
      path == null ? 'Home' : path!.split('/').where((s) => s.isNotEmpty).last;
}

/// Shows a strip of tabs above independent [HomeScreen] instances, one per
/// tab. Each [HomeScreen] keeps its own complete navigation state (path,
/// search, selection) exactly as it does standalone — [IndexedStack] keeps
/// every tab's widget tree alive simultaneously, just hiding the inactive
/// ones, so switching tabs needs no state hand-off logic at all.
class TabsHost extends StatefulWidget {
  const TabsHost({super.key});

  @override
  State<TabsHost> createState() => _TabsHostState();
}

class _TabsHostState extends State<TabsHost> {
  final _tabStore = TabSessionStore();
  final List<_TabData> _tabs = [];
  int _activeIndex = 0;
  int _nextId = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    List<String> paths = const [];
    var activeIndex = 0;

    if (SettingsStore.instance.sessionRestoreEnabled) {
      paths = await _tabStore.loadPaths();
      activeIndex = await _tabStore.loadActiveIndex();
    }
    if (paths.isEmpty) paths = const [''];

    if (!mounted) return;
    setState(() {
      _tabs.addAll([
        for (final p in paths) _TabData(id: _nextId++, path: p.isEmpty ? null : p),
      ]);
      _activeIndex = activeIndex.clamp(0, _tabs.length - 1);
      _ready = true;
    });
  }

  void _persist() {
    final paths = _tabs.map((t) => t.path ?? '').toList();
    _tabStore.save(paths, _activeIndex);
  }

  void _addTab() {
    setState(() {
      _tabs.add(_TabData(id: _nextId++));
      _activeIndex = _tabs.length - 1;
    });
    _persist();
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) return; // always keep at least one tab open
    setState(() {
      _tabs.removeAt(index);
      if (_activeIndex >= _tabs.length) {
        _activeIndex = _tabs.length - 1;
      } else if (_activeIndex > index) {
        _activeIndex--;
      }
    });
    _persist();
  }

  void _selectTab(int index) {
    setState(() => _activeIndex = index);
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TabStrip(
              count: _tabs.length,
              activeIndex: _activeIndex,
              labelBuilder: (i) => _tabs[i].label,
              onSelect: _selectTab,
              onClose: _closeTab,
              onAdd: _addTab,
            ),
            Expanded(
              child: IndexedStack(
                index: _activeIndex,
                children: [
                  for (final tab in _tabs)
                    HomeScreen(
                      key: ValueKey(tab.id),
                      initialPath: tab.path,
                      onPathChanged: (path) {
                        // setState so the tab strip's label (the current
                        // folder name) updates live while browsing, not
                        // just when switching tabs.
                        setState(() => tab.path = path);
                        _persist();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  final int count;
  final int activeIndex;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;
  final VoidCallback onAdd;

  const _TabStrip({
    required this.count,
    required this.activeIndex,
    required this.labelBuilder,
    required this.onSelect,
    required this.onClose,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      color: scheme.surfaceContainerHigh,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              itemBuilder: (context, index) {
                final active = index == activeIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onSelect(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? scheme.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            labelBuilder(index),
                            style: TextStyle(
                              color: active
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (count > 1) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => onClose(index),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: active
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New tab',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
