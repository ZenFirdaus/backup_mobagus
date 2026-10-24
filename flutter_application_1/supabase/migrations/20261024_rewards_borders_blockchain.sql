-- ==============================================================================
-- FOODIE REWARDS + BORDER SHOP + BLOCKCHAIN REGISTRY MIGRATION
-- Project: FOODIE Mobile App (DIY & Jateng)
-- Target: Supabase PostgreSQL
-- ==============================================================================

-- 1. TABEL: REWARD_BORDERS (Katalog Produk Border Profil)
CREATE TABLE IF NOT EXISTS public.reward_borders (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    rarity TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    price_points INTEGER NOT NULL CHECK (price_points >= 0),
    is_animated BOOLEAN NOT NULL DEFAULT false,
    category TEXT NOT NULL DEFAULT 'Klasik',
    style_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index reward_borders
CREATE INDEX IF NOT EXISTS idx_reward_borders_rarity ON public.reward_borders(rarity);
CREATE INDEX IF NOT EXISTS idx_reward_borders_price ON public.reward_borders(price_points);

-- 2. TABEL: USER_POINTS (Buku Saldo Poin Pengguna - Atomik & Non-Negatif)
CREATE TABLE IF NOT EXISTS public.user_points (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
    total_earned INTEGER NOT NULL DEFAULT 0 CHECK (total_earned >= 0),
    total_spent INTEGER NOT NULL DEFAULT 0 CHECK (total_spent >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index user_points
CREATE INDEX IF NOT EXISTS idx_user_points_balance ON public.user_points(balance);

-- 3. TABEL: POINT_TRANSACTIONS (Ledger Riwayat Transaksi Poin - Audit Trail)
CREATE TABLE IF NOT EXISTS public.point_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL, -- Positif = Perolehan, Negatif = Penukaran
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('game_reward', 'border_purchase', 'checkin', 'refund', 'bonus')),
    reference_id TEXT,
    idempotency_key TEXT UNIQUE NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index point_transactions
CREATE INDEX IF NOT EXISTS idx_point_tx_user_id ON public.point_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_point_tx_created ON public.point_transactions(created_at DESC);

-- 4. TABEL: USER_REWARDS (Koleksi Border Profil yang Dimiliki Pengguna)
CREATE TABLE IF NOT EXISTS public.user_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    border_id TEXT NOT NULL REFERENCES public.reward_borders(id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT false,
    acquired_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_border UNIQUE (user_id, border_id)
);

-- Index user_rewards
CREATE INDEX IF NOT EXISTS idx_user_rewards_user ON public.user_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_rewards_active ON public.user_rewards(user_id) WHERE is_active = true;

-- Tambahkan kolom active_border_id di tabel profiles jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'active_border_id'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN active_border_id TEXT REFERENCES public.reward_borders(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 5. TABEL: REWARD_REDEMPTIONS (Pencatatan Penukaran Hadiah Idempoten)
CREATE TABLE IF NOT EXISTS public.reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    border_id TEXT NOT NULL REFERENCES public.reward_borders(id) ON DELETE RESTRICT,
    points_spent INTEGER NOT NULL CHECK (points_spent >= 0),
    status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'failed')),
    idempotency_key TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index reward_redemptions
CREATE INDEX IF NOT EXISTS idx_redemptions_user ON public.reward_redemptions(user_id);

-- 6. TABEL: BLOCKCHAIN_TRANSACTIONS (Pencatatan Bukti On-Chain EVM Sepolia Testnet)
CREATE TABLE IF NOT EXISTS public.blockchain_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    redemption_id UUID REFERENCES public.reward_redemptions(id) ON DELETE SET NULL,
    border_id TEXT NOT NULL REFERENCES public.reward_borders(id) ON DELETE RESTRICT,
    chain_id BIGINT NOT NULL DEFAULT 11155111, -- Sepolia Testnet
    contract_address TEXT NOT NULL,
    tx_hash TEXT UNIQUE NOT NULL,
    block_number BIGINT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'failed')),
    explorer_url TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    confirmed_at TIMESTAMPTZ
);

-- Index blockchain_transactions
CREATE INDEX IF NOT EXISTS idx_blockchain_tx_user ON public.blockchain_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_tx_hash ON public.blockchain_transactions(tx_hash);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.reward_borders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_transactions ENABLE ROW LEVEL SECURITY;

-- 1. reward_borders: Publik dapat melihat produk aktif
DROP POLICY IF EXISTS "Public can view active borders" ON public.reward_borders;
CREATE POLICY "Public can view active borders" 
ON public.reward_borders FOR SELECT USING (is_active = true);

