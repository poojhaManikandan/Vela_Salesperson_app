import 'package:flutter/material.dart';
import '../data/bill_store.dart';
import '../data/cart_store.dart';
import '../data/dummy_data.dart';
import '../models/bill.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/app_search_field.dart';
import '../widgets/misc_widgets.dart';
import '../widgets/product_card.dart';
import '../widgets/primary_button.dart';
import 'bill_history_screen.dart';
import 'cart_screen.dart';
import 'product_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  String _selectedCategory = 'All';
  String _query = '';
  bool _isListView = false;

  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _shopNameController;
  late TextEditingController _discountController;

  final List<String> _employees = [
    'Ramalingam',
    'Divya',
    'Rahul',
    'Kavitha',
  ];

  final List<String> _paymentModes = ['Cash', 'UPI / QR', 'Card', 'Credit'];

  @override
  void initState() {
    super.initState();
    BillStore.load();
    // Pre-populate recent products if empty
    if (CartStore.recentProducts.isEmpty) {
      for (int i = 0; i < 4 && i < DummyData.products.length; i++) {
        CartStore.recentProducts.add(DummyData.products[i]);
      }
    }

    _customerNameController = TextEditingController(text: CartStore.customerName);
    _customerPhoneController = TextEditingController(text: CartStore.customerPhone);
    _shopNameController = TextEditingController(text: CartStore.shopName);
    _discountController = TextEditingController(
      text: CartStore.discount > 0 ? CartStore.discount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _shopNameController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _customerNameController.text = CartStore.customerName;
    _customerPhoneController.text = CartStore.customerPhone;
    _shopNameController.text = CartStore.shopName;
    _discountController.text = CartStore.discount > 0 ? CartStore.discount.toStringAsFixed(0) : '';
  }

  List<String> get _categories => [
        'All',
        '❤️ Wishlist',
        ...DummyData.categories.where((c) => c != 'All'),
      ];

  List<Product> get _filteredProducts {
    return DummyData.products.where((p) {
      final matchesCategory = _selectedCategory == 'All'
          ? true
          : (_selectedCategory == '❤️ Wishlist'
              ? CartStore.isWishlisted(p.id)
              : p.category == _selectedCategory);
      final matchesQuery =
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.category.toLowerCase().contains(_query.toLowerCase()) ||
          p.id.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  int _countForCategory(String cat) {
    if (cat == 'All') return DummyData.products.length;
    if (cat == '❤️ Wishlist') return CartStore.wishlistCount;
    return DummyData.products.where((p) => p.category == cat).length;
  }

  void _showWishlistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final wishlistedProducts = DummyData.products
              .where((p) => CartStore.isWishlisted(p.id))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: AppTheme.dangerRed, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'My Wishlist (${wishlistedProducts.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      if (wishlistedProducts.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              CartStore.wishlistProductIds.clear();
                            });
                            setModalState(() {});
                          },
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppTheme.dangerRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                if (wishlistedProducts.isEmpty)
                  const Expanded(
                    child: EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'Your Wishlist is Empty',
                      subtitle:
                          'Tap the heart icon on any product card to save your favorite items here for quick billing.',
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: wishlistedProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = wishlistedProducts[index];
                        final outOfStock = product.stock == 0;
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: AppTheme.backgroundLight,
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 20,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            subtitle: Text(
                              '₹${product.price.toStringAsFixed(2)} / ${product.unit}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite_rounded,
                                      color: AppTheme.dangerRed, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      CartStore.toggleWishlist(product.id);
                                    });
                                    setModalState(() {});
                                  },
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: outOfStock
                                      ? null
                                      : () {
                                          setState(() {
                                            CartStore.add(product);
                                          });
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Added ${product.name} to bill'),
                                              duration:
                                                  const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 850;

    final pages = [
      _buildHomeBody(isWide),
      const BillHistoryScreen(embedded: true),
      const SettingsScreen(embedded: true),
    ];

    return Scaffold(
      appBar: _navIndex == 0 ? _buildAppBar(context) : null,
      body: SafeArea(child: pages[_navIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() {
            _navIndex = i;
          });
          if (i == 0) {
            _syncControllers();
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Shop POS'),
          NavigationDestination(
              icon: Icon(Icons.receipt_outlined),
              selectedIcon: Icon(Icons.receipt_rounded),
              label: 'Bill History'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vela Agency',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(CartStore.shopName,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        // Employee Selector Menu
        PopupMenuButton<String>(
          initialValue: CartStore.activeEmployee,
          onSelected: (val) {
            setState(() {
              CartStore.activeEmployee = val;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Switched employee to $val')),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
          ),
          itemBuilder: (context) => _employees
              .map((e) => PopupMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Icon(
                          e == CartStore.activeEmployee
                              ? Icons.check_circle_rounded
                              : Icons.person_outline,
                          size: 18,
                          color: e == CartStore.activeEmployee
                              ? AppTheme.primaryBlue
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Text(e,
                            style: TextStyle(
                              fontWeight: e == CartStore.activeEmployee
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            )),
                      ],
                    ),
                  ))
              .toList(),
        ),

        // Wishlist Quick Access Button (Top right, near show menu toggle)
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                CartStore.wishlistCount > 0
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: CartStore.wishlistCount > 0 ? AppTheme.dangerRed : AppTheme.textDark,
              ),
              tooltip: 'Wishlist (${CartStore.wishlistCount})',
              onPressed: () => _showWishlistSheet(context),
            ),
            if (CartStore.wishlistCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.dangerRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${CartStore.wishlistCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Compact/Grid View Toggle ("Show menu")
        IconButton(
          icon: Icon(_isListView ? Icons.grid_view_rounded : Icons.view_list_rounded),
          tooltip: _isListView ? 'Show Grid View' : 'Show Compact List View',
          onPressed: () {
            setState(() {
              _isListView = !_isListView;
            });
          },
        ),

        // Cart Icon with Badge (only shown on narrow screens)
        if (MediaQuery.of(context).size.width <= 850)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                    setState(() {
                      _syncControllers();
                    });
                  },
                ),
                if (CartStore.items.isNotEmpty)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppTheme.dangerRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${CartStore.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHomeBody(bool isWide) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Pane: Catalog
          Expanded(
            flex: 3,
            child: _buildCatalogSection(isWide),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Right Pane: Active Bill / Checkout
          SizedBox(
            width: 380,
            child: _buildEmbeddedCartPanel(),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _buildCatalogSection(isWide),
        // Floating Cart Action Bar when cart is not empty and screen is narrow
        if (CartStore.items.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${CartStore.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${CartStore.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${CartStore.items.length} items added',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                      setState(() {
                        _syncControllers();
                      });
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Checkout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCatalogSection(bool isWide) {
    final products = _filteredProducts;
    final paddingBottom = !isWide && CartStore.items.isNotEmpty ? 90.0 : 24.0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Catalog',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Search & add products to generate bill',
                          style: TextStyle(
                              fontSize: 12.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppSearchField(
                  hintText: 'Search products by name, code or category...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
        ),

        // ⚡ Recent Products Section
        if (CartStore.recentProducts.isNotEmpty && _query.isEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 18, color: Color(0xFFF57C00)),
                  SizedBox(width: 6),
                  Text(
                    'Recent & Frequent Products',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: CartStore.recentProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final product = CartStore.recentProducts[index];
                  final qty = CartStore.quantityFor(product);
                  return ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.12),
                      child: Text(
                        product.name.isNotEmpty ? product.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    label: Text(
                      '${product.name} (₹${product.price.toStringAsFixed(0)})${qty > 0 ? " • x$qty" : ""}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: qty > 0 ? FontWeight.w800 : FontWeight.w600,
                        color: qty > 0 ? AppTheme.primaryBlue : AppTheme.textDark,
                      ),
                    ),
                    backgroundColor: qty > 0
                        ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: qty > 0
                            ? AppTheme.primaryBlue
                            : Colors.grey.shade300,
                      ),
                    ),
                    onPressed: () {
                      if (product.stock == 0) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} is out of stock!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        CartStore.add(product);
                      });
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${product.name} to bill'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],

        // Category Split Bar
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _selectedCategory;
                final count = _countForCategory(category);
                return ChoiceChip(
                  label: Text('$category ($count)'),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                );
              },
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} items available',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted),
                ),
                if (_selectedCategory != 'All' || _query.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = 'All';
                      _query = '';
                    }),
                    child: const Text(
                      'Reset Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No products found',
              subtitle: 'Try searching with a different term or category.',
            ),
          )
        else if (_isListView)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, paddingBottom),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    isCompactList: true,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductScreen(product: product),
                        ),
                      );
                      setState(() {});
                    },
                    onAddToCart: () {
                      final added = CartStore.add(product);
                      setState(() {});
                      if (!added) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Cannot add more ${product.name}. Stock limit (${product.stock}) reached!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    onToggleWishlist: () {
                      setState(() {
                        CartStore.toggleWishlist(product.id);
                      });
                    },
                  );
                },
                childCount: products.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, paddingBottom),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.crossAxisExtent > 700 ? 4 : 2;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isCompactList: false,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductScreen(product: product),
                            ),
                          );
                          setState(() {});
                        },
                        onAddToCart: () {
                          final added = CartStore.add(product);
                          setState(() {});
                          if (!added) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Cannot add more ${product.name}. Stock limit (${product.stock}) reached!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        onToggleWishlist: () {
                          setState(() {
                            CartStore.toggleWishlist(product.id);
                          });
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmbeddedCartPanel() {
    final items = CartStore.items;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Bill Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                if (items.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        CartStore.clear();
                      });
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: AppTheme.dangerRed, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          if (items.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Cart is empty',
                subtitle: 'Tap products on the left to add.',
              ),
            )
          else ...[
            // Cart Items Scrollable List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Customer Details Form
                  ExpansionTile(
                    title: const Text(
                      'Customer & Shop Info',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
                    ),
                    leading: const Icon(Icons.person_pin_rounded, color: AppTheme.primaryBlue, size: 20),
                    dense: true,
                    initiallyExpanded: CartStore.customerPhone.isEmpty,
                    childrenPadding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      TextField(
                        controller: _customerNameController,
                        onChanged: (val) {
                          CartStore.customerName = val.trim().isEmpty ? 'Walk-in Customer' : val;
                        },
                        decoration: InputDecoration(
                          labelText: 'Customer Name',
                          hintText: 'Walk-in Customer',
                          prefixIcon: const Icon(Icons.person_outline, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (val) {
                          CartStore.customerPhone = val;
                        },
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '9876543210',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _shopNameController,
                        onChanged: (val) {
                          CartStore.shopName = val;
                        },
                        decoration: InputDecoration(
                          labelText: 'Store Branch',
                          prefixIcon: const Icon(Icons.store_outlined, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 4),

                  // Payment Mode Chips
                  const Text(
                    'Payment Mode',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: _paymentModes.map((mode) {
                      final selected = CartStore.paymentMode == mode;
                      return ChoiceChip(
                        label: Text(mode, style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppTheme.primaryBlue,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            CartStore.paymentMode = mode;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  const SizedBox(height: 6),

                  // Items List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items Added (${items.length})',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${CartStore.itemCount} units',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      CartStore.decrement(item.product);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: AppTheme.primaryBlue),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    final added = CartStore.add(item.product);
                                    setState(() {});
                                    if (!added) {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Max stock limit (${item.product.stock}) reached for ${item.product.name}!'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: AppTheme.primaryBlue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Discount Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0.0;
                            setState(() {
                              CartStore.discount = parsed;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Discount (₹)',
                            prefixText: '₹ ',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Wrap(
                        spacing: 2,
                        children: [10, 20, 50].map((amt) {
                          return ActionChip(
                            label: Text('₹$amt', style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onPressed: () {
                              setState(() {
                                CartStore.discount = amt.toDouble();
                                _discountController.text = amt.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cart Checkout Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                      Text('₹${CartStore.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST Tax (5%):', style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                      Text('₹${CartStore.tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (CartStore.discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(fontSize: 12.5, color: AppTheme.successGreen)),
                        Text('-₹${CartStore.discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.successGreen)),
                      ],
                    ),
                  ],
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      Text('₹${CartStore.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Generate Bill',
                    icon: Icons.receipt_long_rounded,
                    onPressed: () async {
                      final newBill = Bill(
                        billNumber: BillStore.nextBillNumber(),
                        date: DateTime.now(),
                        employeeName: CartStore.activeEmployee,
                        customerName: CartStore.customerName,
                        customerPhone: CartStore.customerPhone,
                        shopName: CartStore.shopName,
                        paymentMode: CartStore.paymentMode,
                        items: List.from(CartStore.items),
                        subtotal: CartStore.subtotal,
                        tax: CartStore.tax,
                        discount: CartStore.discount,
                        total: CartStore.total,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      await BillStore.save(newBill);
                      CartStore.clear();
                      if (mounted) {
                        setState(() {
                          _syncControllers();
                        });
                      }
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                          content: Row(
                            children: [
                              const Icon(Icons.folder_zip_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bill ${newBill.billNumber} generated & stored in backend folder! (₹${newBill.total.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
