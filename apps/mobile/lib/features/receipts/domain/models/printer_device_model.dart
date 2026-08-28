enum PrinterPaperWidth { mm58, mm80 }

enum PrinterPageFormat { a4, roll58mm, roll80mm }

extension PrinterPaperWidthExtension on PrinterPaperWidth {
  int get columns => this == PrinterPaperWidth.mm58 ? 32 : 48;
  String get label => this == PrinterPaperWidth.mm58 ? '58mm' : '80mm';

  static PrinterPaperWidth fromString(String? val) {
    if (val == '80mm' || val == 'mm80') return PrinterPaperWidth.mm80;
    return PrinterPaperWidth.mm58;
  }
}

extension PrinterPageFormatExtension on PrinterPageFormat {
  String get label {
    switch (this) {
      case PrinterPageFormat.a4:
        return 'A4';
      case PrinterPageFormat.roll58mm:
        return '58mm Roll';
      case PrinterPageFormat.roll80mm:
        return '80mm Roll';
    }
  }

  PrinterPaperWidth get toPaperWidth {
    switch (this) {
      case PrinterPageFormat.a4:
        return PrinterPaperWidth.mm80;
      case PrinterPageFormat.roll58mm:
        return PrinterPaperWidth.mm58;
      case PrinterPageFormat.roll80mm:
        return PrinterPaperWidth.mm80;
    }
  }

  static PrinterPageFormat fromString(String? val) {
    switch (val) {
      case 'a4':
        return PrinterPageFormat.a4;
      case 'roll58mm':
        return PrinterPageFormat.roll58mm;
      case 'roll80mm':
        return PrinterPageFormat.roll80mm;
      default:
        return PrinterPageFormat.roll80mm;
    }
  }
}

class PrinterDeviceModel {
  final String id;
  final String name;
  final String address; // IP:port for WiFi, MAC for BT
  final String connectionType; // 'wifi', 'network', 'bluetooth', 'usb'
  final PrinterPaperWidth paperWidth;
  final bool isConnected;
  final bool isColor;
  final PrinterPageFormat pageFormat;
  final int copies;
  final String? url; // For WiFi printers: IPP/HTTP URL

  const PrinterDeviceModel({
    required this.id,
    required this.name,
    required this.address,
    this.connectionType = 'wifi',
    this.paperWidth = PrinterPaperWidth.mm80,
    this.isConnected = false,
    this.isColor = true,
    this.pageFormat = PrinterPageFormat.roll80mm,
    this.copies = 1,
    this.url,
  });

  PrinterDeviceModel copyWith({
    String? id,
    String? name,
    String? address,
    String? connectionType,
    PrinterPaperWidth? paperWidth,
    bool? isConnected,
    bool? isColor,
    PrinterPageFormat? pageFormat,
    int? copies,
    String? url,
  }) {
    return PrinterDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      connectionType: connectionType ?? this.connectionType,
      paperWidth: paperWidth ?? this.paperWidth,
      isConnected: isConnected ?? this.isConnected,
      isColor: isColor ?? this.isColor,
      pageFormat: pageFormat ?? this.pageFormat,
      copies: copies ?? this.copies,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'connection_type': connectionType,
        'paper_width': paperWidth.label,
        'is_connected': isConnected,
        'is_color': isColor,
        'page_format': pageFormat.name,
        'copies': copies,
        'url': url,
      };

  factory PrinterDeviceModel.fromJson(Map<String, dynamic> json) =>
      PrinterDeviceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        connectionType: json['connection_type'] as String? ?? 'wifi',
        paperWidth: PrinterPaperWidthExtension.fromString(
            json['paper_width'] as String?),
        isConnected: json['is_connected'] as bool? ?? false,
        isColor: json['is_color'] as bool? ?? true,
        pageFormat: PrinterPageFormatExtension.fromString(
            json['page_format'] as String?),
        copies: json['copies'] as int? ?? 1,
        url: json['url'] as String?,
      );
}
