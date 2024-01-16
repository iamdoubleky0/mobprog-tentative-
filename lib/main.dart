import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database.dart';

void main() {
  runApp(ContactsMapApp());
}

class Contact {
  int? id;
  String name;
  String phoneNumber;
  String address;

  Contact({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}

class ContactsMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ContactsListPage(),
    );
  }
}

class ContactsListPage extends StatefulWidget {
  @override
  _ContactsListPageState createState() => _ContactsListPageState();
}

class _ContactsListPageState extends State<ContactsListPage> {
  List<Contact> contacts = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final loadedContacts = await dbHelper.getContacts();
    setState(() {
      contacts = loadedContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(contacts[index].name),
            subtitle: Text(contacts[index].phoneNumber),
            onTap: () => _navigateToContactDetailPage(contacts[index], index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddContactPage(),
        child: Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddContactPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditContactPage()),
    );

    if (result is Contact) {
      setState(() {
        contacts.add(result);
      });
    }
  }

  void _navigateToContactDetailPage(Contact contact, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailPage(
          contact: contact,
          index: index,
          onEdit: (editedContact) {
            setState(() {
              contacts[index] = editedContact as Contact;
            });
          },
          onDelete: () {
            _showDeleteConfirmation(context, contact);
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Contact"),
          content: Text("Are you sure you want to delete this contact?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                _deleteContact(contact);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteContact(Contact contact) {
    setState(() {
      contacts.remove(contact);
    });
  }
}

class AddEditContactPage extends StatefulWidget {
  final Contact? contact;

  AddEditContactPage({this.contact});

  @override
  _AddEditContactPageState createState() => _AddEditContactPageState();
}

class _AddEditContactPageState extends State<AddEditContactPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.contact?.phoneNumber ?? '');
    _addressController =
        TextEditingController(text: widget.contact?.address ?? '');
  }

  @override
  void dispose() {
    // Dispose of the controllers to prevent memory leaks
    _nameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _saveContact(context),
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveContact(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneNumberController.text;
      if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid phone number.'),
          ),
        );
        return;
      }

      final editedContact = Contact(
        name: _nameController.text,
        phoneNumber: phoneNumber,
        address: _addressController.text,
      );

      final dbHelper = DatabaseHelper();
      try {
        if (widget.contact == null) {
          print('Inserting new contact: $editedContact');
          await dbHelper.insertContact(editedContact);
        } else {
          print('Updating contact: $editedContact');
          editedContact.id = widget.contact!.id;
          await dbHelper.updateContact(editedContact);
        }
      } catch (e) {
        print('Error saving contact: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving contact. Please try again.'),
          ),
        );
        return;
      }

      Navigator.of(context).pop(editedContact);
    }
  }
}

class ContactDetailPage extends StatelessWidget {
  final Contact contact;
  final int index;
  final Function(Contact) onEdit;
  final VoidCallback onDelete;

  ContactDetailPage({
    required this.contact,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Phone: ${contact.phoneNumber}', style: TextStyle(fontSize: 18)),
              Text('Address: ${contact.address}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              if (contact.address.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(37.4220, -122.0841),
                      zoom: 14.0,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _openGoogleMaps(context, contact.address),
                child: Text('Open Google Maps'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final editedContact = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditContactPage(contact: contact),
                    ),
                  );

                  if (editedContact != null) {
                    onEdit(editedContact as Contact);
                  }
                },
                child: Text('Edit'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: onDelete,
                child: Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGoogleMaps(BuildContext context, String address) async {
    if (address.isNotEmpty) {
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$address';
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        print('Could not launch $googleMapsUrl');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Address is empty.'),
        ),
      );
    }
  }
}
