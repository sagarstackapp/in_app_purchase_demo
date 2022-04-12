import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  State<ProductScreen> createState() => ProductScreenState();
}

final List<String> productIds = [
  'android.test.purchased',
  'inapptest',
  'hello'
];

class ProductScreenState extends State<ProductScreen> {
  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  List<String> noFoundId = [];
  List<ProductDetails> availableProducts = <ProductDetails>[];
  StreamSubscription<List<PurchaseDetails>>? streamSubscription;
  bool isAvailable = false;

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseStream =
        inAppPurchase.purchaseStream;
    streamSubscription = purchaseStream.listen(
      (List<PurchaseDetails> event) {
        log('Event --> ${event.first}');
      },
      onDone: () => log('Subs done'),
      onError: (error) {
        log('Subs error --> $error');
      },
    );
    initStoreInfo();
    super.initState();
  }

  @override
  void dispose() {
    streamSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAvailable ? 'Store Open' : ' Store closed'),
        elevation: 0,
      ),
      body: Center(
        child: !isAvailable
            ? const Text('Store is Closed')
            : ListView(
                children: [
                  const Center(
                    child: Text(
                      'Available Products',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: availableProducts.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          PurchaseParam purchaseParam;
                          purchaseParam = GooglePlayPurchaseParam(
                            productDetails: availableProducts[index],
                            applicationUserName: null,
                          );
                          inAppPurchase.buyNonConsumable(
                              purchaseParam: purchaseParam);
                        },
                        child: ListTile(
                          leading: Container(
                            decoration: const BoxDecoration(
                                color: Colors.cyan, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(8),
                            child: Text('${index + 1}'),
                          ),
                          title: Text(availableProducts[index].title),
                          subtitle: Text(availableProducts[index].description),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                  const Center(
                    child: Text(
                      'No Found Products',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: noFoundId.length,
                    itemBuilder: (BuildContext context, int index) => ListTile(
                      leading: Container(
                        decoration: const BoxDecoration(
                            color: Colors.cyan, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(8),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(noFoundId[index]),
                      subtitle: Text(noFoundId[index]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> initStoreInfo() async {
    isAvailable = await inAppPurchase.isAvailable();
    log('Store available --> $isAvailable');
    if (!isAvailable) {
      return;
    }

    try {
      final ProductDetailsResponse productDetailsResponse =
          await inAppPurchase.queryProductDetails(productIds.toSet());
      if (productDetailsResponse.productDetails.isNotEmpty) {
        availableProducts = productDetailsResponse.productDetails;
        log('Available products --> $availableProducts');
        for (var element in availableProducts) {
          log('Products ${element.id} --> ${element.title} : ${element.description}');
        }
      }
      if (productDetailsResponse.notFoundIDs.isNotEmpty) {
        noFoundId = productDetailsResponse.notFoundIDs;
        log('Not found id --> $noFoundId');
      }
      if (productDetailsResponse.error != null) {
        log('Error --> ${productDetailsResponse.error!.code} : ${productDetailsResponse.error!.message}');
      }
    } on InAppPurchaseException catch (e) {
      log('Error in InAppPurchase --> ${e.message}');
    }
  }
}
