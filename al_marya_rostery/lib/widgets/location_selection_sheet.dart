import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../providers/location_provider.dart';
import '../models/saved_address.dart';
import 'add_address_sheet.dart';

class LocationSelectionSheet extends StatefulWidget {
  const LocationSelectionSheet({super.key});

  @override
  State<LocationSelectionSheet> createState() => _LocationSelectionSheetState();
}

class _LocationSelectionSheetState extends State<LocationSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Initialize address provider if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with search toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Select Location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchController.clear();
                        context.read<AddressProvider>().clearSearch();
                      }
                    });
                  },
                  icon: Icon(_showSearch ? Icons.close : Icons.search),
                ),
              ],
            ),
          ),

          // Search box (animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSearch ? 60 : 0,
            child: _showSearch
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        context.read<AddressProvider>().searchAddresses(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for your building or street',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<AddressProvider>().clearSearch();
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFA89A6A),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Use current location option
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA89A6A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    locationProvider.hasError
                        ? Icons.location_off
                        : Icons.my_location,
                    color: locationProvider.hasError
                        ? Colors.red
                        : const Color(0xFFA89A6A),
                  ),
                ),
                title: const Text('Use current location'),
                subtitle: Text(
                  locationProvider.hasError
                      ? 'Location unavailable'
                      : locationProvider.getDisplayLocation(),
                ),
                trailing: locationProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: locationProvider.hasError
                    ? null
                    : () {
                        // Use current location
                        Navigator.of(context).pop();
                        // The existing location will be used
                      },
              );
            },
          ),

          const Divider(),

          // Add new address option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFA89A6A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_location, color: Color(0xFFA89A6A)),
            ),
            title: const Text(
              '+ Add new address',
              style: TextStyle(
                color: Color(0xFFA89A6A),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Open map to drop pin and select place'),
            onTap: () {
              Navigator.of(context).pop();
              _showAddAddressSheet(context);
            },
          ),

          const Divider(),

          // Saved addresses section
          Expanded(
            child: Consumer<AddressProvider>(
              builder: (context, addressProvider, child) {
                if (addressProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (addressProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          addressProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: addressProvider.refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final addresses = addressProvider.filteredAddresses;

                if (addresses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showSearch && _searchController.text.isNotEmpty
                              ? 'No addresses found'
                              : 'No saved addresses',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showSearch && _searchController.text.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add your first address to save time',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Saved Addresses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          final isSelected = addressProvider.isAddressSelected(
                            address,
                          );
                          final isDefault = addressProvider.isAddressDefault(
                            address,
                          );

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: address.type == AddressType.home
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : address.type == AddressType.work
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                address.type.icon,
                                color: address.type == AddressType.home
                                    ? Colors.blue
                                    : address.type == AddressType.work
                                    ? Colors.orange
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    address.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFA89A6A,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFA89A6A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              address.shortAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFA89A6A),
                                  )
                                : PopupMenuButton(
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'default',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isDefault
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isDefault
                                                  ? 'Remove default'
                                                  : 'Set as default',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'default') {
                                        if (!isDefault) {
                                          await addressProvider
                                              .setDefaultAddress(address);
                                        }
                                      } else if (value == 'delete') {
                                        await addressProvider.deleteAddress(
                                          address.id,
                                        );
                                      }
                                    },
                                  ),
                            onTap: () {
                              addressProvider.selectAddress(address);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAddressSheet(),
    );
  }
}
