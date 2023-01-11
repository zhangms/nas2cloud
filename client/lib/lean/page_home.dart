import 'package:flutter/material.dart';
import 'package:nas2cloud/lean/page_favorites.dart';
import 'package:nas2cloud/lean/page_generator.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  Widget getWidgetByIndex(int index) {
    switch (index) {
      case 0:
        return GeneratorPage();
      case 1:
        return FavoritePage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget page = getWidgetByIndex(selectedIndex);
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
                child: NavigationRail(
              extended: constraints.maxWidth >= 600,
              destinations: [
                NavigationRailDestination(
                    icon: Icon(Icons.home), label: Text("Home")),
                NavigationRailDestination(
                    icon: Icon(Icons.favorite), label: Text("Favorites"))
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            )),
            Expanded(
                child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ))
          ],
        ),
      );
    });
  }
}
