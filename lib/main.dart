import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_list_manager/item_add.dart';
import 'package:shopping_list_manager/item_edit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopping List Manager',
      home: const ShoppingListManager(),
    );
  }
}

class ShoppingListManager extends StatefulWidget {
  const ShoppingListManager({super.key});

  @override
  State<ShoppingListManager> createState() => _ShoppingListManagerState();
}

class _ShoppingListManagerState extends State<ShoppingListManager> {
  final MenuController _menuController = MenuController();
  // LIST MAP TO BE PASSED FROM ITEM_ADD
  final List<Map<String, dynamic>> _inventory = [];
  int _itemId = 0;

  // LOAD THE SAVED ITEMS
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // FUNCTION TO LOAD THE ITEMS
  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('inventory_items');

    if (itemsJson != null) {
      final List<dynamic> decodedItems = jsonDecode(itemsJson);

      setState(() {
        _inventory.clear();
        _itemId = 0;
        
        for (var item in decodedItems) {
          final itemMap = Map<String, dynamic>.from(item);
          _inventory.add(itemMap);
          
          if (itemMap.containsKey('id') && itemMap['id'] is int && itemMap['id'] > _itemId) {
            _itemId = itemMap['id'];
          }
        }
      });
    }
  }

  // FUNCTION TO SAVE THE ITEMS
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(_inventory);
    
    await prefs.setString('inventory_items', itemsJson);
  }
  // ADD ITEM WHEN PRESSED DONE IN ITEM_ADD
  void _addItem(Map<String, dynamic> item) {
    setState(() {
      _itemId++;
      item['id'] = _itemId;
      
      _inventory.add(item);
      _saveItems();
    });

    customSnackBar('Item added successfully!');
  }

  // FUNCTION TO EDIT THE ITEMS
  void _editItem(Map<String, dynamic> updatedItem) {
    final index = updatedItem['index'];
    final existingId = _inventory[index]['id'];

    setState(() {
      _inventory[index] = {
        'id': existingId,
        'name': updatedItem['name'],
        'quantity': updatedItem['quantity'],
        'price': updatedItem['price'],
      };
      _saveItems();
    });

    customSnackBar('Item updated successfully!');
  }

  // FUNCTION TO DELETE THE ITEMS
  void _deleteItem(int index) {
    setState(() {
      _inventory.removeAt(index);
      _saveItems();
    });

    customSnackBar('Item deleted successfully!');
  }

  // CUSTOM SNACK BAR
  void customSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        width: 300,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)
        ),
        duration: Duration(seconds: 2),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _inventory.isNotEmpty ? Colors.grey[100] : Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Shopping List Manager'),
        actions: [
          // SHOW THE MENU ANCHOR IF THERE ARE ITEMS
          if (_inventory.isNotEmpty) MenuAnchor(
            controller: _menuController,
            style: MenuStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
            ),
            builder: (context, controller, child) {
              return IconButton(
                onPressed: (){
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                }, 
                icon: Icon(Icons.more_vert),
              );
            },
            // CLEAR ALL BUTTON
            menuChildren: [
              MenuItemButton(
                onPressed: () {
                  setState(() {
                    _inventory.clear();
                    _saveItems();
                  });

                  customSnackBar('All items cleared!');
                },
                child: Row(
                  children: [
                    Icon(Icons.delete_outlined),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              )
            ],
          )
        ],
      ),
      // IF THERE ARE NO ITEMS, SHOW ADD ITEM BUTTON : SHOW ITEMS FROM LIST
      body: _inventory.isEmpty ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text('There are no items in the inventory'),
          ),
          SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              // OPEN ITEM_ADD
              final update = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ItemAdd())
              );
              // THE USER ADDED AN ITEM
              if (update != null) {
                _addItem(update);
              }
            },
            icon: Icon(Icons.add),
            label: Text('Add items',
              style: TextStyle(color: Colors.black,
              ),
            ),
          ),
        ],
      ) : 
      // CARD BUTTON OF EACH ITEM
      ListView.builder(
        itemCount: _inventory.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = _inventory[index];
          return Card.filled(
            clipBehavior: Clip.hardEdge,
            color: Colors.white,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              splashColor: Colors.grey.withAlpha(20),
              onTap: () async {
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => ItemEdit(
                      name: item['name'],
                      quantity: item['quantity'],
                      price: item['price'],
                      index: index,
                      id: item['id'],
                    ),
                  ),
                );
                if (result != null) {
                  if (result['delete'] == true) {
                    _deleteItem(result['index']);
                  }
                  else {
                    _editItem(result);
                  }
                }
              },
              child: Dismissible(
                key: Key(item['name']),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                onDismissed: (direction) {
                  setState(() {
                    _inventory.removeAt(index);
                    _saveItems();
                  });
                  customSnackBar('Item removed!');
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product ID: ${item['id']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Quantity: ${item['quantity']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₱${item['price']}',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      // FAB OF ADD ITEM
      floatingActionButton: _inventory.isNotEmpty ? FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () async {
          // OPEN ITEM_ADD
          final update = await Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => ItemAdd())
          );
          // THE USER ADDED AN ITEM
          if (update != null) {
            _addItem(update);
          }
        },
        icon: Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: Text(
          'Add item', 
          style: TextStyle(
            color: Colors.white
            )
          ),
      ) :
      // DON'T SHOW THE FAB 
      null,
    );
  }
}
