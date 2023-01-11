import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state_app.dart';
import 'widget_bigcard.dart';

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;
    var current = appState.current;

    IconData icon;
    if (favorites.contains(current)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: current),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: Icon(icon),
                label: Text("Like"),
                onPressed: () {
                  appState.toggleFavorites();
                },
              ),
              SizedBox(
                width: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  child: Text("Next")),
            ],
          )
        ],
      ),
    );
  }
}
