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
  // 🔥 LISTA DE PRODUCTOS
  static Widget productosList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          // SEARCH
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // FILTROS
          Row(
            children: [
              _box(width: 110, height: 42),
              const SizedBox(width: 12),
              _box(width: 160, height: 42),
            ],
          ),

          const SizedBox(height: 30),

          // ESTADISTICAS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              return Column(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _box(width: 50, height: 12),
                ],
              );
            }),
          ),

          const SizedBox(height: 30),

          // PRODUCTOS
          ListView.builder(
            itemCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [

                      // IMAGEN
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            _line(width: 70, height: 18),

                            const SizedBox(height: 12),

                            _line(width: 120),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                _line(width: 70),
                                const SizedBox(width: 12),
                                _line(width: 60),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _line(width: 140, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

// 🔥 LINEA
  static Widget _line({
    required double width,
    double height = 16,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.white,
    );
  }

// 🔥 CAJA
  static Widget _box({
    required double width,
    required double height,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}