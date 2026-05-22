import 'package:json_annotation/json_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';

part 'donation_model.g.dart';

// TODO why do we have this model and the Product model as well? One seems redundant
@JsonSerializable()
class DonationRequest {
  final String name;
  final String description;
  @JsonKey(name: 'categoryId')
  final String categoryId;
  @JsonKey(name: 'charityId')
  final String charityId;
  final String quality;
  final String size;
  @JsonKey(name: 'postage_size')
  final PostageSize postageSize;
  @JsonKey(name: 'product_images')
  final List<String>? productImages;
  final double donation;
  final double price;
  final int likes;
  final int number;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<XFile>? localImages;

  DonationRequest({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.charityId,
    required this.quality,
    required this.size,
    required this.postageSize,
    required this.donation,
    required this.price,
    this.productImages,
    this.likes = 0,
    this.number = 10,
    this.localImages,
  });

  factory DonationRequest.fromJson(Map<String, dynamic> json) => _$DonationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DonationRequestToJson(this);

  DonationRequest copyWith({
    String? name,
    String? description,
    String? categoryId,
    String? charityId,
    String? quality,
    String? size,
    PostageSize? postageSize,
    double? donation,
    double? price,
    List<String>? productImages,
    int? likes,
    int? number,
    List<XFile>? localImages,
  }) {
    return DonationRequest(
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      charityId: charityId ?? this.charityId,
      quality: quality ?? this.quality,
      size: size ?? this.size,
      postageSize: postageSize ?? this.postageSize,
      donation: donation ?? this.donation,
      price: price ?? this.price,
      productImages: productImages ?? this.productImages,
      likes: likes ?? this.likes,
      number: number ?? this.number,
      localImages: localImages ?? this.localImages,
    );
  }
}

@JsonSerializable()
class DonationResponse {
  final bool success;
  final String message;
  final Product productData;

  DonationResponse({
    required this.success,
    required this.message,
    required this.productData,
  });

  factory DonationResponse.fromJson(Map<String, dynamic> json) => _$DonationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DonationResponseToJson(this);

  String get id => productData.id;
  String? get createdAt => productData.createdAt;
}
