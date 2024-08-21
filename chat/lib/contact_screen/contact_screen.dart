import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/reverpod/auth_providers/user_auth.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final auth = UserAuth();
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final currentUserID = auth.auth.currentUser?.uid;
                final contacts = snapshot.data?.docs ?? [];

                final filteredContacts = contacts.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  final userID = doc['id'].toString();

                  return name.contains(_searchText.toLowerCase()) &&
                      userID != currentUserID; // Exclude current user
                }).toList();

                return ListView.separated(
                  itemBuilder: (_, i) {
                    final contact = filteredContacts[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        // backgroundImage:
                        // AssetImage('assets/avatar_$i.png'), // Placeholder image
                      ),
                      title: Text(
                        contact['name'], // Assuming 'name' field exists in Firestore
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  },
                  separatorBuilder: (_, i) {
                    return const Divider();
                  },
                  itemCount: filteredContacts.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
