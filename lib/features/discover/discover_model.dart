import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';

final List<DummyCharity> dummyCharities = [
  DummyCharity(
    charityName: "WaterAid",
    description:
        "In a small village in Malawi, WaterAid recently completed the construction of a new well, providing clean, safe drinking water to hundreds of residents. No more long treks for water. No more toxic sources!",
    charityImage: AppImages.discoverImage1,
    charityLogo: AppImages.waterAidLogo,
    likes: 3,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: "WWF",
    description:
        "After years of conservation efforts, WWF announced a rise in sea turtle hatchlings on a beach in Costa Rica! Thanks to beach patrols and community engagement, baby turtles are making their way to the ocean in record numbers. Help them shell-ebrate!",
    charityImage: AppImages.wwf,
    charityLogo: AppImages.wwfLogo,
    likes: 3,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: "Shelter",
    description:
        "Shelter UK helped dozens of families move into secure housing last month. Thanks to their advocacy and support, families now have a place to call home.",
    charityImage: AppImages.shelter,
    charityLogo: AppImages.shelterLogo,
    likes: 3,
    tags: {'smaller-charities'},
  ),
  DummyCharity(
    charityName: "Mind",
    description:
        "The mental health charity Mind has rolled out a series of free community workshops across the UK, reaching over 5,000 people. These sessions equip individuals with tools to manage stress and anxiety.",
    charityImage: AppImages.mind,
    charityLogo: AppImages.mindLogo,
    likes: 3,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'Maudsley Charity',
    description:
        'Maudsley Charity funds improvements and innovation in mental health care across south London. It supports clinical teams, researchers and community organisations working to ensure people experiencing mental illness can access the right care.',
    charityImage: AppImages.placeholderMaudsleyCharity,
    charityLogo: AppImages.maudsleyCharityLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'British Heart Foundation',
    description:
        'British Heart Foundation funds life-saving research into heart and circulatory diseases. It also supports people living with cardiovascular conditions and campaigns for improvements in prevention, diagnosis and treatment.',
    charityImage: AppImages.placeholderBritishHeartFoundation,
    charityLogo: AppImages.britishHeartFoundationLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'West London NHS Charity',
    description:
        'West London NHS Charity raises funds to improve the wellbeing of patients, service users, carers and NHS staff. Donations support projects and improvements that cannot normally be funded through standard NHS budgets.',
    charityImage: AppImages.placeholderWestLondonNhsCharity,
    likes: 0,
    tags: {'smaller-charities', 'local'},
  ),
  DummyCharity(
    charityName: 'Disaster Aid UK & Ireland',
    description:
        'Disaster Aid UK & Ireland provides humanitarian support to communities affected by disasters around the world. Working through Disaster Aid International, it helps fund and deliver practical aid while supporting communities as they recover and rebuild.',
    charityImage: AppImages.placeholderDisasterAidUkIreland,
    charityLogo: AppImages.disasterAidUkIrelandLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'New College Worcester',
    description:
        'New College Worcester is a national residential school and college for young people who are blind or vision impaired. It provides specialist education, independent living skills and support to help students become confident and fulfilled adults.',
    charityImage: AppImages.placeholderNewCollegeWorcester,
    likes: 0,
    tags: {'smaller-charities'},
  ),
  DummyCharity(
    charityName: 'Groundwork',
    description:
        'Groundwork works with communities across the UK to create a fairer and greener future. Its projects improve local green spaces, tackle poverty and inequality, support healthier communities and help people access skills and employment.',
    charityImage: AppImages.placeholderGroundwork,
    charityLogo: AppImages.groundworkLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: "Alzheimer's Society",
    description:
        "Alzheimer's Society supports people affected by dementia with advice and practical guidance. It also funds research and campaigns for lasting change so dementia becomes a priority.",
    charityImage: AppImages.placeholderAlzheimersSociety,
    charityLogo: AppImages.alzheimersSocietyLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'World Animal Protection',
    description:
        'World Animal Protection works globally to end cruelty and create lasting change for animals. It challenges factory farming, opposes the exploitation of wild animals and campaigns for stronger welfare standards.',
    charityImage: AppImages.placeholderWorldAnimalProtection,
    charityLogo: AppImages.worldAnimalProtectionLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'Leicester Animal Aid',
    description:
        'Leicester Animal Aid rescues and rehomes cats and dogs that are lost, abandoned, neglected or unwanted. It also gives owners practical advice and runs support services that help people keep caring for their pets.',
    charityImage: AppImages.placeholderLeicesterAnimalAid,
    charityLogo: AppImages.leicesterAnimalAidLogo,
    likes: 0,
    tags: {'smaller-charities'},
  ),
  DummyCharity(
    charityName: 'British Red Cross',
    description:
        'British Red Cross helps people prepare for, respond to and recover from crises in the UK and overseas. Its humanitarian work includes emergency response, health and care services, and support for refugees and displaced people.',
    charityImage: AppImages.placeholderBritishRedCross,
    charityLogo: AppImages.britishRedCrossLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'UNICEF',
    description:
        "UNICEF UK raises funds for UNICEF's emergency and development work for children worldwide. It also promotes children's rights and helps deliver healthcare, education, nutrition, clean water and protection in emergencies.",
    charityImage: AppImages.placeholderUnicef,
    charityLogo: AppImages.unicefLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'Save the Children',
    description:
        "Save the Children works with families and communities in the UK and around the world to keep children safe, healthy and learning. It provides emergency help and campaigns for lasting improvements to children's lives and rights.",
    charityImage: AppImages.placeholderSaveTheChildren,
    charityLogo: AppImages.saveTheChildrenLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'Prostate Cancer Research',
    description:
        'Prostate Cancer Research funds research to improve survival and find better treatments for prostate cancer. It also works to turn discoveries into real-world diagnostics and treatments while improving access to care.',
    charityImage: AppImages.placeholderProstateCancerResearch,
    charityLogo: AppImages.prostateCancerResearchLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'Macmillan Cancer Support',
    description:
        'Macmillan Cancer Support provides information, practical and emotional support, and services for people living with cancer. It also supports healthcare professionals, researches cancer care and campaigns for better services and fairer access.',
    charityImage: AppImages.placeholderMacmillanCancerSupport,
    charityLogo: AppImages.macmillanCancerSupportLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'RSPCA',
    description:
        'The RSPCA rescues and cares for animals facing cruelty, neglect or urgent need across England and Wales. It rehabilitates and rehomes animals, investigates cruelty, campaigns for stronger laws and works to improve welfare standards.',
    charityImage: AppImages.placeholderRspca,
    charityLogo: AppImages.rspcaLogo,
    likes: 0,
    tags: {'popular'},
  ),
  DummyCharity(
    charityName: 'The Cat Welfare Group',
    description:
        'The Cat Welfare Group rescues stray, abandoned and mistreated cats and kittens on the South Coast. It provides medical treatment before rehoming and neuters feral cats, returning them or finding a suitable new home when needed.',
    charityImage: AppImages.placeholderCatWelfareGroup,
    charityLogo: AppImages.catWelfareGroupLogo,
    logoUsesDarkBackground: true,
    likes: 0,
    tags: {'smaller-charities'},
  ),
];

