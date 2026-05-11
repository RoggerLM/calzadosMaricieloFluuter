// widgets/provincia_dropdown.dart
import 'package:flutter/material.dart';
import '../models/PeruDepartments.dart';

class ProvinciaDropdown extends StatelessWidget {
  final String? departamento;
  final String? value;
  final Function(String?) onChanged;
  final bool requerido;

  const ProvinciaDropdown({
    Key? key,
    required this.departamento,
    required this.value,
    required this.onChanged,
    this.requerido = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provincias = departamento != null && PeruDepartments.provinciasPorDepartamento.containsKey(departamento)
        ? PeruDepartments.provinciasPorDepartamento[departamento]!
        : <String>[];

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Provincia',
        prefixIcon: const Icon(Icons.location_city),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: provincias.map((provincia) {
        return DropdownMenuItem<String>(
          value: provincia,
          child: Text(provincia),
        );
      }).toList(),
      onChanged: departamento != null ? onChanged : null,
      validator: (value) {
        if (requerido && departamento != null && (value == null || value.isEmpty)) {
          return 'Por favor selecciona una provincia';
        }
        return null;
      },
    );
  }
}