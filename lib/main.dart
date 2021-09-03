import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:inapp_purchase/features/inAppPurchaseCubit.dart';
import 'package:inapp_purchase/utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<InAppPurchaseCubit>(create: (_) => InAppPurchaseCubit(productIds: inAppPurchaseProducts.keys.toList())),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _buildProducts(List<ProductDetails> products) {
    return ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () {
              //print(products[index].id);
              context.read<InAppPurchaseCubit>().buyConsumableProducts(products[index]);
            },
            title: Text(products[index].title),
            subtitle: Text(products[index].price),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("In-App Purchase"),
      ),
      body: BlocConsumer<InAppPurchaseCubit, InAppPurchaseState>(
        bloc: context.read<InAppPurchaseCubit>(),
        listener: (context, state) {
          print("State change to ${state.toString()}");
          if (state is InAppPurchaseProcessSuccess) {
            print("Add ${inAppPurchaseProducts[state.purchasedProductId]} coins to user wallet");
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      content: Text("Coin Purchased Successfully"),
                    ));
          } else if (state is InAppPurchaseFailure) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      content: Text(state.errorMessage),
                    ));
          } else if (state is InAppPurchaseProcessFailure) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      content: Text(state.errorMessage),
                    ));
          }
        },
        builder: (context, state) {
          //initial state of cubit
          if (state is InAppPurchaseInitial || state is InAppPurchaseLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          //if occurred problem while fetching product details
          //from appstore or playstore
          if (state is InAppPurchaseFailure) {
            //
            return Center(
              child: Text("${state.errorMessage}"),
            );
          }

          if (state is InAppPurchaseNotAvailable) {
            return Center(
              child: Text("In-app purchase is not available"),
            );
          }

          //if any error occurred in while making in-app purchase
          if (state is InAppPurchaseProcessFailure) {
            return _buildProducts(state.products);
          }
          //
          if (state is InAppPurchaseAvailable) {
            return _buildProducts(state.products);
          }
          //
          if (state is InAppPurchaseProcessSuccess) {
            return _buildProducts(state.products);
          }

          return Container();
        },
      ),
    );
  }
}