const dummyProducts = [
  Product(
    userId: "demo-user",
    id: "1",
    name: "Men's Grey Button-up T-Shirt",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "8/Great",
    size: "M",
    postageSizeId: "testid",
    productImages: [
      AppImages.mensTShirt,
      AppImages.mensTShirt,
    ],
    donation: 6.40,
    price: 7.00,
    securityFee: 7.00,
    likes: 8,
    number: 8,
  ),
  Product(
    userId: "demo-user",
    id: "2",
    name: "Shoes",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "6/Good",
    size: "8",
    postageSizeId: "testid2",
    productImages: [
      AppImages.shoes2,
      AppImages.shoes2,
    ],
    donation: 16.00,
    price: 17.00,
    securityFee: 7.00,
    likes: 33,
    number: 8,
  ),
  Product(
    userId: "demo-user",
    id: "3",
    name: "Shoes",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "6/Good",
    size: "8",
    postageSizeId: "testid3",
    productImages: [
      AppImages.shoes2,
    ],
    donation: 17.00,
    price: 17.00,
    securityFee: 7.00,
    likes: 33,
    number: 9,
  ),
  Product(
    userId: "demo-user",
    id: "4",
    name: "Shoes",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "6/Good",
    size: "8",
    postageSizeId: "testid4",
    productImages: [
      AppImages.shoes2,
    ],
    donation: 17.00,
    price: 17.00,
    securityFee: 7.00,
    likes: 33,
    number: 9,
  ),
];
