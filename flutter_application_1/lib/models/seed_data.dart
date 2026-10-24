import '../models/restaurant.dart';
import '../models/food.dart';
import '../models/review.dart';

final kDefaultRestaurants = <Restaurant>[
  Restaurant(
    id: 'resto_1',
    name: 'Gudeg Yu Djum Wijilan',
    category: 'Restoran',
    address: 'Jl. Wijilan No. 167, Panembahan, Kraton, Yogyakarta',
    province: 'DIY',
    lat: -7.8004,
    lng: 110.3667,
    priceMin: 20000,
    priceMax: 45000,
    openingHours: '06:00 - 21:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1551266080-616f5d8174f1?auto=format&fit=crop&w=900&q=85',
    phone: '081227000167',
    website: 'https://gudegyudjum.com',
    createdAt: DateTime(2025, 1, 1),
    rating: 4.9,
    reviewCount: 1284,
    description:
        'Restoran gudeg legendaris yang telah berdiri sejak 1950-an dengan resep turun-temurun. '
        'Krecek pedasnya yang khas dan areh santannya yang kental menjadi daya tarik utama '
        'wisatawan kuliner Keraton. Berlokasi di kampung Wijilan yang terkenal sebagai sentra gudeg Jogja.',
  ),
  Restaurant(
    id: 'resto_2',
    name: 'Mangut Lele Asap Mbah Marto',
    category: 'Warung Tradisional',
    address: 'Dusun Tiwir, Sewon, Bantul, DIY',
    province: 'DIY',
    lat: -7.8383,
    lng: 110.3582,
    priceMin: 25000,
    priceMax: 35000,
    openingHours: '08:00 - 15:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=85',
    phone: '081328000456',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.8,
    reviewCount: 876,
    description:
        'Warung lele asap kayu klampok khas Bantul disiram kuah santan cabai rawit yang pedas gurih. '
        'Dimasak di dapur pawon tradisional dengan kayu bakar pilihan setiap harinya. '
        'Mbah Marto telah mewariskan resep rahasia ini kepada generasi ketiga keluarganya.',
  ),
  Restaurant(
    id: 'resto_3',
    name: 'Soto Bathok Mbah Katro',
    category: 'Warung Tradisional',
    address: 'Jl. Candi Sambisari, Kalasan, Sleman, DIY',
    province: 'DIY',
    lat: -7.7555,
    lng: 110.4609,
    priceMin: 8000,
    priceMax: 15000,
    openingHours: '06:00 - 14:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1762754104506-eaa04386106f?auto=format&fit=crop&w=900&q=85',
    phone: '081568000789',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.7,
    reviewCount: 542,
    description:
        'Warung saung tradisional di tepi sawah Sambisari yang menyajikan soto kuah bening segar dalam batok kelapa asli. '
        'Irisan daging sapi empuk dengan tempe garit renyah menjadi sajian sarapan favorit warga Kalasan.',
  ),
  Restaurant(
    id: 'resto_4',
    name: 'Bakmi Jawa Mbah Gito',
    category: 'Restoran',
    address: 'Jl. Kemasan, Kotagede, Yogyakarta',
    province: 'DIY',
    lat: -7.8168,
    lng: 110.3986,
    priceMin: 20000,
    priceMax: 35000,
    openingHours: '16:00 - 23:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1752924349515-761435ec22b3?auto=format&fit=crop&w=900&q=85',
    phone: '081804000321',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.8,
    reviewCount: 934,
    description:
        'Restoran bakmi Jawa arang bernuansa rumah kayu etnik paling legendaris di Kotagede. '
        'Kuah kaldu ayam kampung kental dengan telur bebek rebus menjadi ciri khas yang tak terlupakan.',
  ),
  Restaurant(
    id: 'resto_5',
    name: 'Kopi Joss Lik Man',
    category: 'Angkringan',
    address: 'Stasiun Tugu, Jl. Mangkubumi, Yogyakarta',
    province: 'DIY',
    lat: -7.7891,
    lng: 110.3617,
    priceMin: 5000,
    priceMax: 15000,
    openingHours: '18:00 - 02:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1700955004555-900a9733ee14?auto=format&fit=crop&w=900&q=85',
    phone: '081705000654',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.7,
    reviewCount: 2103,
    description:
        'Angkringan ikonik wisata malam Jogja sejak 1960-an di dekat Stasiun Tugu. '
        'Kopi tubruk robusta yang dicelupkan arang kayu membara menghasilkan aroma karamel smoky yang khas.',
  ),
  Restaurant(
    id: 'resto_6',
    name: 'Oseng Mercon Bu Narti',
    category: 'Warung Tradisional',
    address: 'Jl. KH. Ahmad Dahlan, Ngampilan, Yogyakarta',
    province: 'DIY',
    lat: -7.7951,
    lng: 110.3571,
    priceMin: 25000,
    priceMax: 35000,
    openingHours: '17:00 - 23:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1626200419199-391ae4be7a41?auto=format&fit=crop&w=900&q=85',
    phone: '081906000987',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.6,
    reviewCount: 673,
    description:
        'Warung tenda malam legendaris yang menyajikan oseng koyor sapi dengan racikan cabai rawit pedas meledak. '
        'Menjadi kebanggaan kuliner malam warga Jogja selama puluhan tahun.',
  ),
  Restaurant(
    id: 'resto_7',
    name: 'Bakmi Jawa Pak Pale',
    category: 'Warung Tradisional',
    address: 'Alun-alun Utara, Kraton, Yogyakarta',
    province: 'DIY',
    lat: -7.8038,
    lng: 110.3641,
    priceMin: 22000,
    priceMax: 30000,
    openingHours: '17:00 - 00:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=900&q=85',
    phone: '081207000123',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.7,
    reviewCount: 445,
    description:
        'Warung tenda bakmi Jawa nyemek dengan bumbu bawang putih khas dapur Kraton. '
        'Disajikan malam hari di bawah pohon beringin Alun-alun Utara dengan aroma tungku arang yang khas.',
  ),
  Restaurant(
    id: 'resto_8',
    name: 'Sate Klatak Pak Pong',
    category: 'Restoran',
    address: 'Jl. Imogiri Timur, Bantul, DIY',
    province: 'DIY',
    lat: -7.8714,
    lng: 110.3830,
    priceMin: 30000,
    priceMax: 55000,
    openingHours: '10:00 - 22:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1751212352288-d5811798804c?auto=format&fit=crop&w=900&q=85',
    phone: '081308000456',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.9,
    reviewCount: 1567,
    description:
        'Restoran sate kambing muda paling ikonik di Bantul. Dipanggang di atas jeruji besi sepeda '
        'dengan bumbu garam dan kuah gulai gurih tanpa kecap yang legendaris.',
  ),
  Restaurant(
    id: 'resto_9',
    name: 'Warung Nasi Pecel Bu Wiryo',
    category: 'Warung Tradisional',
    address: 'Pasar Kranggan, Jl. Tentara Rakyat, Yogyakarta',
    province: 'DIY',
    lat: -7.7942,
    lng: 110.3659,
    priceMin: 8000,
    priceMax: 18000,
    openingHours: '05:30 - 10:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=900&q=85',
    phone: '081509000234',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.6,
    reviewCount: 389,
    description:
        'Warung pecel sarapan paling ramai di kawasan Pasar Kranggan. Sambal kacang kental dengan pilihan lauk '
        'tempe goreng panas dan empal gurih yang menggugah selera.',
  ),
  Restaurant(
    id: 'resto_10',
    name: 'Tengkleng Gajah Bu Hj. Bejo',
    category: 'Restoran',
    address: 'Jl. Brigjen Katamso No. 57, Mergangsan, Yogyakarta',
    province: 'DIY',
    lat: -7.8089,
    lng: 110.3654,
    priceMin: 35000,
    priceMax: 75000,
    openingHours: '10:00 - 20:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1695658519636-5fc41203df9a?auto=format&fit=crop&w=900&q=85',
    phone: '081410000567',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.5,
    reviewCount: 298,
    description:
        'Restoran tengkleng kambing porsi besar dengan kuah rempah gulai medhok dan tulang sumsum lezat. '
        'Tempat makan nyaman yang cocok dikunjungi bersama rombongan dan keluarga.',
  ),
  Restaurant(
    id: 'resto_11',
    name: 'Es Dawet Ibu Titi',
    category: 'Warung Tradisional',
    address: 'Malioboro, Jl. Malioboro No. 1, Gedongtengen, Yogyakarta',
    province: 'DIY',
    lat: -7.7927,
    lng: 110.3658,
    priceMin: 5000,
    priceMax: 12000,
    openingHours: '09:00 - 20:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=900&q=85',
    phone: '081211000890',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.5,
    reviewCount: 756,
    description:
        'Kedai minuman tradisional legendaris di selasar Malioboro. Dawet ayu dengan cendol pandan wangi, '
        'santan kelapa segar, dan sirup gula kelapa asli khas Mataraman.',
  ),
  Restaurant(
    id: 'resto_12',
    name: 'Ayam Goreng Mbah Cemplung',
    category: 'Restoran',
    address: 'Desa Geneng, Pendowoharjo, Sewon, Bantul, DIY',
    province: 'DIY',
    lat: -7.8451,
    lng: 110.3493,
    priceMin: 30000,
    priceMax: 50000,
    openingHours: '10:00 - 21:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=900&q=85',
    phone: '081312000345',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.8,
    reviewCount: 1102,
    description:
        'Restoran rumah tradisional di Bantul yang terkenal dengan teknik goreng cemplung dalam kuali tanah liat. '
        'Ayam kampung empuk berbumbu rempah gurih disajikan dengan sambal terasi dan lalapan segar.',
  ),
  Restaurant(
    id: 'resto_fastfood_1',
    name: 'Olive Fried Chicken Gejayan',
    category: 'Fast Food',
    address: 'Jl. Affandi No. 24, Caturtunggal, Depok, Sleman, DIY',
    province: 'DIY',
    lat: -7.7712,
    lng: 110.3892,
    priceMin: 12000,
    priceMax: 28000,
    openingHours: '09:00 - 21:30 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=900&q=85',
    phone: '081229000111',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.8,
    reviewCount: 3421,
    description:
        'Fast food ayam goreng tepung lokal legendaris kebanggaan mahasiswa dan warga Jogja sejak 2011. '
        'Kulitnya renyah krispi dengan bumbu gurih meresap dan harga yang sangat bersahabat di kantong.',
  ),
  Restaurant(
    id: 'resto_foodcourt_1',
    name: 'Food Court Pasar Kranggan (Lt. 2)',
    category: 'Food Court',
    address: 'Lantai 2 Pasar Kranggan, Jl. Poncowinatan, Gowongan, Jetis, Yogyakarta',
    province: 'DIY',
    lat: -7.7828,
    lng: 110.3664,
    priceMin: 15000,
    priceMax: 45000,
    openingHours: '10:00 - 22:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=900&q=85',
    phone: '081329000222',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.7,
    reviewCount: 1890,
    description:
        'Sentra kuliner modern dan food court hits di lantai atas pasar tradisional Kranggan. '
        'Menyajikan puluhan tenant makanan dari artisan noodle, pastry, kopi, hingga kuliner nusantara.',
  ),
  Restaurant(
    id: 'resto_cafe_1',
    name: 'Klinik Kopi Kaliurang',
    category: 'Cafe',
    address: 'Jl. Kaliurang KM 7.8, Sinduharjo, Ngaglik, Sleman, DIY',
    province: 'DIY',
    lat: -7.7342,
    lng: 110.3951,
    priceMin: 20000,
    priceMax: 40000,
    openingHours: '08:00 - 20:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=900&q=85',
    phone: '081392000333',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.9,
    reviewCount: 2450,
    description:
        'Kafe kopi spesialti legendaris yang mengedukasi pengunjung tentang varietas biji kopi Nusantara. '
        'Suasana tenang dengan konsep cerita kopi di setiap seduhan.',
  ),
  Restaurant(
    id: 'resto_restoran_1',
    name: 'Bale Raos Keraton Yogyakarta',
    category: 'Restoran',
    address: 'Jl. Magangan Kulon No. 1, Panembahan, Kraton, Yogyakarta',
    province: 'DIY',
    lat: -7.8080,
    lng: 110.3620,
    priceMin: 35000,
    priceMax: 90000,
    openingHours: '10:00 - 21:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1631795617958-3ddcf718d6aa?auto=format&fit=crop&w=900&q=85',
    phone: '0274415565',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.7,
    reviewCount: 1620,
    description:
        'Restoran autentik yang menyajikan hidangan kesukaan Sri Sultan Hamengku Buwono terdahulu. '
        'Suasana pendopo ningrat kraton yang anggun dengan resep kerajaan warisan Mataraman.',
  ),
];

