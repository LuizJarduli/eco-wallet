import { createClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";

import { publicEnv, serverEnv } from "@/core/config/env";
import { createSupabaseServerClient } from "@/core/lib/supabase-server";
import { resolveAdminAccessForUser } from "@/features/admin-auth/services/admin-access";

export async function GET(request: Request) {
  const path = new URL(request.url).searchParams.get("path");

  if (!path) {
    return NextResponse.json({ error: "Caminho da foto ausente." }, { status: 400 });
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Não autenticado." }, { status: 401 });
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .maybeSingle<{ role: string }>();

  const access = resolveAdminAccessForUser(user.id, profile?.role);

  if (!access.allowed) {
    return NextResponse.json({ error: "Acesso negado." }, { status: 403 });
  }

  const serviceRoleKey = serverEnv.supabaseServiceRoleKey();

  if (!serviceRoleKey) {
    return NextResponse.json(
      { error: "Configuração de storage indisponível." },
      { status: 500 }
    );
  }

  const serviceClient = createClient(
    publicEnv.supabaseUrl(),
    serviceRoleKey,
    { auth: { persistSession: false, autoRefreshToken: false } }
  );

  const { data, error } = await serviceClient.storage
    .from("disposal-photos")
    .createSignedUrl(path, 600);

  if (error || !data?.signedUrl) {
    return NextResponse.json(
      { error: "Não foi possível gerar URL da foto." },
      { status: 404 }
    );
  }

  return NextResponse.redirect(data.signedUrl);
}
