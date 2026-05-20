import { adminLoginPath } from "@/features/admin-auth/services/admin-access";

export const shouldProtectAdminPath = (pathname: string): boolean =>
  pathname.startsWith("/admin") && pathname !== adminLoginPath;

export const buildAdminLoginRedirect = (requestUrl: string): string =>
  new URL(adminLoginPath, requestUrl).toString();

export const shouldRedirectToLogin = (
  hasUser: boolean,
  isAdmin: boolean
): boolean => !hasUser || !isAdmin;
