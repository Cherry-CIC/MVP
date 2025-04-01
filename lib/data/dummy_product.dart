import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/product_carousel.dart';

const dummyProduct = [
  ProductCarousel(
    image: "https://media-hosting.imagekit.io/deff61e388004a9f/charity_product1.jpg?Expires=1838030012&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=fNDFss1WWNslA9J7mO8n74AVkF-~vAI8P7DldUz~83Evj6BbQ442-QKWO7ksEncfka5YgF9QkzA6PuTezFIxfnY2Cv~W-oBvLGnzvSh4KhWv4eMTD5asgTp97U1anIVOp4XpDoIUVhkblEf-3ktVTPFEviWZ6BE7w5r9wDwsCdptRKwAQ2axyaC8P7N0ADtfVZbdKzUV9DLTSYxjbsb0bFoJ9XT064~Izeejbij3WmXXHxwhC8EF3zYO5~p5i-7z0i3oDNavexq7zLSg8FgdzsO-Nh~QLWgSQaKcSoenpdqSKr6dTS7k118TEV4YWUYyP4usMilk7L0d8g37aioaNA__",
    charityLogo: "https://media-hosting.imagekit.io/a28f6b7d21f745ce/logo_save_children.png?Expires=1838026666&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=tCLf-6g~~U5htLpuSEBJ0PRwPF703YQLz1PNI~K6dv5WFBURsINJSdu1dLbvqra9kbrifK61b9d9E5skgj4teXtO89YYvENGweWrSqJkMRCJk8DqvAbL4hnjsJqVYr9rbQHHqEnnU0VLD6uXosttDCPPWIQKxkq93gIFaxqN44dP8fHNOGeliQkbV-s8TphANUjoziJbOtawZGUaQTmhEJ-VOf5cPOWt~8eVhYUjGFMra9nK4~sOUlz8Dnq0Aa5IMCE4H-yy0vXrfRFjJSwdYP6p~PJ-UJ-EgE1aL2MLtzb2S2ywqVe2JRJfrct4hudzt3PmAPKqaEX~2-2zOlDGXg__",
    numberLikes: 50,
    price: 6,
    numberIndexes: 8,
    description: "Baggie Beige Men's Button Shirt",
    size: 'M'
  ),

  ProductCarousel(
    image: "https://media-hosting.imagekit.io/dfbbfde7175441db/charity_product2.jpg?Expires=1838030687&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=u3pWq22~JXvbx0-lb4MD8aGOs~k9feE8GA1QmXAWASaPAzmfQnmbOhmSuVpkW3ZJ5YAq2zPfrQRiq13Noj3Y6duYYte1br9q~bAbbPnN7AKuatvAuFVp6pAKnVB6WN9PomaNQaMu2KmHmYvfSwQyChxVYQ3peHn2aYstKboLHJj1koOPDZNH81a-AWv7fHsrqIZPbI16t2KxKXdy2AZi4v3JdXysPhTFs7FWCZUlKkdq88r-v1-jUPB5Gepu5A4VHRoR2r~VQvphFMZ46hR7RTLVXYkLsrIUfAo9WVY2JaXSnIzMrIC4GJkDzCa26rlK0X2HNRImYIJtbOdmVdhUkw__",
    charityLogo: "https://media-hosting.imagekit.io/d573b210a83a4114/logo_age_uk.png?Expires=1838030737&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=PfevwSL~3gmFNk29gyamXRRrc6V5g73-osjTIooRTkJMOvLM5CdzY08BQi9stJbnD6~nSKEt~BMkLjK~mk7Gq9815GVwAivtcrzkE-9ZXYjmpyIezd1fBmDpxwHg5gWM2cbvDWUsPkZEf2hSSbIOpfhJqurHlOg5H5Ip63D64VNgb1EmdaApJigt6iaORw5ptiTahudYRYkCHtZa0YoJMrYiL6khpvHTwvI8AYv7tD8F1z6p3lH4xkQjId1qAzv96Oy-dWhjU4Y-iJOuscUGzwH7IuhcUbLJVrm1W9V6Uk-8~oZoVSAUifCOVbs2Leq0rkQhbRZ8Jz6DbuMdEEWPhA__",
    numberLikes: 60,
    price: 8,
    numberIndexes: 10,
    description: "Blue Mens Long-Steeved Polo",
    size: 'M'
  ), 

  ProductCarousel(
    image: "https://media-hosting.imagekit.io/55b4597117cc460e/charity_product3.jpg?Expires=1838030868&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=d5giMLS6C7F0SkAl2wDgMFbU3oatSCWDidcOiip9bjZIYs1JfMRRDYcQ66h3zWq3Tlm5wrxJmMnvWc3JUI3B-60-X6jvJvmpV1k1lvr5NI6bOzhecCR-6-VGZNfptgEeMGSWWYi7~H-UsXbSE4lifeL7ke4Ej3LuIyRtjJxVj7vUOeo8FDvODt-Z4CPXdEt6sbIogMjBkG3DuYSzGV5SjU1LzAsNO8gq1e6mdxxbVSsplWfEPipgfTgPn2KV6FzcDgvJAmlj3C0vipKSgPOmFi6DVijZ~ri0PIoQmT6ETC0ejKVAH4NbyQu5e0hj0xOTA2WHJ-jB6P6UUJS62BrxSw__",
    charityLogo: "https://media-hosting.imagekit.io/c0bd0ad6efd04b0d/logo_british_heart_foundation.jpg?Expires=1838030915&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=kLTeJXtzlq9d0MC~FcKyucslvxd9XVqWz-aixZMKXGIC9FSPWC4ozgMZg3JTwqE5gzTGDyK7SOtJZH91zt9WGUE3uxuVaJco~Ut4E7ojYwzRmBsxIc2ai~kvftL9-spOJW2Eiy67T~Qf3ksYgZkTiBLl45vZ~gX9FbXui8fJ-n9g0X3VXzN7La-ueqH1Pcn7vsp05XrBKKbYe65WzarrqogFhuKN7MRUhFNFNNwuhNZ646gqP39c06KbvpONwbRZC-~0FLjg-NAZhyJ7aDwuIZQTjr~pnb4C71K-hdqvMS9GtHffE3eD4uRPJVAKGWATAlAA-v-9wU7psWBzOeexBA__",
    numberLikes: 10,
    price: 50,
    numberIndexes: 5,
    description: "Patterned Long-Steeved Shirt Men's",
    size: 'M'
  ), 

  ProductCarousel(
    image: "https://media-hosting.imagekit.io/70c2536fdd6246df/clothing_4.png?Expires=1838031227&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=bPHSji3xudNlYqF4NvPlMty9lJOASUk-iNWZe3JuCKdn2F-cy~~BPsLISnUNnzYNF~xGC66UoxvxErgdiYCYjaUFilSSSEgaTrQIEr6Wj6XFHJUqRK4z3PdE0xBD2bRC1IanhWXGxSHzUgxqH5~YABnHrVwSzQwYqNqgGDBlVszBJIcTVBWQFyHoU27bM9B5l88Ks4sMOqMzAGNg4H1qWS2c9mereEGZzr21htYQ137ekqNiRmuq0vXGQibUqE8xjoYcWgkKZwkfF2LWch6xDjgyptFtnQtjLbyTHqhkZJNjbQngod7VFfNDA4vFPQPLF8NqrKTUd8U2OlHF4cfEWg__",
    charityLogo: "https://media-hosting.imagekit.io/f43b5f3f13a84507/logo_one_nation.png?Expires=1838031271&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=vmXl4gI8G~6Su4UxigcMVwNHtOmKEO42KiXApr6GCjwA5oJeAUTwhQsGV4-TpGIJzl03IljR1ydefmkBCiihTccDk970B9lk9-9GhGHGVByEl0QAPq-KxjQg4ZDTdS7lMrV7DUyelMHOkXkfTgQlBnQBS24bjA3YAkIhfjWahliFDUabpSHbghSTO~kJ6ll1vrFNPJ9~ucn9~AZTY06orVEr6LGOJ1CnGyKeG9ZxmjGnAUwYAV5ThvWrJTdjd0moktk-fd8tPSkO8bje6CaRiA5FJ0ssvHihCcw~0Z7XDKRyJPQtMU~kOBrmqA6d-pxEFRUdw8V3z29QBP~6BNOlqg__",
    numberLikes: 50,
    price: 14,
    numberIndexes: 7,
    description: "Patterned Long-Steeved Shirt Men's",
    size: 'S'
  ), 

  ProductCarousel(
    image: "https://media-hosting.imagekit.io/b1aaf9ca8c904cb2/charity_product5.jpg?Expires=1838031346&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=wKsgW3e0RE3MtFbe4lxBJOPlICZ3HxW1qu-BulE2SGvD-EJYE8KRwhemECXg-r7tYFEKCrH8Mxs-DF0qViCJxfSzIC7acusioQS6XZ3D1X-Lc~1Bm4h9RgiEwPlp~o4EAg9l0g9Pdq0G3qEdt-fZ1lkUo~cshmZwH9ky2MJsPal~VV4rkiNxG5j9IZFuH-37W8UGEEtFnbLmaH4tvYvJoolyqtM4J~W8XQBbGndSKh~RbZjxboTjWQRjut38zHA5gqpHXTrc9tvl3dJ5-e~iPpl8qctWUmYkCZXbVKNc7T~pW8Hjzav~WaajpikCCBvX~3LXYAzPv628Jj~dHTceBA__",
    charityLogo: "https://media-hosting.imagekit.io/3063901b665041e9/logo_red_cross.png?Expires=1838031384&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=BILub2JXe9r9dsP42NMFYSNNN~zrJZIM~moSYfL7TTlFzS8hpmZMzvwEFC-BZtJqLTdAtTBGEM2lL6ZZXGmrzcjapbKd1-3BJ2~I9ZdTQutsalt3GgLrrzysqf4FnNgvTDg8Xe8OB2V09dSw4hURqdcDvBEOxoz5A0HFAe-WHzL0q~CRpw2SiXrt5G4KExrd202DATp4yTFGmGPOzrHfwbod84~zgMIbmkw9ul2RHcpOdsvCb1vBNrEIf-84YrCIi1LGEn9ann5LeqFSRSmdWjqQwStVA8hXcALkSHyKBh-bk6uk~jTP2PLoQYJSIVVlQkY6MWYocVPrbAEfGw49Uw__",
    numberLikes: 90,
    price: 11,
    numberIndexes: 12,
    description: "Patterned Long-Steeved Shirt Men's",
    size: 'X'
  ), 
];
