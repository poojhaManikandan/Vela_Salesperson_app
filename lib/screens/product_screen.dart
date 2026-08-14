import 'package:flutter/material.dart';
import '../data/cart_store.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'cart_screen.dart';

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool inStock = product.stock > 0;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _circleIconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
              actions: const [
                SizedBox(width: 12),
              ],
              expandedHeight: 300,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: context.surfaceAlt,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      size: 72,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                transform: Matrix4.translationValues(0, -20, 0),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SKU: ${product.id}  ·  Unit: ${product.unit}',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            label: 'Price',
                            value: '₹${product.price.toStringAsFixed(2)}',
                            icon: Icons.currency_rupee_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(
                            label: 'Stock',
                            value: inStock ? '${product.stock} units' : 'Out of stock',
                            icon: Icons.inventory_2_outlined,
                            valueColor:
                                inStock ? AppTheme.successGreen : AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Good quality ${product.name.toLowerCase()} sourced from trusted suppliers. '
                      'Sold per ${product.unit}, ideal for daily household and retail needs.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: context.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (inStock) ...[
                      const Text(
                        'Quantity',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _quantityButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                          ),
                          Container(
                            width: 56,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          _quantityButton(
                            icon: Icons.add,
                            onTap: () {
                              if (_quantity < product.stock) {
                                setState(() => _quantity++);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: PrimaryButton(
            label: inStock ? 'Add to Cart · ₹${(product.price * _quantity).toStringAsFixed(2)}' : 'Out of Stock',
            icon: Icons.shopping_cart_checkout_rounded,
            onPressed: inStock
                ? () {
                    final qtyInCart = CartStore.quantityFor(product);
                    final remaining = product.stock - qtyInCart;
                    final toAdd = _quantity > remaining ? remaining : _quantity;
                    var added = 0;
                    for (var i = 0; i < toAdd; i++) {
                      if (CartStore.add(product)) added++;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    if (added > 0) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            toAdd < _quantity
                                ? 'Only $remaining left in stock. $added added to cart.'
                                : '${product.name} added to cart',
                          ),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Stock limit reached for this product.'),
                        ),
                      );
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Material(
        color: context.surfaceColor,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: iconColor ?? context.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 11, color: context.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor ?? context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: context.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
        ),
      ),
    );
  }
}
