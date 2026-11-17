class SavedDevice {
  const SavedDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.model,
    this.brand = 'Samsung',
    this.type = 'Samsung SmartTV',
    this.protocol = 'Samsung Wi-Fi (WSS)',
  });

  final String id;
  final String name;
  final String ip;
  final String model;
  final String brand;
  final String type;
  final String protocol;

  SavedDevice copyWith({String? name, String? ip}) => SavedDevice(
        id: id,
        name: name ?? this.name,
        ip: ip ?? this.ip,
        model: model,
        brand: brand,
        type: type,
        protocol: protocol,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'ip': ip, 'model': model,
        'brand': brand, 'type': type, 'protocol': protocol,
      };

  factory SavedDevice.fromJson(Map<String, dynamic> json) => SavedDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        ip: json['ip'] as String,
        model: json['model'] as String? ?? 'Unknown',
        brand: json['brand'] as String? ?? 'Samsung',
        type: json['type'] as String? ?? 'Samsung SmartTV',
        protocol: json['protocol'] as String? ?? 'Samsung Wi-Fi (WSS)',
      );
}

class FoundDevice {
  const FoundDevice({required this.id, required this.ip,
    required this.name, required this.model, required this.type});
  final String id;
  final String ip;
  final String name;
  final String model;
  final String type;
}
