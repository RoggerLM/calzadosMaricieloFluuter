import 'package:flutter/material.dart';

class InvoicesTab extends StatelessWidget {
  const InvoicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInvoiceItem('B-001-2024', '15 Nov 2024', '\$120.00', true),
        _buildInvoiceItem('B-002-2024', '14 Nov 2024', '\$85.50', true),
        _buildInvoiceItem('F-001-2024', '13 Nov 2024', '\$200.00', false),
        _buildInvoiceItem('B-003-2024', '12 Nov 2024', '\$65.25', true),
      ],
    );
  }

  Widget _buildInvoiceItem(String number, String date, String amount, bool isBoleta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isBoleta ? Colors.purple.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt,
            color: isBoleta ? Colors.purple : Colors.orange,
          ),
        ),
        title: Text(
          number,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(date),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              isBoleta ? 'Boleta' : 'Factura',
              style: TextStyle(
                fontSize: 12,
                color: isBoleta ? Colors.purple : Colors.orange,
              ),
            ),
          ],
        ),
        onTap: () {
          // Ver detalle de boleta/factura
        },
      ),
    );
  }
}