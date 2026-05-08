import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeletons {

  // 🔥 LISTA DE PEDIDOS
  static Widget pedidosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 16, width: 120, color: Colors.white),
                    Container(height: 20, width: 80, color: Colors.white),
                  ],
                ),

                const SizedBox(height: 10),

                Container(height: 14, width: 150, color: Colors.white),

                const SizedBox(height: 10),

                Container(height: 14, width: 100, color: Colors.white),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 16, width: 80, color: Colors.white),
                    Container(height: 16, width: 20, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}