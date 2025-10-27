import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';

class ShippingAddressWidget extends StatefulWidget {
  final Function(PlaceDetails)? onAddressSelected;
  
  const ShippingAddressWidget({
    super.key,
    this.onAddressSelected,
  });

  @override
  State<ShippingAddressWidget> createState() => _ShippingAddressWidgetState();
}

class _ShippingAddressWidgetState extends State<ShippingAddressWidget> {
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();
  Timer? _debounceTimer;
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _showPredictions = false;
  PlaceDetails? _selectedAddress;
  bool _isAddressConfirmed = false; // New state to track confirmation
  

 final String _apiKey = dotenv.env[AddressConstants.apiKeyEnvVar] ?? '';
  
  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
    _addressFocusNode.addListener(_onFocusChanged);
    
    // Check if API key is available
    if (_apiKey.isEmpty) {
      debugPrint(AddressConstants.apiKeyMissingError);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_addressFocusNode.hasFocus) {
      setState(() {
        _showPredictions = false;
      });
    }
  }

  void _onAddressChanged() {
    // If address is confirmed and user starts typing, reset confirmation
    if (_isAddressConfirmed) {
      setState(() {
        _isAddressConfirmed = false;
        _selectedAddress = null;
      });
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_addressController.text.length > 2 && !_isAddressConfirmed) {
        _searchPlaces(_addressController.text);
      } else {
        setState(() {
          _predictions.clear();
          _showPredictions = false;
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || _isAddressConfirmed || _apiKey.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final String url = 
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_apiKey'
          '&types=${AddressConstants.addressTypeFilter}'
          '&components=${AddressConstants.countryRestriction}';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<dynamic> predictions = data['predictions'];
          setState(() {
            _predictions = predictions
                .map((pred) => PlacePrediction.fromJson(pred))
                .toList();
            _showPredictions = _predictions.isNotEmpty && !_isAddressConfirmed;
            _isLoading = false;
          });
        } else {
          // Handle API error status
          setState(() {
            _isLoading = false;
            _showPredictions = false;
          });
          if (data['status'] != 'ZERO_RESULTS') {
            debugPrint('${AddressConstants.addressSearchError}: ${data['status']}');
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _showPredictions = false;
        });
        debugPrint('${AddressConstants.addressSearchError}: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('${AddressConstants.addressSearchError}: $e');
      setState(() {
        _isLoading = false;
        _showPredictions = false;
      });
    }
  }

  Future<PlaceDetails?> _getPlaceDetails(String placeId) async {
    if (_apiKey.isEmpty) {
      debugPrint(AddressConstants.apiKeyMissingError);
      return null;
    }
    
    try {
      final String url = 
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&key=$_apiKey'
          '&fields=formatted_address,address_components,geometry';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          debugPrint('${AddressConstants.placeDetailsError}: ${data['status']}');
        }
      } else {
        debugPrint('${AddressConstants.placeDetailsError}: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('${AddressConstants.placeDetailsError}: $e');
    }
    return null;
  }

  void _onPredictionTapped(PlacePrediction prediction) async {
    setState(() {
      _addressController.text = prediction.description;
      _showPredictions = false; // Hide dropdown immediately
      _isLoading = true;
    });

    final PlaceDetails? details = await _getPlaceDetails(prediction.placeId);
    
    setState(() {
      _isLoading = false;
      _selectedAddress = details;
      _isAddressConfirmed = details != null; // Mark as confirmed
    });

    // Unfocus the text field to prevent dropdown from showing again
    _addressFocusNode.unfocus();

    if (details != null && widget.onAddressSelected != null) {
      widget.onAddressSelected!(details);
    }
  }

  void _editAddress() {
    setState(() {
      _isAddressConfirmed = false;
      _selectedAddress = null;
      _showPredictions = false;
    });
    // Focus the text field for editing
    _addressFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address input field
        TextField(
          controller: _addressController,
          focusNode: _addressFocusNode,
          readOnly: _isAddressConfirmed, // Make read-only when confirmed
          decoration: InputDecoration(
            hintText: AddressConstants.addressHintText,
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _isAddressConfirmed
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _editAddress,
                        tooltip: AddressConstants.editAddressTooltip,
                      )
                    : null,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _isAddressConfirmed 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _isAddressConfirmed 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          onTap: () {
            if (_predictions.isNotEmpty && !_isAddressConfirmed) {
              setState(() {
                _showPredictions = true;
              });
            }
          },
        ),
        
        // Predictions dropdown - only show when not confirmed
        if (_showPredictions && !_isAddressConfirmed) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return InkWell(
                    onTap: () => _onPredictionTapped(prediction),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: index < _predictions.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prediction.structuredFormatting?.mainText ?? 
                                  prediction.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (prediction.structuredFormatting?.secondaryText != null)
                                  Text(
                                    prediction.structuredFormatting!.secondaryText!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        
        // Selected address confirmation
        if (_isAddressConfirmed && _selectedAddress != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AddressConstants.addressConfirmedTitle,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedAddress!.formattedAddress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _editAddress,
                  child: Text(
                    AddressConstants.editButtonText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Data Models (same as before)
class PlacePrediction {
  final String description;
  final String placeId;
  final StructuredFormatting? structuredFormatting;

  PlacePrediction({
    required this.description,
    required this.placeId,
    this.structuredFormatting,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      structuredFormatting: json['structured_formatting'] != null
          ? StructuredFormatting.fromJson(json['structured_formatting'])
          : null,
    );
  }
}

class StructuredFormatting {
  final String? mainText;
  final String? secondaryText;

  StructuredFormatting({
    this.mainText,
    this.secondaryText,
  });

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'],
      secondaryText: json['secondary_text'],
    );
  }
}

class PlaceDetails {
  final String formattedAddress;
  final List<AddressComponent> addressComponents;
  final double? latitude;
  final double? longitude;

  PlaceDetails({
    required this.formattedAddress,
    required this.addressComponents,
    this.latitude,
    this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final List<AddressComponent> components = [];
    if (json['address_components'] != null) {
      for (var component in json['address_components']) {
        components.add(AddressComponent.fromJson(component));
      }
    }

    double? lat, lng;
    if (json['geometry']?['location'] != null) {
      lat = json['geometry']['location']['lat']?.toDouble();
      lng = json['geometry']['location']['lng']?.toDouble();
    }

    return PlaceDetails(
      formattedAddress: json['formatted_address'] ?? '',
      addressComponents: components,
      latitude: lat,
      longitude: lng,
    );
  }

  // Helper methods to extract specific address components
  String get streetNumber => _getComponent(AddressConstants.streetNumberType);
  String get route => _getComponent(AddressConstants.routeType);
  String get locality => _getComponent(AddressConstants.localityType);
  String get administrativeAreaLevel1 => _getComponent(AddressConstants.administrativeAreaLevel1Type);
  String get postalCode => _getComponent(AddressConstants.postalCodeType);
  String get country => _getComponent(AddressConstants.countryType);

  String _getComponent(String type) {
    try {
      return addressComponents
          .firstWhere((component) => component.types.contains(type))
          .longName;
    } catch (e) {
      return '';
    }
  }
}

class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] ?? '',
      shortName: json['short_name'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }
}
