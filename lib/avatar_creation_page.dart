import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AvatarCreationPage extends StatefulWidget {
  const AvatarCreationPage({super.key});

  @override
  State<AvatarCreationPage> createState() => _AvatarCreationPageState();
}

class _AvatarCreationPageState extends State<AvatarCreationPage> {
  final List<String> _avatarFiles = [
    '1.png',
    '2.png',
    '3.png',
    '4.png',
    '5.png',
    '6.png',
    '7.png',
    '9.png',
    '10.png'
  ];

  String _selectedAvatar = '1.png';

  String _getAvatarPath(String fileName) {
    return 'assets/avatars/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6E7F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Your Avatar',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newAvatarPath = _getAvatarPath(_selectedAvatar);
              final supabase = Supabase.instance.client;
              final user = supabase.auth.currentUser;
              if (user != null) {
                await supabase
                    .from('users')
                    .update({'avatar_url': newAvatarPath}) // ✅ snake_case
                    .eq('id', user.id);
              }
              Navigator.of(context).pop(newAvatarPath);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(_getAvatarPath(_selectedAvatar)),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Choose a base character',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _avatarFiles.length,
                itemBuilder: (context, index) {
                  final avatarFile = _avatarFiles[index];
                  final isSelected = _selectedAvatar == avatarFile;
                  final avatarPath = _getAvatarPath(avatarFile);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatarFile;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                      ),
                      child: CircleAvatar(
                        backgroundImage: AssetImage(avatarPath),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
