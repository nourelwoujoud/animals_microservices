class Animal {
  final int id;
  final String name;
  final String type;
  final String breed;
  final int age;
  final String gender;
  final String description;
  final String status;

  Animal({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.gender,
    required this.description,
    required this.status,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] is int ? json['age'] : int.parse(json['age'].toString()),
      gender: json['gender'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'available',
    );
  }

  bool get isAvailable => status.toLowerCase() == 'available';

  String get ageLabel => age == 1 ? '1 an' : '$age ans';

  String get genderIcon => gender.toLowerCase() == 'male' ? '♂' : '♀';

  String get typeEmoji {
    switch (type.toLowerCase()) {
      case 'dog':
      case 'chien':
        return '🐕';
      case 'cat':
      case 'chat':
        return '🐈';
      case 'rabbit':
      case 'lapin':
        return '🐇';
      case 'bird':
      case 'oiseau':
        return '🦜';
      default:
        return '🐾';
    }
  }
}