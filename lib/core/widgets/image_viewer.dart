import 'package:flutter/material.dart';

/// เปิดรูปเต็มจอ ซูม/เลื่อนได้ (ใช้ร่วมกันหลายหน้า)
void showZoomableImage(BuildContext context, String imageUrl) {
  if (imageUrl.isEmpty) return;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(40),
                child: Text('โหลดรูปไม่สำเร็จ', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
