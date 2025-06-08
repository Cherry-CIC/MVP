import 'dart:io';

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/search_page.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  String? selectedCategory;
  String? selectedCharity;
  bool _newOffers = true;
  XFile? selectedImage;
  String _displayPrice = '£0.00';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<Map<String, dynamic>> categories = [
    {
      'icon': Image.asset(AppImages.global_charity, height: 25, width: 25),
      'label': 'Charities',
      'color': AppColors.selectedTab,

    },
    {
      'icon': Image.asset(AppImages.women),
      'label': 'Women',
      'color': AppColors.selectedTab,

    },
    {
      'icon': Image.asset(AppImages.men),
      'label': 'Men',
      'color': AppColors.selectedTab,
    
    },
    {
      'icon': Image.asset(AppImages.children),
      'label': 'Children',
      'color': AppColors.selectedTab
    },
    {
      'icon': Image.asset(AppImages.accessories),
      'label': 'Accessories',
      'color': AppColors.selectedTab
    },
    {
      'icon': Image.asset(AppImages.unisex),
      'label': 'Unisex',
      'color': AppColors.selectedTab
    },
    {
      'icon': Image.asset(AppImages.designer),
      'label': 'Designer',
      'color': AppColors.selectedTab
    },
    {
      'icon': Image.asset(AppImages.book),
      'label': 'Books',
      'color': AppColors.selectedTab
    },
    {
      'icon': Image.asset(AppImages.toy),
      'label': 'Toys & Board Games',
      'color': AppColors.selectedTab
    },
    {
      'icon': Image.asset(AppImages.cd),
      'label': 'CD\'s & Vinyl',
      'color': AppColors.selectedTab
    },
    {
      'icon': Image.asset(AppImages.dvd),
      'label': 'DVD\'s & Video Games',
      'color': AppColors.selectedTab
    },
  ];
  List<Map<String, dynamic>> charities = [
    {
      'icon': Container(
  width: 89,
  height: 89,
  margin: EdgeInsets.only(right: 10),
  decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(10),
  color: const Color(0xFFE5EBFC),
  border: Border.all(color: AppColors.white, width: 1),
  ),
  child: Image.asset(AppImages.homeStart,  fit: BoxFit.cover),
  ),
      'name': 'Home Start',
  'description': 'Home Start is a local charity that aims to support young single parents of children with difficulties.',


      'color': AppColors.selectedTab,

    },
    {
      'icon': Container(
        width: 89,
        height: 89,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFE5EBFC),
          border: Border.all(color: AppColors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3), // X and Y offset of the shadow
            ),
          ],
        ),

        child: Image.asset(AppImages.Ic_logo, fit: BoxFit.cover),
      ),
      'name': 'Cherry',
      'description': 'cherry is a CIC limited by guarantee; all profits go to supporting the mission, not shareholders.',


      'color': AppColors.selectedTab,

    },
    {
      'icon': Container(
        width: 89,
        height: 89,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFE5EBFC),
          border: Border.all(color: AppColors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3), // X and Y offset of the shadow
            ),
          ],
        ),
        child: Image.asset(AppImages.Ic_water, fit: BoxFit.cover),
      ),

      'name': 'WaterAid',
      'description': 'WaterAid is an international non-governmental organization, focused on wat....',


      'color': AppColors.selectedTab,

    },
    {
      'icon': Container(
        width: 89,
        height: 89,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFE5EBFC),
          border: Border.all(color: AppColors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3), // X and Y offset of the shadow
            ),
          ],
        ),
        child: Image.asset(AppImages.Ic_shelter,  fit: BoxFit.cover),
      ),
      'name': 'Shelter',
      'description': 'Shelter is a registered charity that campaigns for housing justice in England and Scotland',


      'color': AppColors.selectedTab,

    },
    {
      'icon': Container(
        width: 89,
        height: 89,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFE5EBFC),
          border: Border.all(color: AppColors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3), // X and Y offset of the shadow
            ),
          ],
        ),
        child: Image.asset(AppImages.Ic_panda,  fit: BoxFit.cover),
      ),
      'name': 'WWF',
      'description': 'We re WWF, the leading global environmental charity, and we re bringing our world back to life. With nature in freefall, ...',


      'color': AppColors.selectedTab,

    },
    {
      'icon': Container(
        width: 89,
        height: 89,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFE5EBFC),
          border: Border.all(color: AppColors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3), // X and Y offset of the shadow
            ),
          ],
        ),
        child: Image.asset(AppImages.homeStart,  fit: BoxFit.cover),
      ),
      'name': 'The Hunger Project',
      'description': 'The Hunger project is for big boys. We re Mind, the mental health charity. We re here t',


      'color': AppColors.selectedTab,

    },



  ];

  @override
  void initState() {
    super.initState();

    _priceController.addListener(_updateDisplayPrice);
    _titleController.addListener(_onTextFieldChanged);
    _descriptionController.addListener(_onTextFieldChanged);
  }

  @override
  void dispose() {
    _priceController.removeListener(_updateDisplayPrice);
    _titleController.removeListener(_onTextFieldChanged);
    _descriptionController.removeListener(_onTextFieldChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateDisplayPrice() {
    setState(() {
      if (_priceController.text.isEmpty) {
        _displayPrice = '£0.00';
      } else {

        double? price = double.tryParse(_priceController.text);
        if (price != null) {
          _displayPrice= '£${price.toStringAsFixed(2)}';
        } else {
          _displayPrice = '£${_priceController.text}'; // Show raw input if not a valid number yet
        }
      }
    });
  }
  void _onTextFieldChanged() {

    // allowing the prefixIcon to be conditionally shown/hidden.
    setState(() {});
  }

  void _buildCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (context) => _buildCategoryPopup(),
    );
  }
  void _buildCharityBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (context) => _buildCharityPopup(),
    );
  }
  Widget _buildCategoryPopup() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Image.asset(
                    AppImages.Ic_arrowLeft,
                    height: 26,
                    width: 26,
                    color: AppColors.primary,

                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text(
                    'Categories',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                      height: 30/24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Categories list
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: category['icon'],
                    title: Text(
                      category['label'],
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                        height: 31/16,
                        letterSpacing: 0
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.grey2,
                      size: 24,
                    ),
                    onTap: () {
                      setState(() {
                        selectedCategory = category['label'];
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCharityPopup() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Image.asset(
                    AppImages.Ic_arrowLeft,
                    height: 26,
                    width: 29,
                    color: AppColors.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text(
                    'Charities',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                      height: 30/24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            width: double.infinity,
            height: 51,
            decoration: BoxDecoration(
              color: Color(0XFFDFDFDF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: TextField(
              controller: _searchController,
              //onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search items ',
                hintStyle: TextStyle(color: AppColors.greyTextColor),
                prefixIcon:  Image.asset(AppImages.icSearch,height:22.5 ,width: 22.5, color: AppColors.grey1,),
                suffixIcon: Image.asset(AppImages.icCam,height:22.5 ,width: 22.5,),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Categories list
          Expanded(
            child: ListView.builder(
              itemCount: charities.length,
              itemBuilder: (context, index) {
                final charity = charities[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: charity['icon'],
                    title: Text(
                      charity['name'],
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                        height: 31/16,
                        letterSpacing: 0,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          charity['description'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey2,
                            height: 18/13,
                            letterSpacing: 0,
                          ),
                        ),
                        Text(
                          'See More',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primary,
                            height: 18/13,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),

                    onTap: () {
                      setState(() {
                        // Update selectedCharity with the actual name
                        selectedCharity = charity['name'];
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          selectedImage = picked;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> takePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512, // Adjusted to match gallery for consistency, or keep 1024
        maxHeight: 512, // Adjusted to match gallery for consistency, or keep 1024
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          selectedImage = photo; // Assign to single selected image, replacing any existing one
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      // Ensure you have a BuildContext available here
      if (context.mounted) { // Check if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: GoogleFonts.instrumentSans(
            fontWeight: FontWeight.w400,
            height: 31 / 16,
            fontSize: 16,
            letterSpacing: 0,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: SizedBox(
          width: 185,
          height: 36,
          child: Text(
            'Donate an item',
            style: GoogleFonts.instrumentSans(
              textStyle: TextStyle(
                letterSpacing: .5,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 30 / 24,
                color: AppColors.black,
              ),
            ),
          ),
        ),
        leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: 16,
              width: 19,
              child: Center(
                child: Image.asset(
                  AppImages.Ic_cross,
                  height: 16,
                  width: 19,
                ),
              ),
            )),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Upload clear, high-quality images to help your items shine. The more angles the better.',
                style: GoogleFonts.instrumentSans(
                  textStyle: TextStyle(
                    letterSpacing: -0.17,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 27 / 18,
                    color: AppColors.grey2,
                  ),
                ),
              ),
            ),
           //upload image
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {

                if (selectedImage == null) {
                  pickImage();
                } else {
                  ;
                }
              },
              child: Container(
                height: 406,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColors.containerColor,
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: selectedImage != null // Conditional rendering
                    ? ClipRRect( // Clip the image to the container's border radius
                  borderRadius: BorderRadius.circular(28),
                  child: Image.file(
                    File(selectedImage!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                    : Column( // Default upload UI
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library, // Icon for image gallery
                      color: AppColors.grey1,
                      size: 24, // Increased size for better visibility
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload or take new photos',
                      textAlign: TextAlign.center, // Center text if it wraps
                      style: GoogleFonts.instrumentSans(
                        textStyle: TextStyle(
                          letterSpacing: 0,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 20 / 16,
                          color: AppColors.grey1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    //take photo with camera
                    // OutlinedButton.icon(
                    //   onPressed: takePhoto,
                    //   icon: Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: Icon(
                    //       Icons.camera_alt,
                    //       color: AppColors.grey1,
                    //       size: 16,
                    //     ),
                    //   ),
                    //   label: Text(
                    //     '',
                    //     style: GoogleFonts.instrumentSans(
                    //       textStyle: TextStyle(
                    //         letterSpacing: 0,
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w400,
                    //         height: 20 / 16,
                    //         color: AppColors.grey1,
                    //       ),
                    //     ),
                    //   ),
                    //   style: OutlinedButton.styleFrom(
                    //     side: BorderSide.none,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.primary,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 8, top: 8, bottom: 8),
                        child: Icon(
                          Icons.info,
                          color: AppColors.white,
                          size: 25,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Catch eyes by using \nquality photos!',
                          style: GoogleFonts.instrumentSans(
                            textStyle: TextStyle(
                              letterSpacing: 0,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              decorationStyle: TextDecorationStyle.solid,
                              height: 1,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 46, right: 8, top: 8, bottom: 8),
                        child: TextButton(
                          onPressed: () {
                            //implement Nav
                          },
                          child: Text(
                            'Learn How',
                            style: GoogleFonts.instrumentSans(
                              textStyle: TextStyle(
                                letterSpacing: 0,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                decorationStyle: TextDecorationStyle.solid,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.white,
                                height: 1,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  )),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildSectionTitle('Title'),
            ),
        

            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: SizedBox(
                height: 55,
                width: double.infinity,
                child: TextField(
                  controller: _titleController,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight:_titleController.text.isEmpty? FontWeight.w400:FontWeight.w500,
                    height: 36 / 16,
                    letterSpacing: -0.28,
                    color: Colors.black,
                  ),

                 decoration: InputDecoration(
                   prefixIcon: _titleController.text.isEmpty
                       ? Image.asset(
                     AppImages.icAdd,
                     height: 8,
                     width: 8,
                   )
                       : null,
                   hintText: 'e.g. White COS Jumper',
                   hintStyle: TextStyle(color: AppColors.grey1, fontSize: 16, ),

                   contentPadding: const EdgeInsets.only(top: 6, bottom: 2, left: 12, right: 12),

                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(10),
                     borderSide: BorderSide(
                       color:AppColors.grey1,
                       width: 1,
                     ),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(10),
                     borderSide: BorderSide(
                       color: AppColors.grey1,
                       width: 1,
                     ),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(10),
                     borderSide: BorderSide(
                       color: AppColors.grey1,
                       width: 1,
                     ),
                   ),
                   fillColor: AppColors.white,
                   filled: true,
                 ),
                  maxLines: 1,

                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: _buildSectionTitle('Description'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 72,
                width: double.infinity,
                child: TextField(
                  controller: _descriptionController,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: _descriptionController.text.isEmpty?FontWeight.w400:FontWeight.w500,
                    height: 1.2,
                    letterSpacing: 0,
                    color: Colors.black,
                  ),

                 decoration: InputDecoration(
                   prefixIcon: _descriptionController.text.isEmpty
                       ? Image.asset(
                     AppImages.icAdd,
                     height: 8,
                     width: 8,
                   )
                       : null,
                   hintText: 'e.g. only worn a few times, brand x, true to size, no label.',
                   hintStyle: TextStyle(color: AppColors.grey1, fontSize: 16, ),

                   contentPadding: const EdgeInsets.only(top: 6, bottom: 2, left: 12, right: 12),

                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(10),
                     borderSide: BorderSide(
                       color:AppColors.grey1,
                       width: 1,
                     ),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(10),
                     borderSide: BorderSide(
                       color: AppColors.grey1,
                       width: 1,
                     ),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(10),
                     borderSide: BorderSide(
                       color: AppColors.grey1,
                       width: 1,
                     ),
                   ),
                   fillColor: AppColors.white,
                   filled: true,
                 ),
                  maxLines: 6,

                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: _buildCategoryBottomSheet,
                child: Container(
                  height: 55,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xff898989),
                    width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 31 / 16,
                        ),
                      ),
                      selectedCategory != null?
                       Text(
                        selectedCategory ?? '',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 31 / 16,
                        ),
                      ):  Icon(
                        Icons.chevron_right,
                        color: AppColors.grey2,
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: _buildCharityBottomSheet,
                child: Container(
                  height: 55,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xff898989),
                    width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                       'Charity',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 31 / 16,
                        ),
                      ),
                      selectedCharity != null? Text(
                        selectedCharity ?? 'Charity',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 31 / 16,
                        ),
                      ):
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.grey2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                //onTap: _buildCharityBottomSheet,
                child: Container(
                  height: 55,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xff898989),
                    width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Size',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 31 / 16,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_outlined,
                        size: 30,
                        color: AppColors.grey2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //price
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child: Stack( // Use Stack to place the formatted text on top of the TextField
                children: [
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow numbers and decimals

                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 36 / 16,
                      letterSpacing: -0.28,
                      color: _priceController.text.isEmpty ? AppColors.grey1 : AppColors.white, // to make the price disabled according to figma design this need proper function in life app
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                   prefixIcon: Padding(
                     padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8, bottom: 8),
                     child: Text('Price',   style: GoogleFonts.instrumentSans(
                       fontSize: 16,
                       fontWeight: FontWeight.w400,
                       height: 36 / 16,
                       letterSpacing: -0.28,
                     ),),
                   ),


                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.grey1,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.grey1,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.grey1,
                          width: 1,
                        ),
                      ),
                      fillColor: AppColors.white,
                      filled: true,
                    ),
                    maxLines: 1,
                  ),
                  // Overlay Text widget to show the formatted value
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _displayPrice,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,

                            height: 1.0,
                            letterSpacing: -0.28,
                            color: _priceController.text.isEmpty ? AppColors.grey1 : Colors.black, // Grey for "£0.00", black for input
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                //onTap: _buildCharityBottomSheet,
                child: Container(
                  height: 55,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xff898989),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Condition',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 31 / 16,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_outlined,
                        size: 30,
                        color: AppColors.grey2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                //onTap: _buildCharityBottomSheet,
                child: Container(
                  height: 55,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xff898989),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add to Collection',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.grey1,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          height: 31 / 16,
                        ),
                      ),
                      Icon(
                        Icons.add,
                        size: 30,
                        color: AppColors.grey2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Donation Options',

              style: GoogleFonts.instrumentSans(
                color:AppColors.grey2,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.17,
                height: 31 / 16,
              )
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8),
              child: Text('Give your buyer the option pick a cause they care about. its an easy way to make your listing more impactful.',

              style: GoogleFonts.instrumentSans(
                color:AppColors.grey2,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.17,
                height: 31 / 16,
              )
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                //onTap: _buildCharityBottomSheet,
                child: Container(
                  height: 61,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Color(0xff898989),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Open to other charities',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.grey1,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.17,
                          height: 31 / 18,
                        ),
                      ),
                      Switch(value: _newOffers, onChanged: (bool value){
                        setState(() {
                          _newOffers = value;
                        });
                      },
                        activeColor: AppColors.grey2,
                        activeTrackColor: AppColors.grey2,
                        inactiveThumbColor: AppColors.white,
                        thumbColor: MaterialStateProperty.all(AppColors.white),


                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                //onTap: _buildCharityBottomSheet,
                child: Container(
                  height: 61,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Color(0xff898989),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Open to offers',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.grey1,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.17,
                          height: 31 / 18,
                        ),
                      ),
                      Switch(value: _newOffers, onChanged: (bool value){
                        setState(() {
                          _newOffers = value;
                        });
                      },
                        activeColor: AppColors.grey2,
                        activeTrackColor: AppColors.grey2,
                        inactiveThumbColor: AppColors.white,
                        thumbColor: MaterialStateProperty.all(AppColors.white),


                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                //onTap: _buildCharityBottomSheet,
                child: Container(
                  height: 61,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Color(0xff898989),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Applicable for buyer discounts',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.grey1,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.17,
                          height: 31 / 18,
                        ),
                      ),
                     Switch(value: _newOffers, onChanged: (bool value){
                       setState(() {
                         _newOffers = value;
                       });
                     },
                       activeColor: AppColors.grey2,
                       activeTrackColor: AppColors.grey2,
                       inactiveThumbColor: AppColors.white,
                       thumbColor: MaterialStateProperty.all(AppColors.white),


                     )
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 197,
                      height: 60,

                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.primary,
                            width: 2),
                      ),
                      child: Center(
                        child: Text('Back',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.17,
                          height: 21 / 18,
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(


                      width: 197,
                      height: 60,

                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.primary,
                            width: 2),
                      ),
                      child: Center(
                        child: Text('Next',
                        style: GoogleFonts.instrumentSans(
                          color:AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.17,
                          height: 21 / 18,
                        ),
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),


            SizedBox(height: 20,),








          ],
        ),
      ),
    );
  }



}
