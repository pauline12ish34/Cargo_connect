import 'package:cargo_app/widgets/review_dialogue.dart';
import 'package:flutter/material.dart';

void showPaymentDialog(BuildContext context, {double price = 80000}) {
  final phoneController = TextEditingController();
  final tax = (price * 0.05).roundToDouble();
  final total = price + tax;

  String formatRwf(double amount) =>
      'Rwf ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("PAY", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("Subtotal"), Text(formatRwf(price))],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("Tax (5%)"), Text(formatRwf(tax))],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(formatRwf(total), style: const TextStyle(color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const TextField(
            readOnly: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.phone_android),
              hintText: "MTN Mobile Money",
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone),
              hintText: "Phone number",
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your phone number')),
                );
                return;
              }
              Navigator.pop(context);
              showThankYouDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size.fromHeight(45),
            ),
            child: const Text("PAY"),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bank transfer coming soon')),
              );
            },
            child: const Text("USE BANK", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    ),
  );
}

void showThankYouDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.teal, size: 60),
          const SizedBox(height: 10),
          const Text(
            "PAYMENT SUCCESSFUL",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your payment was successful. Thank you for choosing our services.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                builder: (_) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ReviewDialog(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size.fromHeight(45),
            ),
            child: const Text("Give Feedback"),
          ),
        ],
      ),
    ),
  );
}
