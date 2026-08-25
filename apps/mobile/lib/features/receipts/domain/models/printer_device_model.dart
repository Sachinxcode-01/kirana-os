enum PrinterPaperWidth { mm58, mm80 }

extension PrinterPaperWidthExtension on PrinterPaperWidth {
  int get columns => this == PrinterPaperWidth.mm58 ? 32 : 48;
  String get label => this == PrinterPaperWidth.mm58 ? '58mm' : '80mm';

  static PrinterPaperWidth fromString(String? val) {
    if (val == '80mm' || val == 'mm80') return PrinterPaperWidth.mm80;
    return PrinterPaperWidth.mm58;
  }
}

class PrinterDeviceModel {
  final String id;
  final String name;
  final String address;
  final String connectionType; // 'bluetooth', 'usb'
  final PrinterPaperWidth paperWidth;
  final bool isConnected;

  const PrinterDeviceModel({
    required this.id,
    required this.name,
    required this.address,
    this.connectionType = 'bluetooth',
    this.paperWidth = PrinterPaperWidth.mm58,
    this.isConnected = false,
  });

  PrinterDeviceModel copyWith({
    String? id,
    String? name,
    String? address,
    String? connectionType,
    PrinterPaperWidth? paperWidth,
    bool? isConnected,
  }) {
    return PrinterDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      connectionType: connectionType ?? this.connectionType,
      paperWidth: paperWidth ?? this.paperWidth,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'connection_type': connectionType,
        'paper_width': paperWidth.label,
        'is_connected': isConnected,
      };

  factory PrinterDeviceModel.fromJson(Map<String, dynamic> json) =>
      PrinterDeviceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        connectionType: json['connection_type'] as String? ?? 'bluetooth',
        paperWidth: PrinterPaperWidthExtension.fromString(
            json['paper_width'] as String?),
        isConnected: json['is_connected'] as bool? ?? false,
      );
}
