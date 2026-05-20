import { createServerClient } from "@supabase/ssr";
import { type NextRequest, NextResponse } from "next/server";

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

  const response = NextResponse.next({
    request: {
      headers: request.headers
    }
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            request.cookies.set(name, value);
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