final kDefaultFoods = <String, List<Food>>{
  'resto_fastfood_1': [
    Food(
      id: 'food_ff_1',
      restaurantId: 'resto_fastfood_1',
      name: 'Paket Sayap + Nasi + Es Teh',
      description:
          '1 potong sayap ayam krispi bumbu gurih rempah khas Olive dengan nasi pulen hangat dan es teh manis',
      price: 15000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_ff_2',
      restaurantId: 'resto_fastfood_1',
      name: 'Paket Paha Atas Krispi',
      description:
          '1 potong paha atas ayam goreng tepung renyah beraroma gurih renyah dengan sambal khas',
      price: 18000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_ff_3',
      restaurantId: 'resto_fastfood_1',
      name: 'Ayam Geprek Sambal Korek Olive',
      description:
          'Ayam krispi digeprek dengan ulekan cabai rawit pedas gurih bawang putih',
      price: 20000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_ff_4',
      restaurantId: 'resto_fastfood_1',
      name: 'Burger Ayam Krispi',
      description:
          'Burger dengan patty fillet ayam krispi tebal, selada segar, dan saus mayones khas',
      price: 16000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_ff_5',
      restaurantId: 'resto_fastfood_1',
      name: 'French Fries Bumbu Gurih',
      description:
          'Kentang goreng stik renyah garing keemasan dengan taburan bumbu rempah gurih',
      price: 12000,
      category: 'Camilan',
      imageUrl:
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_foodcourt_1': [
    Food(
      id: 'food_fc_1',
      restaurantId: 'resto_foodcourt_1',
      name: 'Mie Kering Chili Oil Tjap 1000 Tahun',
      description:
          'Mie kenyal racikan khas Pasar Kranggan dengan chili oil aromatik, ayam cincang, dan pangsit renyah',
      price: 26000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_fc_2',
      restaurantId: 'resto_foodcourt_1',
      name: 'Pain Au Chocolat Bake Me to The Moon',
      description:
          'Pastry butter Prancis renyah berlapis dengan isian cokelat Belgia pekat lumer',
      price: 22000,
      category: 'Camilan',
      imageUrl:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_fc_3',
      restaurantId: 'resto_foodcourt_1',
      name: 'Dimsum Siomay Mentai Bakar',
      description:
          '4 buah dimsum siomay daging udang ayam tebal dengan siraman saus mentai bakar torched gurih creamy',
      price: 24000,
      category: 'Camilan',
      imageUrl:
          'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_fc_4',
      restaurantId: 'resto_foodcourt_1',
      name: 'Es Kopi Susu Gula Aren Kranggan',
      description:
          'Espresso house blend robusta arabika dengan susu segar creamy dan gula aren organik',
      price: 18000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_cafe_1': [
    Food(
      id: 'food_cafe_1',
      restaurantId: 'resto_cafe_1',
      name: 'V60 Single Origin Wamena Enade',
      description:
          'Kopi seduh manual V60 arabika Papua Wamena dengan aroma melati segar, apel merah, dan aftertaste bersih',
      price: 35000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_cafe_2',
      restaurantId: 'resto_cafe_1',
      name: 'Kopi Tubruk Bajawa Flores',
      description:
          'Kopi tubruk aromatik dataran tinggi Flores dengan body kental mantap serta sentuhan cokelat karamel',
      price: 30000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_cafe_3',
      restaurantId: 'resto_cafe_1',
      name: 'Single Origin Temanggung Darma',
      description:
          'Manual brew biji Temanggung proses natural dengan sensasi rasa manis madu alami dan buah berry segar',
      price: 35000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_cafe_4',
      restaurantId: 'resto_cafe_1',
      name: 'Orange Tart Artisan Pastry',
      description:
          'Tart renyah buatan artisan dengan krim custard citrus segar pendamping seduhan kopi',
      price: 28000,
      category: 'Camilan',
      imageUrl:
          'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_cafe_5',
      restaurantId: 'resto_cafe_1',
      name: 'Cold Drip Filter Reserve',
      description:
          'Ekstraksi tetesan kopi dingin selama 12 jam menghasilkan karakter rasa kopi bersih yang intens menyegarkan',
      price: 38000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_restoran_1': [
    Food(
      id: 'food_resto_1',
      restaurantId: 'resto_restoran_1',
      name: 'Bistik Jawa Keraton',
      description:
          'Hidangan favorit Sri Sultan Hamengku Buwono VIII berupa bistik lidah/daging sapi empuk saus rempah pala manis dengan selada wortel buncis',
      price: 68000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_resto_2',
      restaurantId: 'resto_restoran_1',
      name: 'Bebek Suwar-Suwir Saus Kedondong',
      description:
          'Daging bebek suwir empuk bumbu rempah gurih khas Keraton dengan siraman saus asam segar buah kedondong asli',
      price: 62000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1514944298352-78d4924c5b2a?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_resto_3',
      restaurantId: 'resto_restoran_1',
      name: 'Gecok Ganem Daging Sapi',
      description:
          'Bulatan daging sapi cincang lembut berkuah santan belimbing wuluh segar kegemaran Sri Sultan HB IX',
      price: 58000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_resto_4',
      restaurantId: 'resto_restoran_1',
      name: 'Sup Timlo Ningrat',
      description:
          'Sup kaldu ayam bening kaya rasa dengan potongan sosis solo, telur pindang bebek, jamur kuping, dan suwiran ayam',
      price: 42000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_resto_5',
      restaurantId: 'resto_restoran_1',
      name: 'Beer Djawa',
      description:
          'Minuman rempah non-alkohol khas Sultan berbusa jeruk nipis, jahe, serai, cengkeh, kayu manis yang disajikan dingin menyegarkan',
      price: 22000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_resto_6',
      restaurantId: 'resto_restoran_1',
      name: 'Manuk Nom Puding Tape',
      description:
          'Puding tape ketan hijau lembut disajikan dengan emping melinjo gurih manis renyah sebagai penutup santap agung ningrat',
      price: 25000,
      category: 'Camilan',
      imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_1': [
    Food(
      id: 'food_1_1',
      restaurantId: 'resto_1',
      name: 'Nasi Gudeg Komplit Wijilan',
      description:
          'Gudeg nangka merah manis gurih, sambal krecek pedas berkuah areh kental, telur bebek bacem, suwir ayam kampung, dan tahu tempe',
      price: 42000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_1_2',
      restaurantId: 'resto_1',
      name: 'Gudeg Kendil Paha Atas & Dada',
      description:
          'Kemasan kendil tanah liat khas berisi gudeg kering, 2 paha atas/dada ayam kampung, 5 butir telur bebek pindang, dan sambal krecek',
      price: 180000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_1_3',
      restaurantId: 'resto_1',
      name: 'Nasi Gudeg Telur Suwir',
      description:
          'Nasi gudeg nangka muda manis legit, sambal goreng krecek pedas cabai rawit, 1 butir telur pindang bacem, dan suwir ayam kampung',
      price: 25000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_1_4',
      restaurantId: 'resto_1',
      name: 'Sambal Goreng Krecek Mercon',
      description:
          'Porsi krecek kulit sapi empuk kenyal dengan cabai rawit merah utuh kuah santan areh gurih pedas nampol',
      price: 20000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_1_5',
      restaurantId: 'resto_1',
      name: 'Wedang Uwuh Rempah Komplit',
      description:
          'Minuman seduh kayu secang, jahe geprek, cengkeh, kayu manis, dan daun pala disajikan dengan gula batu murni',
      price: 10000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_2': [
    Food(
      id: 'food_2_1',
      restaurantId: 'resto_2',
      name: 'Mangut Lele Asap Pawon',
      description:
          'Ikan lele sungai diasap dengan kayu klampok, dimasak kuah santan cabai rawit merah medok khas pawon Mbah Marto',
      price: 25000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_2_2',
      restaurantId: 'resto_2',
      name: 'Garang Asem Ayam Kampung',
      description:
          'Ayam kampung kukus bungkus daun pisang dengan belimbing wuluh, santan encer segar berkuah pedas gurih asam',
      price: 30000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_2_3',
      restaurantId: 'resto_2',
      name: 'Opor Ayam Kampung Pawon',
      description:
          'Potongan ayam kampung kuah opor kuning kental gurih aroma kayu bakar khas dapur tradisional Bantul',
      price: 28000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_2_4',
      restaurantId: 'resto_2',
      name: 'Gudeg Daun Pepaya & Krecek',
      description:
          'Sayur daun pepaya rebus tanpa rasa pahit disajikan dengan kuah sambal krecek pedas gurih',
      price: 12000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_2_5',
      restaurantId: 'resto_2',
      name: 'Es Beras Kencur Segar',
      description:
          'Jamu beras kencur alami racikan tradisional manis segar pereda lelah',
      price: 7000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_3': [
    Food(
      id: 'food_3_1',
      restaurantId: 'resto_3',
      name: 'Soto Sapi Bathok Bening',
      description:
          'Soto daging sapi kuah kaldu bening gurih segar disajikan otentik di dalam batok kelapa beralas mangkok',
      price: 12000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_3_2',
      restaurantId: 'resto_3',
      name: 'Tempe Garit Goreng Panas',
      description:
          'Tempe kedelai bergarit digoreng dadakan renyah gurih bumbu bawang ketumbar khas Sambisari',
      price: 2000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_3_3',
      restaurantId: 'resto_3',
      name: 'Sate Telur Puyuh Bacem',
      description:
          'Tusukan telur puyuh bumbu bacem manis legit kecap gurih khas Jawa',
      price: 4000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_3_4',
      restaurantId: 'resto_3',
      name: 'Sate Usus Ayam Bumbu Kuning',
      description:
          'Tusukan sate usus ayam bersih empuk dengan bumbu kuning kunyit gurih',
      price: 3000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_3_5',
      restaurantId: 'resto_3',
      name: 'Es Jeruk Peras Segar',
      description:
          'Jeruk peras murni dengan es batu dan gula pasir asli pelepas dahaga sarapan soto',
      price: 5000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_4': [
    Food(
      id: 'food_4_1',
      restaurantId: 'resto_4',
      name: 'Bakmi Godhog Telur Bebek',
      description:
          'Bakmi kuning dan bihun dimasak tungku arang anglo dengan telur bebek kental, suwiran ayam kampung, kekian, dan kol tomat',
      price: 32000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_4_2',
      restaurantId: 'resto_4',
      name: 'Bakmi Goreng Spesial Anglo',
      description:
          'Bakmi goreng manis gurih beraroma asap wajan arang dengan suwiran ayam kampung dan taburan bawang merah goreng renyah',
      price: 32000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1585032226651-759b368d7246?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_4_3',
      restaurantId: 'resto_4',
      name: 'Nasi Magelangan Mbah Gito',
      description:
          'Perpaduan nasi dan bakmi dimasak anglo dengan bumbu gurih manis pedas, telur bebek, dan suwir ayam kampung',
      price: 30000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_4_4',
      restaurantId: 'resto_4',
      name: 'Rica-Rica Balungan Ayam Kampung',
      description:
          'Balungan dan sayap ayam kampung bumbu rica pedas pekat dengan aroma daun kemangi segar',
      price: 35000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_4_5',
      restaurantId: 'resto_4',
      name: 'Teh Poci Gula Batu',
      description:
          'Teh hitam wangi melati diseduh dalam poci tanah liat disajikan dengan cangkir tanah liat dan gula batu',
      price: 12000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_5': [
    Food(
      id: 'food_5_1',
      restaurantId: 'resto_5',
      name: 'Kopi Joss Arang Membara',
      description:
          'Kopi hitam tubruk manis khas Angkringan Lik Man dicelup bongkahan arang kayu membara yang mendesis',
      price: 8000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_5_2',
      restaurantId: 'resto_5',
      name: 'Kopi Susu Joss',
      description:
          'Kopi tubruk kental berpadu susu kental manis dan celupan bara arang panas untuk rasa lembut gurih karamel',
      price: 10000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1572442388796-11668a67e53d?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_5_3',
      restaurantId: 'resto_5',
      name: 'Sego Kucing Sambal Teri',
      description:
          'Nasi bungkus daun pisang porsi pas dengan oseng ikan teri gurih dan sambal tomat pedas nikmat',
      price: 4000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_5_4',
      restaurantId: 'resto_5',
      name: 'Sate Usus & Kulit Bakar Angkringan',
      description:
          'Sate usus dan kulit ayam dibakar kecap manis di atas anglo arang bumbu meresap',
      price: 4000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_5_5',
      restaurantId: 'resto_5',
      name: 'Tempe Mendoan Hangat',
      description:
          'Tempe mendoan tepung berbalut daun bawang disajikan panas dengan cabai rawit hijau segar',
      price: 3000,
      category: 'Camilan',
      imageUrl:
          'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_6': [
    Food(
      id: 'food_6_1',
      restaurantId: 'resto_6',
      name: 'Oseng Mercon Daging Koyor',
      description:
          'Daging sapi, kikil, dan tetelan koyor empuk dioseng dengan puluhan cabai rawit pedas menggelegar',
      price: 30000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_6_2',
      restaurantId: 'resto_6',
      name: 'Oseng Mercon Babat & Paru',
      description:
          'Potongan babat dan paru sapi kenyal gurih berbumbu cabai rawit pedas meledak di lidah',
      price: 32000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_6_3',
      restaurantId: 'resto_6',
      name: 'Ayam Goreng Bumbu Mercon',
      description:
          'Ayam goreng gurih disiram bumbu oseng mercon pedas gurih rawit cabai merah',
      price: 26000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_6_4',
      restaurantId: 'resto_6',
      name: 'Tahu & Tempe Bacem Legit',
      description:
          'Baceman tahu dan tempe manis gurih untuk peredam pedas dahsyat oseng mercon',
      price: 4000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_6_5',
      restaurantId: 'resto_6',
      name: 'Es Jeruk Nipis Murni',
      description:
          'Es jeruk nipis segar pelepas dahaga dan peredam rasa pedas oseng mercon',
      price: 6000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_7': [
    Food(
      id: 'food_7_1',
      restaurantId: 'resto_7',
      name: 'Bakmi Nyemek Telur Bebek',
      description:
          'Bakmi kuah kental sedikit berkuah rempah dimasak wajan arang dengan suwiran ayam kampung dan telur bebek gurih',
      price: 28000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_7_2',
      restaurantId: 'resto_7',
      name: 'Bakmi Godhog Kaldu Gurih',
      description:
          'Bakmi rebus kuah kaldu ayam kampung gurih alami dengan kol segar, seledri, dan taburan bawang goreng',
      price: 28000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_7_3',
      restaurantId: 'resto_7',
      name: 'Nasi Goreng Babat Alun-Alun',
      description:
          'Nasi goreng kecap khas Jawa dimasak wajan arang dengan potongan babat sapi kenyal gurih',
      price: 30000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_7_4',
      restaurantId: 'resto_7',
      name: 'Teh Nasgitel Panas Melati',
      description:
          'Teh panas khas Jawa: panas, legi (manis), dan kentel beraroma melati untuk menemani santap malam',
      price: 6000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_8': [
    Food(
      id: 'food_8_1',
      restaurantId: 'resto_8',
      name: 'Sate Klathak Jeruji Besi',
      description:
          '2 tusuk sate daging kambing muda empuk dipanggang jeruji besi sepeda berbalut garam & kuah gulai gurih',
      price: 33000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_8_2',
      restaurantId: 'resto_8',
      name: 'Tongseng Daging Kambing Muda',
      description:
          'Daging kambing muda empuk dimasak kuah gulai kecap manis gurih dengan irisan kol, tomat, dan cabai rawit utuh',
      price: 33000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_8_3',
      restaurantId: 'resto_8',
      name: 'Kicik Daging Kambing',
      description:
          'Daging kambing cincang bumbu kecap rempah gurih pedas manis pekat tanpa kuah beraroma bawang merah melimpah',
      price: 33000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_8_4',
      restaurantId: 'resto_8',
      name: 'Tengkleng Balungan Pak Pong',
      description:
          'Tulang iga dan balungan kambing empuk berkuah gulai gurih kaya rempah khas Imogiri Bantul',
      price: 38000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_8_5',
      restaurantId: 'resto_8',
      name: 'Sarsaparilla / Saparella Dingin',
      description:
          'Minuman soda herbal sarsaparilla klasik khas Yogyakarta dingin dengan aroma rempah menyegarkan',
      price: 12000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_9': [
    Food(
      id: 'food_9_1',
      restaurantId: 'resto_9',
      name: 'Nasi Pecel Komplit Bu Wiryo',
      description:
          'Nasi hangat diselimuti sayur bayam, kangkung, kecambah, kacang panjang disiram kuah sambal pecel kacang kental gurih pedas manis',
      price: 22000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_9_2',
      restaurantId: 'resto_9',
      name: 'Nasi Sop Daging Sapi Bening',
      description:
          'Sop kaldu sapi bening segar dengan potongan wortel, kentang, buncis, dan irisan daging sapi empuk khas UGM',
      price: 25000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_9_3',
      restaurantId: 'resto_9',
      name: 'Empal Daging Sapi Bacem',
      description:
          'Daging sapi goreng gurih manis empuk bumbu rempah bacem meresap sempurna',
      price: 18000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_9_4',
      restaurantId: 'resto_9',
      name: 'Tempe & Tahu Bacem Bu Wiryo',
      description:
          'Tempe kedelai dan tahu bacem khas bumbu ketumbar gula kelapa legit gurih',
      price: 5000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_9_5',
      restaurantId: 'resto_9',
      name: 'Es Kolak Pisang Kepok',
      description:
          'Kolak pisang kepok santan gula aren wangi daun pandan disajikan dingin menyegarkan',
      price: 10000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_10': [
    Food(
      id: 'food_10_1',
      restaurantId: 'resto_10',
      name: 'Tengkleng Gajah Kuah Gulai Jumbo',
      description:
          'Porsi jumbo balungan kambing dengan sumsum melimpah dalam kuah gulai rempah pekat gurih kaya rasa',
      price: 52000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_10_2',
      restaurantId: 'resto_10',
      name: 'Tengkleng Gajah Goreng Rempah',
      description:
          'Balungan kambing dipanggang dan digoreng dengan bumbu kecap rempah manis gurih karamel gurih',
      price: 52000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_10_3',
      restaurantId: 'resto_10',
      name: 'Sate Goreng Daging Kambing',
      description:
          'Daging kambing empuk tanpa tusuk ditumis bumbu kecap pedas gurih dengan kol dan tomat segar',
      price: 45000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_10_4',
      restaurantId: 'resto_10',
      name: 'Nasi Goreng Kambing Gajah',
      description:
          'Nasi goreng bumbu rempah gulai kambing dengan suwiran daging kambing melimpah dan acar segar',
      price: 38000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_10_5',
      restaurantId: 'resto_10',
      name: 'Es Timun Serut Selasih',
      description:
          'Serutan mentimun segar berpadu biji selasih dan sirup melon dingin peredam kolesterol',
      price: 10000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_11': [
    Food(
      id: 'food_11_1',
      restaurantId: 'resto_11',
      name: 'Es Dawet Ayu Cendol Pandan',
      description:
          'Cendol daun pandan suji kenyal dengan santan kelapa murni gurih dan juruh gula aren kental harum nangka',
      price: 10000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_11_2',
      restaurantId: 'resto_11',
      name: 'Es Dawet Durian Asli',
      description:
          'Es dawet cendol komplet disajikan dengan 1 butir buah durian asli manis creamy legit',
      price: 22000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_11_3',
      restaurantId: 'resto_11',
      name: 'Rujak Es Krim Malioboro',
      description:
          'Serutan buah mangga, kedondong, bengkuang, pepaya berbumbu rujak pedas manis asam ditutup es puter kelapa lembut',
      price: 15000,
      category: 'Camilan',
      imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_11_4',
      restaurantId: 'resto_11',
      name: 'Es Cincau Hitam Gula Aren',
      description:
          'Cincau hitam kenyal alami disiram santan kelapa segar dan kuah juruh gula aren harum',
      price: 8000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_12': [
    Food(
      id: 'food_12_1',
      restaurantId: 'resto_12',
      name: 'Ayam Kampung Utuh Goreng Cemplung',
      description:
          '1 ekor ayam kampung utuh bumbu bawang putih ketumbar digoreng dalam kuali tanah liat api kayu bakar, kulit renyah daging juicy',
      price: 135000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_12_2',
      restaurantId: 'resto_12',
      name: 'Paket Paha / Dada Cemplung + Nasi',
      description:
          'Potongan ayam kampung paha atau dada renyah di luar juicy di dalam disajikan dengan nasi pulen hangat',
      price: 35000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_12_3',
      restaurantId: 'resto_12',
      name: 'Sambal Korek Ulek Bawang',
      description:
          'Sambal cabai rawit merah segar diulek dadakan dengan bawang putih dan siraman minyak panas kelapa gurih',
      price: 5000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_12_4',
      restaurantId: 'resto_12',
      name: 'Sayur Asem Segar Kasihan',
      description:
          'Sayur asem khas Jawa manis asam segar dengan melinjo, jagung manis, kacang panjang, dan kacang tanah',
      price: 8000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_12_5',
      restaurantId: 'resto_12',
      name: 'Es Kelapa Muda Gula Jawa',
      description:
          'Air kelapa muda dan daging kelapa keruk disajikan dengan gula kelapa cair asli dan es batu',
      price: 10000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
};

final kDefaultReviews = <String, List<Review>>{
  'resto_1': [
    Review(
      id: 'rev_1_1',
      userId: 'usr_1',
      restaurantId: 'resto_1',
      rating: 5,
      comment:
          'Kreceknya pedas gurih dan areh santannya sangat kental beraroma kayu bakar. '
          'Resep autentik Kraton yang tidak pernah berubah sejak dulu.',
      createdAt: DateTime(2025, 10, 15),
      userName: 'Arya Dananjaya',
    ),
    Review(
      id: 'rev_1_2',
      userId: 'usr_2',
      restaurantId: 'resto_1',
      rating: 5,
      comment:
          'Porsi komplit mengenyangkan dan manisnya pas di lidah. '
          'Wajib dicoba kalau main ke kawasan Wijilan!',
      createdAt: DateTime(2025, 10, 12),
      userName: 'Siti Rahmawati',
    ),
    Review(
      id: 'rev_1_3',
      userId: 'usr_5',
      restaurantId: 'resto_1',
      rating: 5,
      comment:
          'Gudeg paling legendaris di Jogja. Beli buat oleh-oleh keluarga di Jakarta, '
          'besek kendilnya tahan sampai di sana dalam kondisi sempurna.',
      createdAt: DateTime(2025, 10, 5),
      userName: 'Rina Setiawati',
    ),
  ],
  'resto_2': [
    Review(
      id: 'rev_2_1',
      userId: 'usr_6',
      restaurantId: 'resto_2',
      rating: 5,
      comment:
          'Mangut lelenya juara! Asap kayu klampok benar-benar memberikan aroma khas '
          'yang tidak bisa ditemukan di tempat lain. Pedasnya nendang banget.',
      createdAt: DateTime(2025, 10, 14),
      userName: 'Bagas Widodo',
    ),
    Review(
      id: 'rev_2_2',
      userId: 'usr_7',
      restaurantId: 'resto_2',
      rating: 4,
      comment:
          'Tempatnya sederhana tapi rasanya luar biasa. Harus datang pagi karena '
          'cepat habis. Sangat recommended untuk pecinta kuliner otentik Bantul.',
      createdAt: DateTime(2025, 10, 9),
      userName: 'Laila Nuraini',
    ),
  ],
  'resto_3': [
    Review(
      id: 'rev_3_1',
      userId: 'usr_8',
      restaurantId: 'resto_3',
      rating: 5,
      comment:
          'Unik banget disajikan dalam batok kelapa! Kuah bening segarnya beda dari soto '
          'biasa. Tempe garit gorengnya renyah sempurna, cocok buat sarapan.',
      createdAt: DateTime(2025, 10, 11),
      userName: 'Dita Permatasari',
    ),
    Review(
      id: 'rev_3_2',
      userId: 'usr_9',
      restaurantId: 'resto_3',
      rating: 4,
      comment:
          'Harganya sangat terjangkau untuk rasa yang luar biasa. Lokasi dekat Candi '
          'Sambisari jadi bisa sekaligus wisata sejarah. Sangat worth it!',
      createdAt: DateTime(2025, 10, 7),
      userName: 'Eko Prasetyo',
    ),
  ],
  'resto_4': [
    Review(
      id: 'rev_4_1',
      userId: 'usr_3',
      restaurantId: 'resto_4',
      rating: 5,
      comment:
          'Bakmi jawa paling autentik yang pernah saya cicipi. Kuah kaldu kental '
          'dengan telur bebek sungguh luar biasa. Wajib antri tapi worth it!',
      createdAt: DateTime(2025, 10, 10),
      userName: 'Budi Santoso',
    ),
    Review(
      id: 'rev_4_2',
      userId: 'usr_10',
      restaurantId: 'resto_4',
      rating: 5,
      comment:
          'Sudah 3 kali balik ke sini dan selalu nagih. Bakmi gorengnya juga tidak '
          'kalah enak dari yang godhog. Aroma arang kayunya bikin kangen terus.',
      createdAt: DateTime(2025, 10, 3),
      userName: 'Hendra Wijaya',
    ),
  ],
  'resto_5': [
    Review(
      id: 'rev_5_1',
      userId: 'usr_4',
      restaurantId: 'resto_5',
      rating: 5,
      comment:
          'Kopi Joss satu-satunya yang ada arangnya! Suasana Stasiun Tugu malam hari '
          'makin syahdu. Harga sangat terjangkau, pengalaman yang tidak terlupakan.',
      createdAt: DateTime(2025, 10, 8),
      userName: 'Dewi Kusuma',
    ),
    Review(
      id: 'rev_5_2',
      userId: 'usr_11',
      restaurantId: 'resto_5',
      rating: 5,
      comment:
          'Ikon wisata malam Jogja yang sesungguhnya. Nasi kucing 4000 perak dengan '
          'kopi joss yang iconic. Wajib dikunjungi setiap ke Jogja!',
      createdAt: DateTime(2025, 10, 1),
      userName: 'Fajar Nugroho',
    ),
  ],
  'resto_6': [
    Review(
      id: 'rev_6_1',
      userId: 'usr_12',
      restaurantId: 'resto_6',
      rating: 5,
      comment:
          'Level pedas maksimal! Beneran meledak di mulut tapi nagih banget. '
          'Oseng koyor sayangnya tidak ada di tempat lain yang bisa menandingi ini.',
      createdAt: DateTime(2025, 10, 13),
      userName: 'Rizki Pratama',
    ),
    Review(
      id: 'rev_6_2',
      userId: 'usr_13',
      restaurantId: 'resto_6',
      rating: 4,
      comment:
          'Pedas yang sebenarnya untuk pecinta kuliner ekstrem. Selalu bawa minum '
          'ekstra! Tapi tetap saja ketagihan dan balik lagi minggu berikutnya.',
      createdAt: DateTime(2025, 10, 6),
      userName: 'Maya Anggraeni',
    ),
  ],
  'resto_7': [
    Review(
      id: 'rev_7_1',
      userId: 'usr_14',
      restaurantId: 'resto_7',
      rating: 5,
      comment:
          'Makan bakmi di bawah langit Alun-alun Utara dengan view Gunung Merapi '
          'adalah pengalaman yang tidak ternilai. Rasanya memang otentik banget.',
      createdAt: DateTime(2025, 10, 12),
      userName: 'Anggita Rahayu',
    ),
    Review(
      id: 'rev_7_2',
      userId: 'usr_15',
      restaurantId: 'resto_7',
      rating: 4,
      comment:
          'Suasana malamnya romantis sekali. Bakmi nyemeknya lembut dan kuahnya '
          'gurih khas Jogja. Lokasi strategis untuk tutup malam di Jogja.',
      createdAt: DateTime(2025, 10, 4),
      userName: 'Dimas Prakoso',
    ),
  ],
  'resto_8': [
    Review(
      id: 'rev_8_1',
      userId: 'usr_16',
      restaurantId: 'resto_8',
      rating: 5,
      comment:
          'Sate kambing paling otentik! Dipanggang di jeruji besi sepeda, bumbu '
          'hanya garam dan bawang tapi rasanya surga. Terbaik di seluruh DIY!',
      createdAt: DateTime(2025, 10, 15),
      userName: 'Prasetya Adi',
    ),
    Review(
      id: 'rev_8_2',
      userId: 'usr_17',
      restaurantId: 'resto_8',
      rating: 5,
      comment:
          'Sudah terkenal sampai mancanegara. Turis Jepang di sebelah saya juga antri '
          'panjang. Buktikan sendiri mengapa ini jadi ikon kuliner DIY.',
      createdAt: DateTime(2025, 10, 10),
      userName: 'Ninda Octavia',
    ),
  ],
  'resto_9': [
    Review(
      id: 'rev_9_1',
      userId: 'usr_18',
      restaurantId: 'resto_9',
      rating: 4,
      comment:
          'Sarapan terbaik di Jogja! Sambal kacangnya kental dan bumbu pecelnya '
          'terasa segar. Harga sangat merakyat untuk kualitas yang luar biasa.',
      createdAt: DateTime(2025, 10, 11),
      userName: 'Citra Lestari',
    ),
  ],
  'resto_10': [
    Review(
      id: 'rev_10_1',
      userId: 'usr_19',
      restaurantId: 'resto_10',
      rating: 5,
      comment:
          'Porsi gajah benar-benar jumbo! Kuah rempahnya kaya dan dagingnya empuk '
          'sekali. Cocok untuk makan bersama keluarga. Harga sebanding kualitasnya.',
      createdAt: DateTime(2025, 10, 8),
      userName: 'Wahyu Santoso',
    ),
  ],
  'resto_11': [
    Review(
      id: 'rev_11_1',
      userId: 'usr_20',
      restaurantId: 'resto_11',
      rating: 5,
      comment:
          'Seger banget! Cocok untuk menghilangkan lelah setelah berjalan kaki di '
          'Malioboro. Cendolnya kenyal dan santan segar banget. Murah meriah!',
      createdAt: DateTime(2025, 10, 14),
      userName: 'Fitri Handayani',
    ),
  ],
  'resto_12': [
    Review(
      id: 'rev_12_1',
      userId: 'usr_21',
      restaurantId: 'resto_12',
      rating: 5,
      comment:
          'Teknik cemplung yang bikin kulit ayam super renyah! Dagingnya juicy dan '
          'bumbu meresap sempurna. Wajib antri 30 menit tapi sangat worth it!',
      createdAt: DateTime(2025, 10, 13),
      userName: 'Galuh Putri',
    ),
    Review(
      id: 'rev_12_2',
      userId: 'usr_22',
      restaurantId: 'resto_12',
      rating: 5,
      comment:
          'Terbaik! Sudah coba banyak ayam goreng di Jogja tapi ini yang paling '
          'otentik. Wajan tanah liatnya benar-benar memberi perbedaan yang nyata.',
      createdAt: DateTime(2025, 10, 9),
      userName: 'Reza Firmansyah',
    ),
  ],
};

final kDefaultCategories = <String>[
  'Restoran',
  'Cafe',
  'Fast Food',
  'Food Court',
  'Warung Tradisional',
  'Angkringan',
];
