// test/core/widgets/pakistan_city_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/widgets/pakistan_city_field.dart';
import 'package:pfc_app/core/constants/pakistan_cities.dart';

/// Wraps [PakistanCityField] in a minimal [MaterialApp] + [Form].
Widget buildField({
  String? initialValue,
  void Function(String?)? onChanged,
  String label = 'CITY',
  bool required = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Form(
        child: PakistanCityField(
          initialValue: initialValue,
          onChanged: onChanged ?? (_) {},
          label: label,
          required: required,
        ),
      ),
    ),
  );
}

void main() {
  group('PakistanCityField', () {
    testWidgets('renders dropdown with correct label', (tester) async {
      await tester.pumpWidget(buildField(label: 'CITY OF RESIDENCE'));
      expect(find.text('CITY OF RESIDENCE'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('does not show free-text field initially when no initialValue',
        (tester) async {
      await tester.pumpWidget(buildField());
      expect(find.byKey(const Key('city_other_text_field')), findsNothing);
    });

    testWidgets('pre-selects known city from initialValue', (tester) async {
      await tester.pumpWidget(buildField(initialValue: 'Lahore'));
      await tester.pump();
      expect(find.text('Lahore'), findsOneWidget);
      expect(find.byKey(const Key('city_other_text_field')), findsNothing);
    });

    testWidgets(
        'shows Other... selected and free-text field when initialValue is not in list',
        (tester) async {
      await tester.pumpWidget(buildField(initialValue: 'My Custom Town'));
      await tester.pump();
      // Dropdown shows 'Other...'
      expect(find.text('Other...'), findsOneWidget);
      // Free-text field is visible and pre-populated
      expect(find.byKey(const Key('city_other_text_field')), findsOneWidget);
      expect(find.text('My Custom Town'), findsOneWidget);
    });

    testWidgets('emits selected city string via onChanged', (tester) async {
      String? emitted;
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select 'Karachi'
      await tester.tap(find.text('Karachi').last);
      await tester.pumpAndSettle();

      expect(emitted, 'Karachi');
    });

    testWidgets('shows free-text field when Other... is selected',
        (tester) async {
      await tester.pumpWidget(buildField());

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('city_other_text_field')), findsOneWidget);
    });

    testWidgets('emits trimmed other-text via onChanged when Other... typed',
        (tester) async {
      String? emitted;
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('city_other_text_field')), '  Turbat  ');
      await tester.pump();

      expect(emitted, 'Turbat');
    });

    testWidgets('emits null when Other... selected but text field is empty',
        (tester) async {
      String? emitted = 'initial';
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      // Text field is empty — widget should emit null
      expect(emitted, isNull);
    });

    testWidgets(
        'required=true shows error on dropdown when submitted without selection',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PakistanCityField(
              initialValue: null,
              onChanged: (_) {},
              required: true,
            ),
          ),
        ),
      ));

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('City is required'), findsOneWidget);
    });

    testWidgets(
        'required=true shows error on free-text field when Other... selected but empty',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PakistanCityField(
              initialValue: null,
              onChanged: (_) {},
              required: true,
            ),
          ),
        ),
      ));

      // Select Other...
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Please enter your city'), findsOneWidget);
    });

    testWidgets('required=false does not show error when empty', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PakistanCityField(
              initialValue: null,
              onChanged: (_) {},
              required: false,
            ),
          ),
        ),
      ));

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('City is required'), findsNothing);
    });

    testWidgets(
        'free-text field disappears and Other... text is cleared when a named city is selected after Other...',
        (tester) async {
      String? emitted;
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      // Select Other... first
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('city_other_text_field')), findsOneWidget);

      // Now select a named city
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sialkot').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('city_other_text_field')), findsNothing);
      expect(emitted, 'Sialkot');
    });
  });
}
