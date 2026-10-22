import '../models/restaurant.dart';
import '../models/food.dart';
import '../models/review.dart';

final kDefaultRestaurants = <Restaurant>[
  Restaurant(
    id: 'resto_1',
    name: 'Gudeg Yu Djum Wijilan',
    category: 'Gudeg',
    address: 'Jl. Wijilan No. 167, Panembahan, Kraton, Yogyakarta',
    province: 'DIY',
    lat: -7.8004,
    lng: 110.3667,
    priceMin: 20000,
    priceMax: 45000,
    openingHours: '06:00 - 21:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=900&q=85',
    phone: '081227000167',
    website: 'https://gudegyudjum.com',
    createdAt: DateTime(2025, 1, 1),
    rating: 4.9,
    reviewCount: 1284,
    description:
        'Warung gudeg legendaris yang telah berdiri sejak 1950-an dengan resep turun-temurun. '
        'Krecek pedasnya yang khas dan areh santannya yang kental menjadi daya tarik utama '
        'wisatawan kuliner Keraton. Berlokasi di kampung Wijilan yang terkenal sebagai sentra gudeg Jogja.',
  ),
  Restaurant(
    id: 'resto_2',
    name: 'Mangut Lele Asap Mbah Marto',
    category: 'Kuliner Tradisional',
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
        'Lele asap kayu klampok khas Bantul disiram kuah santan cabai rawit yang pedas gurih. '
        'Dimasak di dapur pawon tradisional dengan kayu bakar pilihan setiap harinya. '
        'Mbah Marto telah mewariskan resep rahasia ini kepada generasi ketiga keluarganya.',
  ),
  Restaurant(
    id: 'resto_3',
    name: 'Soto Bathok Mbah Katro',
    category: 'Soto',
    address: 'Jl. Candi Sambisari, Kalasan, Sleman, DIY',
    province: 'DIY',
    lat: -7.7555,
    lng: 110.4609,
    priceMin: 8000,
    priceMax: 15000,
    openingHours: '06:00 - 14:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1617093727343-374698b1b08d?auto=format&fit=crop&w=900&q=85',
    phone: '081568000789',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.7,
    reviewCount: 542,
    description:
        'Soto kuah bening segar disajikan dalam batok kelapa asli yang unik dan estetik. '
        'Irisan daging sapi empuk dengan tempe garit renyah menjadi sajian sarapan favorit warga Kalasan. '
        'Viral di media sosial karena cara penyajiannya yang orisinal dan instagramable.',
  ),
  Restaurant(
    id: 'resto_4',
    name: 'Bakmi Jawa Mbah Gito',
    category: 'Bakmi Jawa',
    address: 'Jl. Kemasan, Kotagede, Yogyakarta',
    province: 'DIY',
    lat: -7.8168,
    lng: 110.3986,
    priceMin: 20000,
    priceMax: 35000,
    openingHours: '16:00 - 23:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=85',
    phone: '081804000321',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.8,
    reviewCount: 934,
    description:
        'Bakmi Jawa arang kayu paling legendaris di Kotagede. '
        'Kuah kaldu ayam kampung kental dengan telur bebek rebus menjadi ciri khas yang tak terlupakan. '
        'Sudah berdiri lebih dari 40 tahun, antrian panjang setiap malam adalah bukti nyata kelezatannya.',
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
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=85',
    phone: '081705000654',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.7,
    reviewCount: 2103,
    description:
        'Kopi tubruk robusta yang dicelupkan arang kayu membara menghasilkan aroma karamel smoky '
        'khas angkringan Stasiun Tugu. Spot ikonik wisata malam Jogja sejak 1960-an. '
        'Dipercaya mampu menetralisir asam lambung berkat reaksi kimia arang panas dengan kopi.',
  ),
  Restaurant(
    id: 'resto_6',
    name: 'Oseng Mercon Bu Narti',
    category: 'Kuliner Pedas',
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
        'Oseng koyor sapi dengan racikan cabai rawit merah yang benar-benar meledak di lidah. '
        'Hidangan pedas legendaris yang telah menjadi kebanggaan warga Jogja selama puluhan tahun. '
        'Tingkat kepedasan bisa disesuaikan dari sedang hingga level ekstrem bagi pecinta pedas sejati.',
  ),
  Restaurant(
    id: 'resto_7',
    name: 'Bakmi Jawa Pak Pale',
    category: 'Bakmi Jawa',
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
        'Bakmi nyemek spesial dengan bumbu bawang putih khas dapur Kraton. '
        'Disajikan malam hari di bawah langit terbuka Alun-alun Utara dengan nuansa magis. '
        'Kompor arang tradisional dan bahan pilihan menjadi kunci cita rasa yang sulit dilupakan.',
  ),
  Restaurant(
    id: 'resto_8',
    name: 'Sate Klatak Pak Pong',
    category: 'Sate',
    address: 'Jl. Imogiri Timur, Bantul, DIY',
    province: 'DIY',
    lat: -7.8714,
    lng: 110.3830,
    priceMin: 30000,
    priceMax: 55000,
    openingHours: '10:00 - 22:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=900&q=85',
    phone: '081308000456',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.9,
    reviewCount: 1567,
    description:
        'Sate kambing muda paling ikonik di DIY. Hanya dibumbui garam dan bawang, '
        'dipanggang di atas jeruji besi sepeda yang unik, inilah yang membuat tekstur dagingnya '
        'berbeda dari sate biasa. Cita rasa alami tanpa kecap yang khas dan tak tertandingi di Jogja.',
  ),
  Restaurant(
    id: 'resto_9',
    name: 'Warung Nasi Pecel Bu Wiryo',
    category: 'Kuliner Tradisional',
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
        'Nasi pecel sarapan paling legendaris di Pasar Kranggan dengan sambal kacang kental '
        'dan pilihan lauk pauk komplet. Buka sejak dini hari, antriannya sudah mengular sebelum '
        'pasar buka. Tempe goreng dan empal gentong menjadi pelengkap favorit pelanggan setia.',
  ),
  Restaurant(
    id: 'resto_10',
    name: 'Tengkleng Gajah Bu Hj. Bejo',
    category: 'Kuliner Tradisional',
    address: 'Jl. Brigjen Katamso No. 57, Mergangsan, Yogyakarta',
    province: 'DIY',
    lat: -7.8089,
    lng: 110.3654,
    priceMin: 35000,
    priceMax: 75000,
    openingHours: '10:00 - 20:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=85',
    phone: '081410000567',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.5,
    reviewCount: 298,
    description:
        'Tengkleng kambing porsi jumbo dengan kuah rempah-rempah yang kaya dan tulang-tulang '
        'empuk penuh sumsum lezat. Resep warisan dari Solo yang disesuaikan dengan selera Jogja. '
        'Porsi "gajah" bisa untuk 2-3 orang, cocok untuk makan bersama keluarga.',
  ),
  Restaurant(
    id: 'resto_11',
    name: 'Es Dawet Ibu Titi',
    category: 'Minuman & Jajanan',
    address: 'Malioboro, Jl. Malioboro No. 1, Gedongtengen, Yogyakarta',
    province: 'DIY',
    lat: -7.7927,
    lng: 110.3658,
    priceMin: 5000,
    priceMax: 12000,
    openingHours: '09:00 - 20:00 WIB',
    imageUrl:
        'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=900&q=85',
    phone: '081211000890',
    website: null,
    createdAt: DateTime(2025, 1, 1),
    rating: 4.5,
    reviewCount: 756,
    description:
        'Dawet ayu tradisional dengan cendol hijau pandan segar, santan kental gurih, '
        'dan gula merah Jogja yang otentik. Kesegaran terbaik di sepanjang Malioboro '
        'untuk menemani jalan-jalan wisata di pusat kota Yogyakarta.',
  ),
  Restaurant(
    id: 'resto_12',
    name: 'Ayam Goreng Mbah Cemplung',
    category: 'Kuliner Tradisional',
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
        'Ayam kampung goreng dengan teknik "cemplung" — digoreng langsung dalam minyak '
        'panas menggunakan wajan tanah liat tradisional. Kulit renyah dan daging juicy '
        'dengan bumbu kunyit-ketumbar yang meresap sempurna. Sudah terkenal sejak 1970-an.',
  ),
];

