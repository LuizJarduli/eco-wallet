import { createServerClient } from "@supabase/ssr";
import { type NextRequest, NextResponse } from "next/server";

import { publicEnv } from "@/core/config/env";
import { resolveAdminAccessForUser } from "@/features/admin-auth/services/admin-access";
import {
  buildAdminLoginRedirect,
  shouldProtectAdminPath,
  shouldRedirectToLogin
} from "@/features/admin-auth/services/admin-route-guard";

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (!shouldProtectAdminPath(pathname)) {
    return NextResponse.next();
  }

  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    publicEnv.supabaseUrl(),
    publicEnv.supabasePublishableKey(),
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => {
            request.cookies.set(name, value);
          });

          response = NextResponse.next({ request });

          cookiesToSet.forEach(({ name, value, options }) => {
            response.cookies.set(name, value, options);
          });
        }
      }
    }
  );

  const {
    data: { user }
  } = await supabase.auth.getUser();

  const { data: profile } = user
    ? await supabase
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .maybeSingle<{ role: string }>()
    : { data: null };

  const access = resolveAdminAccessForUser(user?.id, profile?.role);

  if (shouldRedirectToLogin(Boolean(user), access.allowed)) {
    return NextResponse.redirect(buildAdminLoginRedirect(request.url));
  }

  return response;
}

export const config = {
  matcher: ["/admin/:path*"]
};
