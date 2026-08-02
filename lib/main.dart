import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'scan_page.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_constants.dart';


// App entry point.
// This starts the RFID organizer app and loads the first screen.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// Page: Main screen.
// This page manages the app shell, drawer navigation, and shared list state.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<InventoryList> _createdLists = [];
  InventoryList? _selectedFeaturedList;
  BluetoothDevice? _rfidDevice;
  void _handleDeviceConnected(BluetoothDevice device) {
  setState(() => _rfidDevice = device);
  }
  

  final List<String> _titles = ['Home', 'My Lists'];

  List<Widget> get _pages => [
        HomePage(
          lists: _createdLists,
          selectedList: _selectedFeaturedList,
          onFeaturedListChanged: _handleFeaturedListChanged,
        ),
        MyListsPage(
          lists: _createdLists,
          selectedList: _selectedFeaturedList,
          onCreatePressed: _openCreateListPage,
          onListSelected: _openListDetailPage,
          onFeaturedListChanged: _handleFeaturedListChanged,
        ),
      ];

  Future<void> _openCreateListPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListPage(
          onCreateList: _handleListCreated,
          rfidDevice: _rfidDevice,
        ),
      ),
    );
  }

  Future<void> _openListDetailPage(InventoryList list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailPage(
          list: list,
          onUpdateList: _handleListUpdated,
          rfidDevice: _rfidDevice,
        ),
      ),
    );
  }

  void _handleListCreated(InventoryList list) {
    setState(() {
      _createdLists.add(list);
      _selectedIndex = 1;
    });
  }

  void _handleListUpdated(InventoryList updatedList) {
    setState(() {
      final index = _createdLists.indexWhere((list) => list.id == updatedList.id);
      if (index != -1) {
        _createdLists[index] = updatedList;
      }

      if (_selectedFeaturedList != null && _selectedFeaturedList!.id == updatedList.id) {
        _selectedFeaturedList = updatedList;
      }
    });
  }

  void _handleFeaturedListChanged(InventoryList list) {
    setState(() {
      _selectedFeaturedList = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'RFID Organizer',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('My Organizer'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('My Lists'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Scan Devices'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanPage(onConnected: _handleDeviceConnected))
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

// Page: Home page.
// This page shows the welcome area and the currently selected list.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.lists,
    required this.selectedList,
    required this.onFeaturedListChanged,
  });

  final List<InventoryList> lists;
  final InventoryList? selectedList;
  final ValueChanged<InventoryList> onFeaturedListChanged;

  // Feature: choose a featured list from the saved options.
  void _showListPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a list',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (lists.isEmpty)
                  const Text('No saved lists yet.')
                else
                  ...lists.map((list) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(list.name),
                        onTap: () {
                          onFeaturedListChanged(list);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feature: welcome card shown at the top of the home page.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade600,
                    Colors.teal.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ready to organize?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan your items, or review your lists.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "User's Bag",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              "Present",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // add scanned items widget here
            const SizedBox(height: 16),
            const Text(
              "Missing",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            // add items that are not scanned widget here
            const SizedBox(height: 20),
            // Feature: selected list summary shown below the welcome area.
            const Text(
              'Selected List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (selectedList == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: const Text(
                  'No list selected.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedList!.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...selectedList!.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name),
                            Text(
                              'NFC ID: ${item.uid}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showListPicker(context),
                icon: const Icon(Icons.list_alt),
                label: const Text('Choose Another List'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget: small status card used for simple summary information.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

// Page: My Lists page.
// This page shows saved lists and gives the user quick access to open or create them.
class MyListsPage extends StatelessWidget {
  const MyListsPage({
    super.key,
    required this.lists,
    required this.selectedList,
    required this.onCreatePressed,
    required this.onListSelected,
    required this.onFeaturedListChanged,
  });

  final List<InventoryList> lists;
  final InventoryList? selectedList;
  final VoidCallback onCreatePressed;
  final ValueChanged<InventoryList> onListSelected;
  final ValueChanged<InventoryList> onFeaturedListChanged;

  // Feature: choose a featured list from the saved options.
  void _showListPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a list',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (lists.isEmpty)
                  const Text('No saved lists yet.')
                else
                  ...lists.map((list) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(list.name),
                        onTap: () {
                          onFeaturedListChanged(list);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feature: selected list preview at the top of the page.
            const Text(
              'Selected List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (selectedList == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: const Text(
                  'No list selected.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedList!.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...selectedList!.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name),
                            Text(
                              'NFC ID: ${item.uid}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showListPicker(context),
                icon: const Icon(Icons.list_alt),
                label: const Text('Choose Another List'),
              ),
            ),
            const SizedBox(height: 24),
            // Feature: saved lists gallery shown in a horizontal row.
            const Text(
              'Saved Lists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (lists.isEmpty) ...[
              const Expanded(
                child: Center(
                  child: Text(
                    'You have not created any lists yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: lists.map((list) {
                      return InkWell(
                        onTap: () => onListSelected(list),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 180,
                          height: 110,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              list.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Make Another List'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data model: one saved inventory list with a name and its items.
class InventoryList {
  InventoryList({required this.id, required this.name, required this.items});

  final String id;
  final String name;
  final List<InventoryItem> items;
}

// Data model: one item inside an inventory list.
class InventoryItem {
  const InventoryItem({required this.name, required this.uid});

  final String name;
  final String uid;
}

class ListItemCard extends StatelessWidget {
  const ListItemCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final InventoryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item: ${item.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'NFC ID: ${item.uid}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete item',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// Page: Create List page.
// This page lets the user create a new list and add scanned items to it.
class CreateListPage extends StatefulWidget {
  const CreateListPage({
    super.key,
    required this.onCreateList,
    required this.rfidDevice,
  });

  final ValueChanged<InventoryList> onCreateList;
  final BluetoothDevice? rfidDevice;

  @override
  State<CreateListPage> createState() => _CreateListPageState();
}
class _CreateListPageState extends State<CreateListPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final List<InventoryItem> _items = [];
  String? _statusMessage;
  String? _lastScannedUid;

  // Feature: update the status message shown to the user.
  void _handleStatusChanged(String message) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
    });
  }

  void _handleUidScanned(String uid) {
    if (!mounted) return;
    setState(() {
      _lastScannedUid = uid;
      _statusMessage = 'Tag scanned successfully';
    });
  }

  // Feature: add a new item to the list when the form is ready.
  void _addItemIfReady({bool allowWithoutUid = false}) {
    if (!mounted) return;

    final itemName = _itemController.text.trim();
    final uid = _lastScannedUid?.trim();

    if (itemName.isEmpty) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Please enter an item name before adding it.';
      });
      return;
    }

    if (!allowWithoutUid && (uid == null || uid.isEmpty)) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Please scan an NFC tag before adding the item.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _items.add(
        InventoryItem(
          name: itemName,
          uid: uid != null && uid.isNotEmpty ? uid : 'Not scanned',
        ),
      );
      _itemController.clear();
      _lastScannedUid = null;
      _statusMessage = 'Item added to the list.';
    });
  }

  void _addItemManually() {
    _addItemIfReady(allowWithoutUid: true);
  }

  // Feature: create the final list and send it back to the main screen.
  void _createList() {
    if (!mounted) return;

    final listName = _nameController.text.trim();
    if (listName.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a list name before creating it.';
      });
      return;
    }

    if (_itemController.text.trim().isNotEmpty && _items.isEmpty) {
      setState(() {
        _statusMessage = 'Please tap Add Item to add at least one item before creating the list.';
      });
      return;
    }

    if (_items.isEmpty) {
      setState(() {
        _statusMessage = 'Please add at least one item to create the list.';
      });
      return;
    }

    widget.onCreateList(
      InventoryList(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: listName,
        items: List<InventoryItem>.from(_items),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _deleteItem(int index) {
    if (!mounted) return;
    setState(() {
      _items.removeAt(index);
    });
  }

  // Feature: show simple help text about how to scan an NFC tag.
  Future<void> _showScanInfoDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Scan Your Tag'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Apple iPhones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'The NFC reader is located at the very top edge of the phone. Hold the top frame flat against the sticker and keep it steady until the scan completes.',
              ),
              SizedBox(height: 12),
              Text(
                'Android Phones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Placement varies, but it is typically in the dead center of the back glass or around the rear camera bump. Slowly slide the center back of the phone over the sticker until it registers.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New List'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feature: list name input field.
            const Text(
              'Name:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter a list name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 24),
            // Feature: preview of the items already added to the draft list.
            if (_items.isNotEmpty) ...[
              const Text(
                'Items:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListItemCard(
                    item: item,
                    onDelete: () => _deleteItem(index),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            NfcScanCard(
              itemController: _itemController,
              statusMessage: _statusMessage,
              onStatusChanged: _handleStatusChanged,
              onUidScanned: _handleUidScanned,
              onAddItem: _addItemManually,
              onInfoPressed: _showScanInfoDialog,
              rfidDevice: widget.rfidDevice,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createList,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Create List'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemController.dispose();
    super.dispose();
  }
}

// Page: List Detail page.
// This page shows the full contents of one list and lets the user edit it.
class ListDetailPage extends StatefulWidget {
  const ListDetailPage({
    super.key,
    required this.list,
    required this.onUpdateList,
    required this.rfidDevice,
  });

  final InventoryList list;
  final ValueChanged<InventoryList> onUpdateList;
  final BluetoothDevice? rfidDevice;

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  late final TextEditingController _listNameController;
  late List<InventoryItem> _items;
  late List<TextEditingController> _itemNameControllers;
  final TextEditingController _newItemController = TextEditingController();
  bool _isEditing = false;
  String? _statusMessage;
  String? _lastScannedUid;

  @override
  void initState() {
    super.initState();
    _listNameController = TextEditingController(text: widget.list.name);
    _items = List<InventoryItem>.from(widget.list.items);
    _itemNameControllers = widget.list.items
        .map((item) => TextEditingController(text: item.name))
        .toList();
  }

  // Feature: switch between view mode and edit mode.
  void _toggleEditMode() {
    if (_isEditing) {
      _persistCurrentState();
      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isEditing = true;
    });
  }

  void _handleUidScanned(String uid) {
    if (!mounted) return;
    setState(() {
      _lastScannedUid = uid;
      _statusMessage = 'Tag scanned successfully';
    });
  }

  void _handleStatusChanged(String message) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
    });
  }

  // Feature: save the current item names and list name back to the app state.
  void _persistCurrentState() {
    final updatedItems = List.generate(_items.length, (index) {
      final currentName = _itemNameControllers[index].text.trim();
      return InventoryItem(
        name: currentName.isEmpty ? 'Untitled item' : currentName,
        uid: _items[index].uid,
      );
    });

    final updatedList = InventoryList(
      id: widget.list.id,
      name: _listNameController.text.trim().isEmpty
          ? widget.list.name
          : _listNameController.text.trim(),
      items: updatedItems,
    );

    setState(() {
      _items = updatedItems;
    });
    widget.onUpdateList(updatedList);
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      _itemNameControllers.removeAt(index);
      _statusMessage = 'Item removed.';
    });
    _persistCurrentState();
  }

  // Feature: add a new item to the existing list while editing.
  void _addItem() {
    final itemName = _newItemController.text.trim();
    final uid = _lastScannedUid?.trim();

    if (itemName.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter an item name.';
      });
      return;
    }

    setState(() {
      _items.add(InventoryItem(name: itemName, uid: uid ?? 'Not scanned'));
      _itemNameControllers.add(TextEditingController(text: itemName));
      _newItemController.clear();
      _lastScannedUid = null;
      _statusMessage = 'Item added.';
    });
    _persistCurrentState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit List' : _listNameController.text.trim().isEmpty ? 'List' : _listNameController.text.trim()),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            tooltip: _isEditing ? 'Save changes' : 'Edit list',
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feature: list name display or edit field.
              if (_isEditing)
                TextField(
                  controller: _listNameController,
                  decoration: InputDecoration(
                    labelText: 'List name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit),
                  ),
                )
              else
                Text(
                  _listNameController.text.trim().isEmpty
                      ? widget.list.name
                      : _listNameController.text.trim(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              // Feature: list of items shown in the detail view.
              const Text(
                'Items:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                const Text('No items yet.')
              else
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: _isEditing
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _itemNameControllers[index],
                                        decoration: InputDecoration(
                                          hintText: 'Item name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'NFC ID: ${item.uid}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteItem(index),
                                  tooltip: 'Delete item',
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'NFC ID: ${item.uid}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                // Feature: NFC scan section used while editing the list.
                NfcScanCard(
                  itemController: _newItemController,
                  statusMessage: _statusMessage,
                  onStatusChanged: _handleStatusChanged,
                  onUidScanned: _handleUidScanned,
                  onAddItem: _addItem,
                  onInfoPressed: () async {},
                  rfidDevice: widget.rfidDevice,
                ),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _statusMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _listNameController.dispose();
    for (final controller in _itemNameControllers) {
      controller.dispose();
    }
    _newItemController.dispose();
    super.dispose();
  }
}

// Feature: NFC scan card.
// This widget contains the scan input, item name field, and add button for NFC-based items.
class NfcScanCard extends StatefulWidget {
  const NfcScanCard({
    super.key,
    required this.itemController,
    required this.statusMessage,
    required this.onStatusChanged,
    required this.onUidScanned,
    required this.onAddItem,
    required this.onInfoPressed,
    required this.rfidDevice,
  });

  final TextEditingController itemController;
  final String? statusMessage;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onUidScanned;
  final VoidCallback onAddItem;
  final Future<void> Function() onInfoPressed;
  final BluetoothDevice? rfidDevice;

  @override
  State<NfcScanCard> createState() => _NfcScanCardState();
}

class _NfcScanCardState extends State<NfcScanCard> {
  bool _isScanning = false;
  // True once the mc reports WAITING_NAME for the currently scanned tag.
  // Only while this is true is it safe to write nameCharacteristic --
  // the mc's WAITING branch is the only place it reads from it.
  bool _isWaitingForName = false;

  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _uidChar;
  BluetoothCharacteristic? _nameChar;

  StreamSubscription<List<int>>? _statusSub;
  StreamSubscription<List<int>>? _uidSub;

  BluetoothDevice? _discoveredFor;

  Future<void> _ensureCharacteristicsDiscovered() async {
    // Re-discover only if we haven't done it yet for this device, or the
    // device instance changed (e.g. reconnect from the Scan page).
    if (_discoveredFor == widget.rfidDevice && _controlChar != null) {
      return;
    }

    final services = await widget.rfidDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() != serviceUuid) continue;
      for (var c in service.characteristics) {
        final uuid = c.uuid.toString();
        if (uuid == controlCharUuid) _controlChar = c;
        if (uuid == statusCharUuid) _statusChar = c;
        if (uuid == uidCharUuid) _uidChar = c;
        if (uuid == nameCharUuid) _nameChar = c;
      }
    }
    _discoveredFor = widget.rfidDevice;

    // Cancel any previous listeners before re-subscribing, otherwise every
    // scan attempt stacks another listener on top of the last one.
    await _statusSub?.cancel();
    await _uidSub?.cancel();

    if (_statusChar != null) {
      await _statusChar!.setNotifyValue(true);
      _statusSub = _statusChar!.lastValueStream.listen((value) {
        final status = String.fromCharCodes(value);
        widget.onStatusChanged(status);
        setState(() {
          _isWaitingForName = status == 'WAITING_NAME';
          if (status == 'WAITING_NAME') _isScanning = false;
        });
      });
    }

    if (_uidChar != null) {
      await _uidChar!.setNotifyValue(true);
      _uidSub = _uidChar!.lastValueStream.listen((value) {
        final uid = String.fromCharCodes(value);
        widget.onUidScanned(uid);
      });
    }
  }

 Future<void> _startNfcScan() async {
  if (widget.rfidDevice == null) {
    widget.onStatusChanged('Not connected to RFID reader.');
    return;
  }

  setState(() => _isScanning = true);

  try {
    final services = await widget.rfidDevice!.discoverServices();
    BluetoothCharacteristic? controlChar;
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var c in service.characteristics) {
          if (c.uuid.toString() == controlCharUuid) controlChar = c;
        }
      }
    }

    if (controlChar == null) {
      widget.onStatusChanged('Control characteristic not found.');
      setState(() => _isScanning = false);
      return;
    }

    await controlChar.write([1], withoutResponse: false);
    print('write completed');

    BluetoothCharacteristic? statusChar;
    BluetoothCharacteristic? uidChar;
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var c in service.characteristics) {
          if (c.uuid.toString() == statusCharUuid) statusChar = c;
          if (c.uuid.toString() == uidCharUuid) uidChar = c;
          if (c.uuid.toString() == nameCharUuid) _nameChar = c;
        }
      }
    }

    if (statusChar != null) {
      await statusChar.setNotifyValue(true);
      statusChar.lastValueStream.listen((value) {
        final status = String.fromCharCodes(value);
        widget.onStatusChanged(status);
        setState(() {
          _isWaitingForName = status == 'WAITING_NAME';
          if (status == 'WAITING_NAME') _isScanning = false;
        });
      });
    }

    if (uidChar != null) {
      await uidChar.setNotifyValue(true);
      uidChar.lastValueStream.listen((value) {
        widget.onUidScanned(String.fromCharCodes(value));
      });
    }
  } catch (e) {
    print('write failed: $e');
    widget.onStatusChanged('Write failed: $e');
    setState(() => _isScanning = false);
  }
}
  // Called from the "Add Item" button. If the mc is currently sitting in
  // WAITING_NAME for a freshly scanned tag, write the name back so the mc
  // can save it (Tag gets created/renamed there, not just in the app).
  // Otherwise this is a manual add with no tag involved, so just hand off
  // to the parent as before.
  Future<void> _handleAddItem() async {
    final name = widget.itemController.text.trim();

    if (_isWaitingForName && _nameChar != null && name.isNotEmpty) {
      final bytes = utf8.encode(name);
      if (bytes.length > maxTagNameBytes) {
        widget.onStatusChanged(
          'Name too long (max $maxTagNameBytes bytes). Please shorten it.',
        );
        return;
      }
      await _nameChar!.write(bytes);
      setState(() => _isWaitingForName = false);
    }

    widget.onAddItem();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _uidSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.nfc,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Scan an NFC Sticker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the button below to scan the ID of one NFC sticker. Click the "i" icon for assistance.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Item:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: widget.itemController,
                  decoration: InputDecoration(
                    hintText: 'Enter the item name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _startNfcScan,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.radar_outlined),
                    label: Text(_isScanning ? 'Scanning...' : 'Start NFC Scan'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleAddItem,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Item'),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.statusMessage != null)
                  Text(
                    widget.statusMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () async {
                await widget.onInfoPressed();
              },
              tooltip: 'How to Scan Your Tag',
            ),
          ),
        ],
      ),
    );
  }
}