-- 2. user_points: Pengguna hanya dapat membaca saldonya sendiri
DROP POLICY IF EXISTS "Users can view own points" ON public.user_points;
CREATE POLICY "Users can view own points" 
ON public.user_points FOR SELECT USING (auth.uid() = user_id);

-- 3. point_transactions: Pengguna dapat melihat dan mencatat riwayat transaksinya sendiri
DROP POLICY IF EXISTS "Users can view own point transactions" ON public.point_transactions;
CREATE POLICY "Users can view own point transactions" 
ON public.point_transactions FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own point transactions" ON public.point_transactions;
CREATE POLICY "Users can insert own point transactions" 
ON public.point_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. user_rewards: Siapapun dapat melihat border aktif orang lain (untuk avatar review), owner dapat manage
DROP POLICY IF EXISTS "Public can view equipped rewards" ON public.user_rewards;
CREATE POLICY "Public can view equipped rewards" 
ON public.user_rewards FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own rewards" ON public.user_rewards;
CREATE POLICY "Users can update own rewards" 
ON public.user_rewards FOR UPDATE USING (auth.uid() = user_id);

-- 5. reward_redemptions: Owner dapat melihat penukarannya
DROP POLICY IF EXISTS "Users can view own redemptions" ON public.reward_redemptions;
CREATE POLICY "Users can view own redemptions" 
ON public.reward_redemptions FOR SELECT USING (auth.uid() = user_id);

-- 6. blockchain_transactions: Publik dapat memverifikasi bukti on-chain, user dapat insert bukti minting
DROP POLICY IF EXISTS "Public can view blockchain proofs" ON public.blockchain_transactions;
CREATE POLICY "Public can view blockchain proofs" 
ON public.blockchain_transactions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own blockchain tx" ON public.blockchain_transactions;
CREATE POLICY "Users can insert own blockchain tx" 
ON public.blockchain_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- DATABASE FUNCTIONS / STORED PROCEDURES (RPC ATOMIK)
-- ==============================================================================

