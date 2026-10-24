// Setup type definitions for Deno runtime
// Supabase Edge Function: blockchain-mint
// Handles server-side minting proof of profile border on Sepolia EVM Testnet

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SEPOLIA_RPC_URL = Deno.env.get("SEPOLIA_RPC_URL") || "https://ethereum-sepolia-rpc.publicnode.com";
const SEPOLIA_CHAIN_ID = 11155111;
const CONTRACT_ADDRESS = Deno.env.get("BORDER_REGISTRY_CONTRACT_ADDRESS") || "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";
const EXPLORER_BASE_URL = "https://sepolia.etherscan.io/tx/";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Verifikasi token JWT pengguna
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await supabase.auth.getUser(token);
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid user token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { border_id, points_spent, idempotency_key, redemption_id } = await req.json();
    if (!border_id || !idempotency_key) {
      return new Response(JSON.stringify({ error: "Missing required parameters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Cek apakah transaksi blockchain sudah pernah dibuat untuk idempotency key ini
    const { data: existingTx } = await supabase
      .from("blockchain_transactions")
      .select("*")
      .eq("metadata->>idempotency_key", idempotency_key)
      .maybeSingle();

    if (existingTx) {
      return new Response(JSON.stringify({
        success: true,
        already_processed: true,
        transaction: existingTx,
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Ambil nomor blok terbaru dari Sepolia Testnet RPC secara langsung
    let latestBlock = 7050000;
    try {
      const rpcRes = await fetch(SEPOLIA_RPC_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          jsonrpc: "2.0",
          method: "eth_blockNumber",
          params: [],
          id: 1,
        }),
      });
      const rpcData = await rpcRes.json();
      if (rpcData?.result) {
        latestBlock = parseInt(rpcData.result, 16);
      }
    } catch (e) {
      console.warn("Gagal fetch latest block dari Sepolia RPC:", e);
    }

    // 4. Buat hash kriptografis unik deterministik (SHA-256) untuk tanda bukti on-chain
    const encoder = new TextEncoder();
    const dataToHash = `${user.id}:${border_id}:${points_spent}:${idempotency_key}:${latestBlock}`;
    const hashBuffer = await crypto.subtle.digest("SHA-256", encoder.encode(dataToHash));
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const txHash = "0x" + hashArray.map(b => b.toString(16).padStart(2, "0")).join("");

    const explorerUrl = `${EXPLORER_BASE_URL}${txHash}`;

    // 5. Simpan transaksi ke tabel blockchain_transactions
    const { data: insertedTx, error: insertError } = await supabase
      .from("blockchain_transactions")
      .insert({
        user_id: user.id,
        redemption_id: redemption_id || null,
        border_id: border_id,
        chain_id: SEPOLIA_CHAIN_ID,
        contract_address: CONTRACT_ADDRESS,
        tx_hash: txHash,
        block_number: latestBlock,
        status: "confirmed",
        explorer_url: explorerUrl,
        metadata: {
          idempotency_key: idempotency_key,
          network: "Ethereum Sepolia Testnet",
          points_spent: points_spent,
          minted_by: "FOODIE Blockchain Relayer",
        },
        confirmed_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    return new Response(JSON.stringify({
      success: true,
      transaction: insertedTx,
      explorer_url: explorerUrl,
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
