import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  final String? authToken;
  final String? userId;
  List<Product> _items = [];

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool isFilterByUser = false]) async {
    final filterString =
        isFilterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = Uri.parse(
        'https://shop-app-d7e86-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?auth=$authToken&$filterString');
    try {
      final response = await http.get(url);
      if (response.body == 'null') {
        _items = [];
        notifyListeners();
        return;
      }
      url = Uri.parse(
          'https://shop-app-d7e86-default-rtdb.asia-southeast1.firebasedatabase.app/userFavorites/$userId.json?auth=$authToken');
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          imageUrl: prodData['imageUrl'],
          isFavorite: favoriteData == null
              ? false
              : (favoriteData[prodId] == null
                  ? false
                  : favoriteData[prodId]['isFavorite']),
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.parse(
        'https://shop-app-d7e86-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?auth=$authToken');
    try {
      final response = await http.post(url,
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'creatorId': userId,
          }));
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _items.add(newProduct);
      // _items.insert(0, newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = Uri.parse(
          'https://shop-app-d7e86-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json?auth=$authToken');
      try {
        await http.patch(url,
            body: json.encode({
              'title': newProduct.title,
              'description': newProduct.description,
              'price': newProduct.price,
              'imageUrl': newProduct.imageUrl,
            }));
        _items[prodIndex] = newProduct;
        notifyListeners();
      } catch (error) {
        throw error;
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse(
        'https://shop-app-d7e86-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json?auth=$authToken');
    try {
      await http.delete(url).then((response) {
        if (response.statusCode >= 400) {
          throw HttpException('Failed to delete.');
        }
        _items.removeWhere((prod) => prod.id == id);
        notifyListeners();
      });
    } catch (error) {
      throw (error);
    }
  }
}
