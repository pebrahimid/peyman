import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const GoldPriceApp());
}

class GoldPriceApp extends StatelessWidget {
  const GoldPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محاسبه قیمت طلا',
      theme: ThemeData(
        fontFamily: 'Vazir',
        scaffoldBackgroundColor: const Color(0xFFFCF8F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD4A017),
          foregroundColor: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      home: const GoldCalculator(),
    );
  }
}

class GoldCalculator extends StatefulWidget {
  const GoldCalculator({super.key});

  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator> {
  final goldPriceController = TextEditingController();
  final weightController = TextEditingController();
  final makingChargeController = TextEditingController();
  final profitController = TextEditingController();
  final extraController = TextEditingController();

  String result = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startAutoUpdatePrice();
  }

  void startAutoUpdatePrice() {
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final response = await http.get(Uri.parse('http://127.0.0.1:5000/gold-price'));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final price = data['price'].toString().replaceAll(',', '');
          setState(() {
            goldPriceController.text = price;
          });
        }
      } catch (e) {
        print('خطا در دریافت قیمت: $e');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void calculate() {
    final price = int.tryParse(goldPriceController.text.replaceAll(',', '')) ?? 0;
    final weight = double.tryParse(weightController.text) ?? 0;
    final making = double.tryParse(makingChargeController.text) ?? 0;
    final profit = double.tryParse(profitController.text) ?? 0;
    final extra = int.tryParse(extraController.text) ?? 0;

    final goldTotal = price * weight;
    final makingTotal = goldTotal * making / 100;
    final profitTotal = (goldTotal + makingTotal) * profit / 100;
    final tax = (profitTotal + makingTotal) * 0.09;
    final total = goldTotal + makingTotal + profitTotal + tax + extra;

    setState(() {
      result = '''
قیمت طلا: ${goldTotal.toStringAsFixed(0)} تومان
اجرت ساخت: ${makingTotal.toStringAsFixed(0)} تومان
سود فروش: ${profitTotal.toStringAsFixed(0)} تومان
مالیات: ${tax.toStringAsFixed(0)} تومان
قیمت نهایی: ${total.toStringAsFixed(0)} تومان
''';
    });
  }

  void reset() {
    goldPriceController.clear();
    weightController.clear();
    makingChargeController.clear();
    profitController.clear();
    extraController.clear();
    setState(() => result = '');
  }

  Widget buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('محاسبه قیمت طلا')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildField(goldPriceController, 'نرخ طلا (تومان)'),
              buildField(weightController, 'وزن طلا (گرم)'),
              buildField(makingChargeController, 'اجرت ساخت (%)'),
              buildField(profitController, 'سود فروش (%)'),
              buildField(extraController, 'ملحقات (اختیاری - تومان)'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: calculate, child: const Text('محاسبه')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: reset, child: const Text('ریست')),
                ],
              ),
              const SizedBox(height: 16),
              Text(result, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