final kDefaultFoods = <String, List<Food>>{
  'resto_1': [
    Food(
      id: 'food_1_1',
      restaurantId: 'resto_1',
      name: 'Paket Nasi Gudeg Komplit',
      description:
          'Nasi gudeg krecek mercon, telur pindang, tahu bacem, suwir ayam kampung',
      price: 25000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_1_2',
      restaurantId: 'resto_1',
      name: 'Paket Gudeg Paha Atas',
      description:
          'Gudeg dengan paha ayam kampung bakar bumbu areh kental gurih',
      price: 38000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_1_3',
      restaurantId: 'resto_1',
      name: 'Besek Gudeg Kendil 5 Porsi',
      description:
          'Gudeg kendil lengkap porsi keluarga untuk oleh-oleh tahan 24 jam',
      price: 120000,
      category: 'Oleh-oleh',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_1_4',
      restaurantId: 'resto_1',
      name: 'Es Teh Manis Hangat',
      description: 'Teh tubruk pilihan dengan gula aren lokal Bantul',
      price: 5000,
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
          'Lele asap kayu klampok disiram kuah santan cabai rawit pedas gurih',
      price: 25000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_2_2',
      restaurantId: 'resto_2',
      name: 'Paket Nasi Gudeg Manggar',
      description:
          'Gudeg bunga kelapa khas Bantul dengan areh santan kental',
      price: 20000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_2_3',
      restaurantId: 'resto_2',
      name: 'Sambal Bawang Bajak',
      description: 'Sambal rawit merah bajak dengan bawang merah goreng renyah',
      price: 3000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1626200419199-391ae4be7a41?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_3': [
    Food(
      id: 'food_3_1',
      restaurantId: 'resto_3',
      name: 'Soto Daging Bathok Kelapa',
      description:
          'Soto kuah bening segar disajikan dalam batok kelapa dengan irisan daging sapi empuk',
      price: 12000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1617093727343-374698b1b08d?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_3_2',
      restaurantId: 'resto_3',
      name: 'Tempe Garit Goreng Hangat',
      description: 'Tempe bergarit bumbu bawang ketumbar gurih renyah',
      price: 2000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_3_3',
      restaurantId: 'resto_3',
      name: 'Soto Ayam Kampung Bathok',
      description: 'Versi ayam kampung dengan kuah kuning kunyit segar',
      price: 10000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1617093727343-374698b1b08d?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_4': [
    Food(
      id: 'food_4_1',
      restaurantId: 'resto_4',
      name: 'Bakmi Godhog Telur Bebek',
      description:
          'Bakmi rebus kuah kaldu ayam kampung kental dimasak dengan arang kayu',
      price: 28000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_4_2',
      restaurantId: 'resto_4',
      name: 'Bakmi Goreng Arang Mbah Gito',
      description:
          'Bakmi goreng kering dengan ayam kampung suwir dan telur omelette tipis',
      price: 30000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_4_3',
      restaurantId: 'resto_4',
      name: 'Wedang Uwuh Rempah Imogiri',
      description:
          'Minuman rempah daun secang, kayu manis, jahe, dan gula batu khas Imogiri',
      price: 10000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_5': [
    Food(
      id: 'food_5_1',
      restaurantId: 'resto_5',
      name: 'Kopi Joss Arang Membara',
      description:
          'Kopi tubruk robusta diselipkan arang kayu membara menciptakan aroma karamel smoky',
      price: 8000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_5_2',
      restaurantId: 'resto_5',
      name: 'Nasi Kucing Sambal Teri',
      description:
          'Nasi porsi kecil bungkus daun pisang dengan sambal teri gurih pedas',
      price: 4000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_5_3',
      restaurantId: 'resto_5',
      name: 'Gorengan Angkringan Mix',
      description:
          'Ote-ote, bakwan jagung, tahu isi, dan pisang goreng pilihan',
      price: 2000,
      category: 'Jajanan',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_6': [
    Food(
      id: 'food_6_1',
      restaurantId: 'resto_6',
      name: 'Oseng Mercon Daging Koyor',
      description:
          'Koyor sapi empuk ditumis dengan racikan cabai rawit merah membara yang meledak di lidah',
      price: 30000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1626200419199-391ae4be7a41?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_6_2',
      restaurantId: 'resto_6',
      name: 'Oseng Mercon Tahu Tempe',
      description:
          'Tahu dan tempe goreng dengan bumbu mercon versi vegetarian yang tak kalah pedas',
      price: 20000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_6_3',
      restaurantId: 'resto_6',
      name: 'Es Jeruk Peras Segar',
      description: 'Penawar pedas! Jeruk peras segar dengan gula aren dingin',
      price: 8000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_7': [
    Food(
      id: 'food_7_1',
      restaurantId: 'resto_7',
      name: 'Bakmi Nyemek Spesial Kraton',
      description:
          'Perpaduan mi kuah kental basah dengan bumbu bawang putih khas kraton dan suwir ayam',
      price: 25000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_7_2',
      restaurantId: 'resto_7',
      name: 'Bakmi Goreng Kering Alun-alun',
      description:
          'Bakmi goreng kering dengan bumbu kuat dan topping ceker ayam',
      price: 27000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_8': [
    Food(
      id: 'food_8_1',
      restaurantId: 'resto_8',
      name: 'Sate Klatak Jeruji Besi 2 Tusuk',
      description:
          'Daging kambing muda hanya dibumbui garam dan bawang, dipanggang di atas jeruji besi sepeda',
      price: 35000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_8_2',
      restaurantId: 'resto_8',
      name: 'Gule Kambing Muda Spesial',
      description: 'Kuah rempah kaya dengan potongan tulang kambing sumsum',
      price: 45000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_8_3',
      restaurantId: 'resto_8',
      name: 'Nasi Putih + Krupuk Emping',
      description: 'Nasi putih panas pulen dengan krupuk emping melinjo renyah',
      price: 5000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_9': [
    Food(
      id: 'food_9_1',
      restaurantId: 'resto_9',
      name: 'Nasi Pecel Komplit Spesial',
      description:
          'Nasi dengan sayuran rebus segar disiram sambal kacang kental dan pilihan lauk',
      price: 15000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_9_2',
      restaurantId: 'resto_9',
      name: 'Empal Gentong Sapi',
      description: 'Empal sapi bumbu kuning digoreng kering renyah gurih',
      price: 8000,
      category: 'Lauk',
      imageUrl:
          'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_10': [
    Food(
      id: 'food_10_1',
      restaurantId: 'resto_10',
      name: 'Tengkleng Gajah Porsi Jumbo',
      description:
          'Tulang kambing kuah rempah kaya dengan sumsum lezat, porsi untuk 2-3 orang',
      price: 65000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_10_2',
      restaurantId: 'resto_10',
      name: 'Tengkleng Regular',
      description:
          'Porsi standar dengan pilihan daging dan iga kambing muda',
      price: 38000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_11': [
    Food(
      id: 'food_11_1',
      restaurantId: 'resto_11',
      name: 'Es Dawet Ayu Original',
      description:
          'Dawet cendol pandan hijau dengan santan segar dan gula merah cair',
      price: 8000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_11_2',
      restaurantId: 'resto_11',
      name: 'Es Dawet Durian Special',
      description: 'Dawet dengan topping daging durian montong premium lokal',
      price: 12000,
      category: 'Minuman',
      imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
  ],
  'resto_12': [
    Food(
      id: 'food_12_1',
      restaurantId: 'resto_12',
      name: 'Ayam Goreng Cemplung Utuh',
      description:
          'Ayam kampung utuh goreng dengan teknik cemplung wajan tanah liat, kulit super renyah',
      price: 50000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_12_2',
      restaurantId: 'resto_12',
      name: 'Paha + Dada Goreng Cemplung',
      description:
          'Potongan paha atas dan dada ayam kampung goreng bumbu kunyit ketumbar meresap',
      price: 30000,
      category: 'Makanan Utama',
      imageUrl:
          'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=600&q=80',
      createdAt: DateTime(2025, 1, 1),
    ),
    Food(
      id: 'food_12_3',
      restaurantId: 'resto_12',
      name: 'Lalapan Segar + Sambal Tomat',
      description: 'Lalapan timun, kemangi, kacang panjang dengan sambal tomat segar',
      price: 5000,
      category: 'Pelengkap',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=600&q=80',
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
  'Gudeg',
  'Soto',
  'Bakmi Jawa',
  'Angkringan',
];
