/*
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawprintgp/components/adoption_post.dart';
import 'package:pawprintgp/models/adoptionpost_model.dart';

void main() {
  testWidgets('AdoptionPostWidget displays post information', (WidgetTester tester) async {
    final post = AdoptionPost(
      title: 'Test Title',
      description: 'Test Description',
      age: '2 years',
      breed: 'Test Breed',
      location: 'Test Location',
      userEmail: 'test@example.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdoptionPostWidget(post: post),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.text('Age: 2 years'), findsOneWidget);
    expect(find.text('Breed: Test Breed'), findsOneWidget);
    expect(find.text('Location: Test Location'), findsOneWidget);
    expect(find.text('User Email: test@example.com'), findsOneWidget);
  });
}
*/