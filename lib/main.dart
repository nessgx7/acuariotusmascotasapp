import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AcuarioApp());
}

const kAzul = Color(0xFF426AFA);
const kNaranja = Color(0xFFFFB13D);

class AcuarioApp extends StatelessWidget {
  const AcuarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Acuario Tus Mascotas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kAzul,
          primary: kAzul,
          secondary: kNaranja,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class TankItem {
  String name;
  int qty;
  String? imagePath; // ruta local de la imagen

  TankItem({required this.name, required this.qty, this.imagePath});

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'imagePath': imagePath,
      };
  factory TankItem.fromJson(Map<String, dynamic> j) => TankItem(
        name: j['name'] ?? '',
        qty: (j['qty'] ?? 0) as int,
        imagePath: j['imagePath'] as String?,
      );
}

class Tank {
  String title;
  String? imagePath;
  List<TankItem> items;

  Tank({required this.title, this.imagePath, this.items = const []});

  Map<String, dynamic> toJson() => {
        'title': title,
        'imagePath': imagePath,
        'items': items.map((e) => e.toJson()).toList(),
      };
  factory Tank.fromJson(Map<String, dynamic> j) => Tank(
        title: j['title'] ?? 'Pecera',
        imagePath: j['imagePath'] as String?,
        items: (j['items'] as List? ?? [])
            .map((e) => TankItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  List<Tank> tanks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tanks');
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => Tank.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() => tanks = list);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tanks', jsonEncode(tanks.map((e) => e.toJson()).toList()));
  }

  void _openTank(Tank tank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(tank.title,
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700,
                        )),
                  ),
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () async {
                      final updated = await _showTankEditor(existing: tank);
                      if (updated != null) {
                        setState(() {});
                        _save();
                      }
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: tank.items.length,
                  itemBuilder: (context, i) {
                    final it = tank.items[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: kAzul.withOpacity(0.15)),
                      ),
                      child: ListTile(
                        leading: it.imagePath == null
                            ? CircleAvatar(backgroundColor: kAzul.withOpacity(0.15),
                                child: const Icon(Icons.image_not_supported))
                            : CircleAvatar(
                                backgroundImage: FileImage(File(it.imagePath!))),
                        title: Text(it.name),
                        subtitle: Text('Cantidad: ${it.qty}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return x?.path;
  }

  Future<Tank?> _showTankEditor({Tank? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    String? tankImage = existing?.imagePath;
    final items = existing?.items
            .map((e) => TankItem(name: e.name, qty: e.qty, imagePath: e.imagePath))
            .toList() ??
        [TankItem(name: '', qty: 0)];

    return showModalBottomSheet<Tank?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16, right: 16, top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(existing == null ? 'Nueva pecera' : 'Editar pecera',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          tooltip: 'Imagen de la pecera',
                          onPressed: () async {
                            final p = await _pickImage();
                            setModal(() => tankImage = p);
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título de la pecera',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Animales/plantas', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...List.generate(items.length, (i) {
                      final nameCtrl = TextEditingController(text: items[i].name);
                      final qtyCtrl = TextEditingController(text: items[i].qty == 0 ? '' : items[i].qty.toString());
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: kAzul.withOpacity(0.15)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final p = await _pickImage();
                                      setModal(() => items[i].imagePath = p);
                                    },
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: kAzul.withOpacity(0.1),
                                      backgroundImage: items[i].imagePath != null
                                          ? FileImage(File(items[i].imagePath!))
                                          : null,
                                      child: items[i].imagePath == null
                                          ? const Icon(Icons.add_a_photo)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: nameCtrl,
                                          onChanged: (v) => items[i].name = v,
                                          decoration: const InputDecoration(
                                            labelText: 'Nombre (pez/animal/planta)',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: qtyCtrl,
                                          onChanged: (v) => items[i].qty = int.tryParse(v) ?? 0,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Cantidad',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () {
                                      setModal(() => items.removeAt(i));
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setModal(() => items.add(TankItem(name: '', qty: 0)));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar otro'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: kAzul),
                            onPressed: () {
                              final t = titleCtrl.text.trim();
                              if (t.isEmpty) return;
                              final filtered = items.where((e) => e.name.trim().isNotEmpty).toList();
                              final tank = Tank(title: t, imagePath: tankImage, items: filtered);
                              Navigator.pop(context, tank);
                            },
                            child: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const SizedBox(height: 6),
            Text('ACUARIO TUS MASCOTAS',
                style: TextStyle(
                  color: kAzul,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                )),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = 180.0;
            final spacing = 14.0;
            final crossAxisCount = (constraints.maxWidth / (itemWidth + spacing)).floor().clamp(1, 4);
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 1.3,
              ),
              itemCount: tanks.length,
              itemBuilder: (context, i) {
                final t = tanks[i];
                return _TankCard(
                  tank: t,
                  onTap: () => _openTank(t),
                  onLongPress: () async {
                    // editar o borrar
                    final sel = await showMenu<String>(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    );
                    if (sel == 'edit') {
                      final updated = await _showTankEditor(existing: t);
                      if (updated != null) setState(() {});
                      _save();
                    } else if (sel == 'delete') {
                      setState(() => tanks.removeAt(i));
                      _save();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAzul,
        onPressed: () async {
          final tank = await _showTankEditor();
          if (tank != null) {
            setState(() => tanks.add(tank));
            _save();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TankCard extends StatelessWidget {
  final Tank tank;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _TankCard({required this.tank, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kAzul.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kAzul.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  image: tank.imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(tank.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tank.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