-- A. Inisialisasi saldo user otomatis dari tabel profiles jika ada
CREATE OR REPLACE FUNCTION public.sync_user_points_from_profile(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile_points INTEGER := 0;
    v_current_balance INTEGER := 0;
BEGIN
    SELECT points INTO v_profile_points FROM public.profiles WHERE id = p_user_id;
    IF v_profile_points IS NULL THEN
        v_profile_points := 100;
    END IF;

    INSERT INTO public.user_points (user_id, balance, total_earned, total_spent, updated_at)
    VALUES (p_user_id, v_profile_points, v_profile_points, 0, now())
    ON CONFLICT (user_id) DO NOTHING;

    SELECT balance INTO v_current_balance FROM public.user_points WHERE user_id = p_user_id;
    RETURN v_current_balance;
END;
$$;

-- B. Validasi & Pemberian Poin Mini Game di Server (Anti-Tamper & Anti-Cheat)
CREATE OR REPLACE FUNCTION public.validate_and_award_game_points(
    p_game_type TEXT,
    p_score INTEGER,
    p_session_token TEXT,
    p_idempotency_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_max_score INTEGER := 300;
    v_awarded_points INTEGER := 0;
    v_new_balance INTEGER := 0;
    v_existing_tx UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Pengguna tidak terautentikasi');
    END IF;

    -- 1. Periksa idempotensi
    SELECT id INTO v_existing_tx FROM public.point_transactions WHERE idempotency_key = p_idempotency_key;
    IF v_existing_tx IS NOT NULL THEN
        SELECT balance INTO v_new_balance FROM public.user_points WHERE user_id = v_user_id;
        RETURN jsonb_build_object(
            'success', true, 
            'message', 'Transaksi skor sudah pernah diproses sebelumnya (Idempotent)',
            'points_awarded', 0,
            'balance', v_new_balance
        );
    END IF;

    -- 2. Validasi batas wajar skor per tipe game
    IF p_game_type = 'kulinerdle' THEN
        v_max_score := 160;
    ELSIF p_game_type = 'detective' THEN
        v_max_score := 350;
    ELSE
        v_max_score := 200;
    END IF;

    -- Clamp skor agar tidak melebihi aturan server
    v_awarded_points := LEAST(GREATEST(p_score, 0), v_max_score);
    IF v_awarded_points <= 0 THEN
        RETURN jsonb_build_object('success', false, 'message', 'Skor tidak valid untuk perolehan poin');
    END IF;

    -- 3. Pastikan user_points ada
    PERFORM public.sync_user_points_from_profile(v_user_id);

    -- 4. Update saldo atomik
    UPDATE public.user_points
    SET balance = balance + v_awarded_points,
        total_earned = total_earned + v_awarded_points,
        updated_at = now()
    WHERE user_id = v_user_id
    RETURNING balance INTO v_new_balance;

    -- 5. Catat audit transaksi
    INSERT INTO public.point_transactions (
        user_id, amount, transaction_type, reference_id, idempotency_key, metadata, created_at
    ) VALUES (
        v_user_id,
        v_awarded_points,
        'game_reward',
        p_session_token,
        p_idempotency_key,
        jsonb_build_object('game_type', p_game_type, 'submitted_score', p_score, 'verified_points', v_awarded_points),
        now()
    );

    -- 6. Sinkronkan ke tabel profiles
    UPDATE public.profiles
    SET points = v_new_balance
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Skor berhasil divalidasi dan poin ditambahkan',
        'points_awarded', v_awarded_points,
        'balance', v_new_balance
    );
END;
$$;

-- C. Pembelian Border Profil Atomik (Anti Double-Spend & Non-Negative Balance)
CREATE OR REPLACE FUNCTION public.purchase_border_reward(
    p_border_id TEXT,
    p_idempotency_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_price INTEGER;
    v_border_name TEXT;
    v_current_balance INTEGER;
    v_new_balance INTEGER;
    v_existing_redemption UUID;
    v_already_owned BOOLEAN;
    v_redemption_id UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Pengguna tidak terautentikasi');
    END IF;

    -- 1. Cek apakah border valid dan aktif
    SELECT price_points, name INTO v_price, v_border_name 
    FROM public.reward_borders 
    WHERE id = p_border_id AND is_active = true;

    IF v_price IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Produk border tidak ditemukan atau tidak aktif');
    END IF;

    -- 2. Cek idempotensi penukaran
    SELECT id INTO v_existing_redemption 
    FROM public.reward_redemptions 
    WHERE idempotency_key = p_idempotency_key;

    IF v_existing_redemption IS NOT NULL THEN
        SELECT balance INTO v_new_balance FROM public.user_points WHERE user_id = v_user_id;
        RETURN jsonb_build_object(
            'success', true,
            'message', 'Pembelian sudah pernah diproses sebelumnya (Idempotent)',
            'redemption_id', v_existing_redemption,
            'balance', v_new_balance
        );
    END IF;

    -- 3. Cek apakah user sudah memiliki border ini
    SELECT EXISTS(
        SELECT 1 FROM public.user_rewards WHERE user_id = v_user_id AND border_id = p_border_id
    ) INTO v_already_owned;

    IF v_already_owned THEN
        RETURN jsonb_build_object('success', false, 'message', 'Anda sudah memiliki border profil ini');
    END IF;

    -- 4. Sinkronkan saldo
    PERFORM public.sync_user_points_from_profile(v_user_id);

    -- 5. Kunci baris user_points (FOR UPDATE) untuk mencegah race condition double-spend
    SELECT balance INTO v_current_balance
    FROM public.user_points
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_current_balance < v_price THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', format('Saldo poin tidak mencukupi. Butuh %s poin, saldo Anda %s poin.', v_price, v_current_balance)
        );
    END IF;

    -- 6. Potong saldo secara atomik
    UPDATE public.user_points
    SET balance = balance - v_price,
        total_spent = total_spent + v_price,
        updated_at = now()
    WHERE user_id = v_user_id
    RETURNING balance INTO v_new_balance;

    -- 7. Catat redemption
    INSERT INTO public.reward_redemptions (
        user_id, border_id, points_spent, status, idempotency_key, created_at, updated_at
    ) VALUES (
        v_user_id, p_border_id, v_price, 'confirmed', p_idempotency_key, now(), now()
    ) RETURNING id INTO v_redemption_id;

    -- 8. Tambahkan ke koleksi user_rewards
    INSERT INTO public.user_rewards (user_id, border_id, is_active, acquired_at)
    VALUES (v_user_id, p_border_id, false, now());

    -- 9. Catat di ledger point_transactions
    INSERT INTO public.point_transactions (
        user_id, amount, transaction_type, reference_id, idempotency_key, metadata, created_at
    ) VALUES (
        v_user_id,
        -v_price,
        'border_purchase',
        v_redemption_id::text,
        p_idempotency_key,
        jsonb_build_object('border_id', p_border_id, 'border_name', v_border_name, 'points_spent', v_price),
        now()
    );

    -- 10. Update profile points
    UPDATE public.profiles
    SET points = v_new_balance
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', format('Berhasil membeli border "%s" seharga %s poin.', v_border_name, v_price),
        'redemption_id', v_redemption_id,
        'border_id', p_border_id,
        'points_spent', v_price,
        'balance', v_new_balance
    );
