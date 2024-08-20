import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final List<String> _contacts = [
    'Devesh Ojha',
    'Sanjay text',
    'Mohit jaiswal',
    'Suresh nair',
    'Alex dame',
    'Stelli forte',
    'Aman singh',
    'Mohit tyagi',
    'Joshep',
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _contacts
        .where((contact) =>
            contact.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                'J',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              backgroundColor: Colors.white24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search by name, number...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Contacts',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemBuilder: (_, i) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/avatar_$i.png'), // Placeholder image
                  ),
                  title: Text(
                    filteredContacts[i],
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              },
              separatorBuilder: (_, i) {
                return const Divider();
              },
              itemCount: filteredContacts.length,
            ),
          ),
        ],
      ),
    );
  }
}
