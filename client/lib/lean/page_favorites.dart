import 'package:flutter/material.dart';
import 'package:nas2cloud/lean/state_app.dart';
import 'package:provider/provider.dart';

class FavoritePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;
    if (favorites.isEmpty) {
      return Center(
        child: Text("no favorites"),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text("you have ${favorites.length} favorites"),
        ),
        for (var favor in favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(favor.asLowerCase),
          ),
      ],
    );
  }
}
