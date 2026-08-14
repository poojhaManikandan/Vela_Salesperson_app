import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/bill_store.dart';
import '../data/cart_store.dart';
import '../models/bill.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_search_field.dart';
import '../widgets/bill_receipt_sheet.dart';
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

  List<Product> _products = [];
  List<Map<String, String>> _customerRows = [];
  bool _isLoadingProducts = false;
  bool _isLoadingMore = false;
  String? _loadError;
  int _visibleProductCount = 100;

  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _shopNameController;
  late TextEditingController _amountPaidController;

  final List<String> _paymentModes = ['Cash', 'UPI / QR', 'Card', 'Credit'];

  @override
  void initState() {
    super.initState();
    BillStore.load();
    _loadProducts();
    _loadCustomers();

    _customerNameController =
        TextEditingController(text: CartStore.customerName);
    _customerPhoneController =
        TextEditingController(text: CartStore.customerPhone);
    _shopNameController = TextEditingController(text: CartStore.shopName);
    _amountPaidController = TextEditingController(
      text: CartStore.amountPaid > 0
          ? (CartStore.amountPaid == CartStore.amountPaid.toInt()
              ? CartStore.amountPaid.toInt().toString()
              : CartStore.amountPaid.toString())
          : '',
    );
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _loadError = null;
    });
    try {
      final fetched = await ApiService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = fetched;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _products = [];
        _isLoadingProducts = false;
        _loadError = 'Could not connect to server.';
      });
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await ApiService.fetchCustomers();
      if (!mounted) return;
      setState(() {
        _customerRows = customers;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _customerRows = [];
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _shopNameController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _customerNameController.text = CartStore.customerName;
    _customerPhoneController.text = CartStore.customerPhone;
    _shopNameController.text = CartStore.shopName;
    _amountPaidController.text = CartStore.amountPaid > 0 
        ? (CartStore.amountPaid == CartStore.amountPaid.toInt() 
            ? CartStore.amountPaid.toInt().toString() 
            : CartStore.amountPaid.toString()) 
        : '';
  }

  List<String> get _categories {
    final cats =
        _products.map((p) => p.category).where((c) => c.isNotEmpty).toSet();
    return ['All', ...cats];
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' ? true : p.category == _selectedCategory;
      final matchesQuery =
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
              p.category.toLowerCase().contains(_query.toLowerCase()) ||
              p.id.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || _visibleProductCount >= _filteredProducts.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _visibleProductCount =
          (_visibleProductCount + 100).clamp(0, _filteredProducts.length);
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    });
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.extentAfter <= 300 &&
        !notification.metrics.outOfRange &&
        _visibleProductCount < _filteredProducts.length) {
      _loadMoreProducts();
    }
  }

  int _countForCategory(String cat) {
    if (cat == 'All') return _products.length;
    return _products.where((p) => p.category == cat).length;
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
      appBar: _buildAppBar(context),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vela Agency'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      CartStore.shopName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _drawerTile(
              index: 0,
              label: 'Shop POS',
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag_rounded,
            ),
            _drawerTile(
              index: 1,
              label: 'Bill History',
              icon: Icons.receipt_outlined,
              selectedIcon: Icons.receipt_rounded,
            ),
            _drawerTile(
              index: 2,
              label: 'Settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    'Cashier: ${CartStore.activeEmployee}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'V1.0.0 (Green Theme)',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(child: pages[_navIndex]),
    );
  }

  Widget _drawerTile({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = _navIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
        selectedColor: AppTheme.primaryGreen,
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppTheme.primaryGreen : context.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          setState(() {
            _navIndex = index;
          });
          if (index == 0) {
            _syncControllers();
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_navIndex == 1) {
      return AppBar(
        title: const Text(
          'Bill History & Analytics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      );
    }
    if (_navIndex == 2) {
      return AppBar(
        title: const Text(
          'System Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      );
    }

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.surfaceColor,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vela Agency'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(CartStore.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Compact/Grid View Toggle ("Show menu")
        IconButton(
          icon: Icon(
              _isListView ? Icons.grid_view_rounded : Icons.view_list_rounded),
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
                      color: AppTheme.primaryGreen,
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
                      backgroundColor: AppTheme.primaryGreen,
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
                    label: Text(
                      'Checkout'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
    final filteredProducts = _filteredProducts;
    final products = filteredProducts.take(_visibleProductCount).toList();
    final paddingBottom = !isWide && CartStore.items.isNotEmpty ? 90.0 : 24.0;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(notification);
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product Catalog'.tr,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Search & add products to generate bill'.tr,
                              style: TextStyle(
                                  fontSize: 12.5, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppSearchField(
                    hintText: 'Search items...'.tr,
                    onChanged: (v) => setState(() {
                      _query = v;
                      _visibleProductCount = 100;
                    }),
                  ),
                ],
              ),
            ),
          ),

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
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : context.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) => setState(() {
                      _selectedCategory = category;
                      _visibleProductCount = 100;
                    }),
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
                    _isLoadingProducts && _products.isEmpty
                        ? 'Loading products...'.tr
                        : '${products.length} items available'.tr,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary),
                  ),
                  if (_selectedCategory != 'All' || _query.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = 'All';
                        _query = '';
                        _visibleProductCount = 100;
                      }),
                      child: Text(
                        'Reset Filters'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_loadError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 18, color: AppTheme.accentOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loadError ?? 'Could not connect to server.'.tr,
                          style: TextStyle(
                              fontSize: 12, color: context.textPrimary),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadProducts,
                        child: Text(
                          'Retry'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isLoadingProducts && _products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          else if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No products found'.tr,
                subtitle: 'Try searching with a different term or category.'.tr,
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
                                  'Cannot add more ${product.name}. Stock limit (${product.stock}) reached!'.tr),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
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
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Cannot add more ${product.name}. Stock limit (${product.stock}) reached!'.tr),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        );
                      },
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),

          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedCartPanel() {
    final items = CartStore.items;

    // Use a Material (not a ColoredBox) so ListTile/ExpansionTile ink
    // splashes paint on this surface instead of being hidden behind it.
    return Material(
      color: context.surfaceColor,
      child: Column(
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Active Bill Checkout'.tr,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        CartStore.clear();
                      });
                    },
                    child: Text(
                      'Clear'.tr,
                      style: const TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (items.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Cart is empty'.tr,
                subtitle: 'Tap products on the left to add.'.tr,
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
                    title: Text(
                      'Customer & Shop Info'.tr,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen),
                    ),
                    leading: const Icon(Icons.person_pin_rounded,
                        color: AppTheme.primaryGreen, size: 20),
                    dense: true,
                    initiallyExpanded: CartStore.customerPhone.isEmpty,
                    childrenPadding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue value) {
                          final query = value.text.trim();
                          final suggestions = _customerRows
                              .map((customer) => customer['name'] ?? '')
                              .where((name) => name.isNotEmpty)
                              .toSet()
                              .toList();

                          if (query.isEmpty) {
                            return suggestions;
                          }

                          return suggestions.where((name) =>
                              name.toLowerCase().contains(query.toLowerCase()));
                        },
                        displayStringForOption: (option) => option,
                        onSelected: (selection) {
                          final matched = _customerRows.firstWhere(
                            (customer) => (customer['name'] ?? '') == selection,
                            orElse: () => {'name': selection, 'phone': ''},
                          );
                          setState(() {
                            CartStore.customerName = selection;
                            CartStore.customerPhone = matched['phone'] ?? '';
                            _customerNameController.text = selection;
                            _customerPhoneController.text =
                                CartStore.customerPhone;
                          });
                        },
                        fieldViewBuilder: (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          textEditingController.text =
                              CartStore.customerName == 'Walk-in Customer'
                                  ? ''
                                  : CartStore.customerName;
                          textEditingController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: textEditingController.text.length),
                          );

                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            onChanged: (val) {
                              CartStore.customerName =
                                  val.trim().isEmpty ? 'Walk-in Customer' : val;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Customer Name / Business'.tr,
                              hintText: 'e.g. Walk-in Customer or Ramesh'.tr,
                              prefixIcon:
                                  const Icon(Icons.person_outline, size: 18),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) {
                          CartStore.customerPhone = val;
                        },
                        decoration: InputDecoration(
                          labelText: 'Mobile Number'.tr,
                          hintText: '9876543210'.tr,
                          prefixIcon:
                              const Icon(Icons.phone_outlined, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _shopNameController,
                        onChanged: (val) {
                          CartStore.shopName = val;
                        },
                        decoration: InputDecoration(
                          labelText: 'Store Branch'.tr,
                          prefixIcon:
                              const Icon(Icons.store_outlined, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 4),

                  // Payment Mode Chips
                  Text(
                    'Payment Mode'.tr,
                    style:
                        const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
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
                        selectedColor: AppTheme.primaryGreen,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : context.textPrimary,
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
                        'Items Added (${items.length})'.tr,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${CartStore.itemCount} units'.tr,
                        style: TextStyle(
                            fontSize: 11, color: context.textSecondary),
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
                          color: context.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.borderColor),
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.textSecondary),
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
                                      color: context.surfaceColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.remove,
                                        size: 14, color: AppTheme.primaryGreen),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    final added = CartStore.add(item.product);
                                    setState(() {});
                                    if (!added) {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Max stock limit (${item.product.stock}) reached for ${item.product.name}!'.tr),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: context.surfaceColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.add,
                                        size: 14, color: AppTheme.primaryGreen),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Amount Paid Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountPaidController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            var parsed = double.tryParse(val) ?? 0.0;
                            var maxAllowed = double.parse(CartStore.total.toStringAsFixed(2));
                            if (parsed > maxAllowed) {
                              parsed = maxAllowed;
                              _amountPaidController.text = parsed == parsed.toInt() ? parsed.toInt().toString() : parsed.toString();
                              _amountPaidController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _amountPaidController.text.length),
                              );
                            }
                            setState(() {
                              CartStore.amountPaid = parsed;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Amount Paid (₹)'.tr,
                            prefixText: '₹ ',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
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
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.borderColor)),
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
                      Text('Subtotal:'.tr,
                          style: TextStyle(
                              fontSize: 12.5, color: context.textSecondary)),
                      Text('₹${CartStore.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GST Tax (5%):'.tr,
                          style: TextStyle(
                              fontSize: 12.5, color: context.textSecondary)),
                      Text('₹${CartStore.tax.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Payable:'.tr,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary)),
                      Text('₹${CartStore.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Paid:'.tr,
                          style: TextStyle(
                              fontSize: 12.5, color: context.textSecondary)),
                      Text('₹${CartStore.amountPaid.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balance Amount:'.tr,
                          style: TextStyle(
                              fontSize: 12.5, color: context.textSecondary)),
                      Text(
                          '₹${(CartStore.amountPaid - CartStore.total).toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color:
                                  (CartStore.amountPaid - CartStore.total) >= 0
                                      ? AppTheme.successGreen
                                      : AppTheme.dangerRed)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Generate Bill'.tr,
                    icon: Icons.receipt_long_rounded,
                    onPressed: () async {
                      if (CartStore.customerPhone.isNotEmpty && CartStore.customerPhone.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.dangerRed,
                            content: Text('Customer mobile number must be exactly 10 digits.'.tr),
                          ),
                        );
                        return;
                      }

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
                        amountPaid: CartStore.amountPaid,
                        status: CartStore.amountPaid >= CartStore.total
                            ? 'Paid'
                            : 'Pending',
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      await BillStore.save(newBill);
                      CartStore.clear();
                      CartStore.amountPaid = 0.0;
                      if (mounted) {
                        setState(() {
                          _syncControllers();
                        });
                      }
                      messenger.hideCurrentSnackBar();
                      if (!mounted) return;
                      await showBillReceiptModal(context, newBill);
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