END;
$$;

-- D. Pasang / Lepas Border Profil Aktif
CREATE OR REPLACE FUNCTION public.equip_user_border(p_border_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_is_owned BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Pengguna tidak terautentikasi');
    END IF;

    -- Jika p_border_id NULL atau kosong, berarti lepas border
    IF p_border_id IS NULL OR p_border_id = '' THEN
        UPDATE public.user_rewards SET is_active = false WHERE user_id = v_user_id;
        UPDATE public.profiles SET active_border_id = NULL WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'message', 'Border profil dilepas');
    END IF;

    -- Cek kepemilikan
    SELECT EXISTS(
        SELECT 1 FROM public.user_rewards WHERE user_id = v_user_id AND border_id = p_border_id
    ) INTO v_is_owned;

    IF NOT v_is_owned THEN
        RETURN jsonb_build_object('success', false, 'message', 'Anda belum memiliki border profil ini');
    END IF;

    -- Set semua border lain menjadi non-aktif, aktifkan yang dipilih
    UPDATE public.user_rewards SET is_active = false WHERE user_id = v_user_id;
    UPDATE public.user_rewards SET is_active = true WHERE user_id = v_user_id AND border_id = p_border_id;

    -- Update tabel profiles
    UPDATE public.profiles SET active_border_id = p_border_id WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Border profil berhasil dipasang',
        'active_border_id', p_border_id
    );
END;
$$;

-- ==============================================================================
-- SEED DATA: 20 PRODUK BORDER PROFIL FOODIE
-- ==============================================================================

