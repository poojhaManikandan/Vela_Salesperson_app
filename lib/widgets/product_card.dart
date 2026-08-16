import 'package:flutter/material.dart';
import '../data/cart_store.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Grid-style or List-style product card with quick POS billing add capabilities.
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isCompactList;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onProductUpdated;

  const ProductCard({
    super.key,
    required this.product,
    this.isCompactList = false,
    this.onTap,
    this.onAddToCart,
    this.onProductUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = product.stock == 0;
    final int qtyInCart = CartStore.quantityFor(product);

    if (isCompactList) {
      return _buildCompactList(context, outOfStock, qtyInCart);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        child: Opacity(
          opacity: outOfStock ? 0.55 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _productImage(context, iconSize: 36),
                    ),

                    if (outOfStock)
                      Positioned(
                        top: 8,
                        left: 42,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Out of stock',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    else if (qtyInCart > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            '$qtyInCart in cart',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: qtyInCart > 0 ? 80 : 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: product.isGst
                              ? AppTheme.primaryGreen.withValues(alpha: 0.85)
                              : Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.isGst ? 'GST 5%' : 'NON-GST',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.category,
                      style: TextStyle(
                          fontSize: 11, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '₹${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                ),
                                if (CartStore.activeEmployee == '9344486055')
                                  InkWell(
                                    onTap: () => _editPrice(context),
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 4.0),
                                      child: Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              '/${product.unit}',
                              style: TextStyle(
                                  color: context.textSecondary, fontSize: 10.5),
                            ),
                          ],
                        ),
                        if (!outOfStock && onAddToCart != null)
                          Material(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: onAddToCart,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget _productImage(BuildContext context,
      {required double iconSize, double? size}) {
    final url = product.imageUrl.trim();
    final fallback = Container(
      width: size,
      height: size,
      color: context.surfaceAlt,
      child: Icon(Icons.inventory_2_outlined,
          size: iconSize, color: context.textSecondary),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _buildCompactList(BuildContext context, bool outOfStock, int qtyInCart) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: outOfStock ? null : onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _productImage(context, iconSize: 20, size: 44),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            if (qtyInCart > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$qtyInCart',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        subtitle: Text(
          outOfStock
              ? 'ID: ${product.id} · Out of Stock'
              : 'ID: ${product.id} · Stock: ${product.stock}',
          style: TextStyle(
            fontSize: 11,
            color: outOfStock
                ? AppTheme.dangerRed
                : (product.stock < 5 ? AppTheme.accentOrange : context.textSecondary),
            fontWeight: (outOfStock || product.stock < 5) ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: context.textPrimary),
                ),
                if (CartStore.activeEmployee == '9344486055')
                  InkWell(
                    onTap: () => _editPrice(context),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            if (!outOfStock && onAddToCart != null)
              Material(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onAddToCart,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _editPrice(BuildContext context) async {
    final ctrl = TextEditingController(text: product.price.toString());
    final newPrice = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Product Price'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'New Price'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)), child: const Text('Save')),
        ],
      ),
    );
    
    if (newPrice != null && newPrice > 0) {
      try {
        await ApiService.updateProductPrice(product.id, newPrice);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Price updated successfully!'))
          );
        }
        onProductUpdated?.call();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update price: $e'))
          );
        }
      }
    }
  }
}

