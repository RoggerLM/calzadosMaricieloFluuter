// widgets/departamento_dropdown.dart
import 'package:flutter/material.dart';
import '../models/PeruDepartments.dart';

class DepartamentoDropdown extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;
  final bool requerido;
  final String? hintText;

  const DepartamentoDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    this.requerido = true,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Departamento',
        hintText: hintText ?? 'Selecciona un departamento',
        prefixIcon: const Icon(Icons.map),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: PeruDepartments.departamentos.map((departamento) {
        return DropdownMenuItem<String>(
          value: departamento,
          child: Text(departamento),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (requerido && (value == null || value.isEmpty)) {
          return 'Por favor selecciona un departamento';
        }
        return null;
      },
    );
  }
}