INSERT INTO public.reward_borders (id, name, description, rarity, price_points, is_animated, category, style_data)
VALUES
    ('border_garuda_bronze', 'Perunggu Garuda', 'Lingkaran perunggu kokoh terinspirasi ukiran candi Jawa kuno.', 'common', 150, false, 'Warisan', '{"primaryColor": 3453915698, "secondaryColor": 2354336555, "borderWidth": 3.0, "styleType": "solid_metallic"}'),
    ('border_bamboo_forest', 'Rimbun Bambu', 'Garis hijau alami yang melambangkan kesegaran bambu petung.', 'common', 180, false, 'Alam', '{"primaryColor": 948892732, "secondaryColor": 459153440, "borderWidth": 3.0, "styleType": "gradient_ring"}'),
    ('border_batik_parang', 'Parang Geometris', 'Aksen motif miring diagonal khas batik keraton Yogyakarta.', 'common', 200, false, 'Warisan', '{"primaryColor": 2372758067, "secondaryColor": 1312011310, "borderWidth": 3.5, "styleType": "dashed_batik"}'),
    ('border_slate_minimalist', 'Slate Minimalis', 'Garis ganda bersih bernuansa batu andesit modern perkotaan.', 'common', 220, false, 'Modern', '{"primaryColor": 1618442115, "secondaryColor": 927422287, "borderWidth": 2.8, "styleType": "double_line"}'),
    ('border_roasted_charcoal', 'Arang Panggang', 'Bingkai monokrom hitam arang dengan sudut bevel berkarakter.', 'common', 250, false, 'Kuliner', '{"primaryColor": 623717680, "secondaryColor": 303437336, "borderWidth": 3.5, "styleType": "chamfer_ring"}'),
    ('border_silver_sleek', 'Perak Kotagede', 'Kilau perak murni hasil tempaan pengrajin legendaris Kotagede.', 'uncommon', 350, false, 'Warisan', '{"primaryColor": 3772834016, "secondaryColor": 2654977710, "borderWidth": 3.5, "styleType": "metallic_silver"}'),
    ('border_cobalt_horizon', 'Cakrawala Kobalt', 'Gradien biru laut samudra selatan dengan kontras tegas.', 'uncommon', 400, false, 'Alam', '{"primaryColor": 4279768786, "secondaryColor": 4279113633, "borderWidth": 3.5, "styleType": "gradient_dual"}'),
    ('border_emerald_heritage', 'Zamrud Kraton', 'Nuansa hijau zamrud bangsawan dengan aksen emas halus.', 'uncommon', 450, false, 'Warisan', '{"primaryColor": 4278221163, "secondaryColor": 4294294864, "borderWidth": 3.5, "styleType": "emerald_gold"}'),
    ('border_paprika_spice', 'Api Paprika', 'Semangat hangat rempah cabai merah yang menggugah selera.', 'uncommon', 500, false, 'Kuliner', '{"primaryColor": 4293886517, "secondaryColor": 4292420373, "borderWidth": 3.5, "styleType": "paprika_accent"}'),
    ('border_saffron_gold', 'Emas Saffron', 'Kemewahan benang saffron kuning keemasan yang berharga.', 'uncommon', 550, false, 'Kuliner', '{"primaryColor": 4294294864, "secondaryColor": 4294942720, "borderWidth": 4.0, "styleType": "gold_ring"}'),
    ('border_cyberpunk_jogja', 'Neon Malioboro', 'Pendaran neon futuristik biru-ungu berdenyut halus.', 'rare', 750, true, 'Futuristik', '{"primaryColor": 4278257151, "secondaryColor": 4292149529, "borderWidth": 4.0, "styleType": "neon_pulse"}'),
    ('border_ruby_gastronomy', 'Permata Delima', 'Pancaran kristal batu delima dengan kilau bersudut presisi.', 'rare', 850, true, 'Permata', '{"primaryColor": 4290906203, "secondaryColor": 4287106639, "borderWidth": 4.0, "styleType": "gem_shimmer"}'),
    ('border_midnight_starlight', 'Bintang Tengah Malam', 'Latar gelap pekat dihiasi taburan bintang yang berpendar.', 'rare', 950, true, 'Kosmik', '{"primaryColor": 4279903102, "secondaryColor": 4292927712, "borderWidth": 4.0, "styleType": "starlight_twinkle"}'),
    ('border_amethyst_nebula', 'Nebula Ametis', 'Pusaran warna ungu kosmik dengan gelombang gradien berputar.', 'rare', 1100, true, 'Kosmik', '{"primaryColor": 4286267330, "secondaryColor": 4283510440, "borderWidth": 4.0, "styleType": "gradient_orbit"}'),
    ('border_lava_krakatau', 'Lahar Krakatau', 'Aliran magma merah membara yang mengalir dinamis melingkar.', 'epic', 1400, true, 'Elemen', '{"primaryColor": 4294917376, "secondaryColor": 4294945536, "borderWidth": 4.5, "styleType": "fiery_flow"}'),
    ('border_aurora_borealis', 'Tirai Aurora', 'Pendaran cahaya kutub hijau toska dan magenta yang bergerak anggun.', 'epic', 1600, true, 'Alam', '{"primaryColor": 4278257270, "secondaryColor": 4294918273, "borderWidth": 4.5, "styleType": "aurora_shift"}'),
    ('border_solar_flare_crown', 'Mahkota Surya', 'Pancaran sinar korona matahari dengan rotasi energi surya.', 'epic', 1850, true, 'Kosmik', '{"primaryColor": 4294956544, "secondaryColor": 4294931712, "borderWidth": 4.5, "styleType": "solar_corona"}'),
    ('border_celestial_diamond', 'Intan Surgawi', 'Kristal berlian prismatik dengan pantulan pelangi berputar abadi.', 'legendary', 2500, true, 'Permata', '{"primaryColor": 4278257151, "secondaryColor": 4294934700, "borderWidth": 5.0, "styleType": "prismatic_diamond"}'),
    ('border_blockchain_genesis', 'Genesis Node EVM', 'Rantai blok heksagonal kriptografis terhubung langsung ke Sepolia.', 'legendary', 3000, true, 'Blockchain', '{"primaryColor": 4284645100, "secondaryColor": 4278257151, "borderWidth": 5.0, "styleType": "blockchain_chain"}'),
    ('border_mythic_phoenix', 'Kencana Ananta', 'Aura burung phoenix emas legendaris melambangkan keagungan kurator utama.', 'legendary', 4000, true, 'Mitos', '{"primaryColor": 4294945536, "secondaryColor": 4294907716, "borderWidth": 5.5, "styleType": "phoenix_aura"}')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    rarity = EXCLUDED.rarity,
    price_points = EXCLUDED.price_points,
    is_animated = EXCLUDED.is_animated,
    category = EXCLUDED.category,
    style_data = EXCLUDED.style_data;
